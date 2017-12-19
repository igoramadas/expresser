# EXPRESSER DOWNLOADER
# --------------------------------------------------------------------------
fs = require "fs"
http = require "http"
https = require "https"
path = require "path"
url = require "url"

errors = null
events = null
lodash = null
logger = null
settings = null

###
# Simple download manager. Supports all common HTTP and HTTPS options, defining
# a maximum of concurrent downloads.
###
class Downloader
    priority: 4

    ##
    # The download queue, should be managed automatically by the module.
    # @property
    # @type Array
    queue: []

    ##
    # List of active downloads.
    # @property
    # @type Array
    downloading: []

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Downloader module. Should be called automatically by the main Expresser module.
    # @private
    ###
    init: =>
        errors = @expresser.errors
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "Downloader.init"

        events.emit "Downloader.on.init"
        delete @init

    # METHODS
    # --------------------------------------------------------------------------

    ###
    # Download a resource and save it to the specified location. The `callback`
    # has the signature (error, data). Returns the downloader object which is added
    # to the `queue`, which has the download properties and a `stop` helper to force
    # stopping it. Returns false on error or duplicate.
    # Tip: if you want to get the downloaded data without having to read the target file
    # you can get the downloaded contents via the `options.downloadedData`.
    # @param {String} resourceUrl The full URL of the resource to be downloaded.
    # @param {String} saveTo The destination path where it should be saved. Optional.
    # @param {Object} options Request options, for example auth. Optional.
    # @param {Function} callback Optional, a function (err, result) to be called when download has finished.
    # @return {Object} Returns the download job with timestamp, resourceUrl, saveTo, options, callback and stop helper.
    ###
    download: (resourceUrl, saveTo, options, callback) =>
        logger.debug "Downloader.download", resourceUrl, saveTo, options

        if not settings.downloader.enabled
            return logger.notEnabled "Downloader"

        # The resource URL is mandatory.
        if not resourceUrl? or resourceUrl is ""
            return errors.throw "urlMandatory", "Please pass a valid URL on first argument 'resourceUrl'."

        # Check options and callback.
        if not callback? and lodash.isFunction options
            callback = options
            options = null

        now = new Date().getTime()

        # Create the download object.
        downloadObj = {timestamp: now, resourceUrl: resourceUrl, saveTo: saveTo, options: options, callback: callback, stopFlag: false}

        # Prevent duplicates?
        if settings.downloader.preventDuplicates
            existing = lodash.find @downloading, {resourceUrl: resourceUrl, saveTo: saveTo}

            # If downloading the same file and to the same location, abort download.
            if existing?.saveTo is saveTo
                logger.error "Downloader.download", "Aborted, already downloading.", resourceUrl, saveTo
                err = {message: "Download aborted: same file is already downloading.", duplicate: true}
                callback? err, downloadObj
                return null

        # Create a `stop` method to force stop the download by setting the `stopFlag`.
        # Accepts a `keep` boolean, if true the already downloaded data will be kept on forced stop.
        stopHelper = (keep) -> @stopFlag = true

        # Update download object with stop helper and add to queue.
        downloadObj.stop = stopHelper
        @queue.push downloadObj

        # Start download immediatelly if not exceeding the `maxSimultaneous` setting.
        next() if @downloading.length < settings.downloader.maxSimultaneous

        return downloadObj

    # Force stop a current download.
    # @param {String} resourceUrl The URL of the download to stop.
    # @param {String} saveTo The full local path of the download to stop.
    # @return {Boolean} Returns true if a match was found, or false if no matching download to stop.
    stop: (resourceUrl, saveTo, keep) =>
        existing = lodash.find @downloading, {resourceUrl: resourceUrl, saveTo: saveTo}

        # Download exists? If so set its stop flag and return true, otherwise false.
        if existing?
            existing.stopFlag = true
            return true
        else
            return false

    # INTERNAL IMPLEMENTATION
    # --------------------------------------------------------------------------

    # Helper to remove a download from the `downloading` list.
    removeDownloading = (obj) =>
        filter = {timestamp: obj.timestamp, resourceUrl: obj.resourceUrl, saveTo: obj.saveTo}
        @downloading = lodash.reject @downloading, filter

    # Helper function to proccess download errors.
    downloadError = (err, obj) =>
        logger.debug "Downloader.downloadError", err, obj
        removeDownloading obj
        next()
        obj.callback(err, obj) if obj.callback?

    # Helper function to parse the URL and get its options.
    parseUrlOptions = (obj, options) =>
        if obj.redirectUrl? and obj.redirectUrl isnt ""
            urlInfo = url.parse obj.redirectUrl
        else
            urlInfo = url.parse obj.resourceUrl

        # Set URL options.
        options =
            host: urlInfo.hostname
            hostname: urlInfo.hostname
            port: urlInfo.port
            path: urlInfo.path

        # Check for credentials on the URL.
        if urlInfo.auth? and urlInfo.auth isnt ""
            options.auth = urlInfo.auth

        return options

    # Helper function to start a download request.
    reqStart = (obj, options) =>
        if obj.resourceUrl.indexOf("https") is 0
            options.port = 443 if not options.port?
            httpHandler = https
        else
            httpHandler = http

        # Start the request.
        req = httpHandler.get options, (response) =>

            # Downloaded contents will be appended also to the `downloadedData`
            # property of the options object.
            obj.downloadedData = ""

            # Set the estination temp file.
            saveToTemp = obj.saveTo + settings.downloader.tempExtension

            # If status is 301 or 302, redirect to the specified location and stop the current request.
            if response.statusCode is 301 or response.statusCode is 302

                obj.redirectUrl = response.headers.location
                options = lodash.assign options, parseUrlOptions obj
                req.end()

                reqStart obj, options

                # If status is not 200 or 304, it means something went wrong so do not proceed
                # with the download. Otherwise proceed and listen to the `data` and `end` events.
            else if response.statusCode isnt 200 and response.statusCode isnt 304

                err = {code: response.statusCode, message: "Server returned an unexpected status code: #{response.statusCode}"}
                downloadError err, obj

            else
                # Create the file stream with a .download extension. This will be renamed after the
                # download has finished and the file is totally written.
                fileWriter = fs.createWriteStream saveToTemp, {"flags": "w+"}

                # Helper called response gets new data. The data will also be
                # appended to `options.data` property.
                onData = (data) ->
                    if obj.stopFlag
                        req.end()
                        onEnd()
                    else
                        fileWriter.write data
                        obj.downloadedData += data

                # Helper called when response ends.
                onEnd = ->
                    response.removeListener "data", onData

                    fileWriter.addListener "close", ->

                        # Check if temp file exists.
                        tempExists = fs.existsSync saveToTemp

                        # Do not keep temporaty files!
                        if not tempExists
                            err = {message:"Can't find downloaded file: #{saveToTemp}"}
                        else if obj.stopFlag
                            fs.unlinkSync saveToTemp

                        # Check if destination file already exists.
                        fileExists = fs.existsSync obj.saveTo

                        # Only proceed with renaming if `stopFlag` wasn't set and destionation is valid.
                        if not obj.stopFlag
                            fs.unlinkSync obj.saveTo if fileExists
                            fs.renameSync saveToTemp, obj.saveTo if tempExists

                        # Remove from `downloading` list and proceed with the callback.
                        removeDownloading obj
                        obj.callback(err, obj) if obj.callback?

                        logger.debug "Downloader.next", "End", obj.resourceUrl, obj.saveTo

                    fileWriter.end()
                    fileWriter.destroySoon()
                    next()

                # Attachd response listeners.
                response.addListener "data", onData
                response.addListener "end", onEnd

        # Unhandled error, call the downloadError helper.
        req.on "error", (err) =>
            downloadError err, obj

    # Process next download.
    next = =>
        return if @queue.length < 0

        # Get first download from queue.
        obj = @queue.shift()

        # Check if download is valid.
        if not obj?
            logger.debug "Downloader.next", "Skip", "Downloader object is invalid."
            return
        else
            logger.debug "Downloader.next", obj

        # Add to downloading array.
        @downloading.push obj

        if settings.downloader.headers? and settings.downloader.headers isnt ""
            headers = settings.web.downloaderHeaders
        else
            headers = null

        # Set and extend default options.
        options = lodash.assign {headers: headers, rejectUnauthorized: settings.downloader.rejectUnauthorized}, obj.options, parseUrlOptions(obj)

        # Start download
        if obj.stopFlag
            logger.debug "Downloader.next", "Skip, 'stopFlag' is #{obj.stopFlag}.", obj
            removeDownloading obj
            next()
        else
            reqStart obj, options

# Singleton implementation
# --------------------------------------------------------------------------
Downloader.getInstance = ->
    @instance = new Downloader() if not @instance?
    return @instance

module.exports = exports = Downloader.getInstance()
