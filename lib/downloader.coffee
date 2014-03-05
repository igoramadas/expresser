# EXPRESSER DOWNLOADER
# --------------------------------------------------------------------------
# Handles external downloads.
# <!--
# @see Settings.downloader
# -->
class Downloader

    fs = require "fs"
    http = require "http"
    https = require "https"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    url = require "url"

    # The download queue and simultaneous count.
    queue = []
    downloading = []

    # INTERNAL METHODS
    # --------------------------------------------------------------------------

    # Helper to remove a download from the `downloading` list.
    removeDownloading = (obj) ->
        filter = {timestamp: obj.timestamp, remoteUrl: obj.remoteUrl, saveTo: obj.saveTo}
        downloading = lodash.reject downloading, filter

    # Helper function to proccess download errors.
    downloadError = (err, obj) ->
        logger.debug "Downloader.downloadError", err, obj
        removeDownloading obj
        next()
        obj.callback(err, obj) if obj.callback?

    # Helper function to parse the URL and get its options.
    parseUrlOptions = (obj, options) ->
        if obj.redirectUrl? and obj.redirectUrl isnt ""
            urlInfo = url.parse obj.redirectUrl
        else
            urlInfo = url.parse obj.remoteUrl

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
    reqStart = (obj, options) ->
        if obj.remoteUrl.indexOf("https") is 0
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
                        if fs.existsSync?
                            tempExists = fs.existsSync saveToTemp
                        else
                            tempExists = path.existsSync saveToTemp

                        # If temp download file can't be found, set error message.
                        # If `stopFlag` is 2 means download was stopped and should not keep partial data.
                        if not tempExists
                            err = {message:"Can't find downloaded file: #{saveToTemp}"}
                        else
                            fs.unlinkSync saveToTemp if obj.stopFlag is 2

                        # Check if destination file already exists.
                        if fs.existsSync?
                            fileExists = fs.existsSync obj.saveTo
                        else
                            fileExists = path.existsSync obj.saveTo

                        # Only proceed with renaming if `stopFlag` wasn't set and destionation is valid.
                        if not obj.stopFlag? or obj.stopFlag < 1
                            fs.unlinkSync obj.saveTo if fileExists
                            fs.renameSync saveToTemp, obj.saveTo if tempExists

                        # Remove from `downloading` list and proceed with the callback.
                        removeDownloading obj
                        obj.callback(err, obj) if obj.callback?

                        logger.debug "Downloader.next", "End", obj.remoteUrl, obj.saveTo

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
    next = ->
        return if queue.length < 0

        # Get first download from queue.
        obj = queue.shift()

        # Check if download is valid.
        if not obj?
            logger.debug "Downloader.next", "Skip", "Downloader object is invalid."
            return
        else
            logger.debug "Downloader.next", obj

        # Add to downloading array.
        downloading.push obj

        if settings.downloader.headers? and settings.downloader.headers isnt ""
            headers = settings.web.downloaderHeaders
        else
            headers = null

        # Set default options.
        options =
            headers: headers
            rejectUnauthorized: settings.downloader.rejectUnauthorized

        # Extend options.
        options = lodash.assign options, obj.options, parseUrlOptions(obj)

        # Start download
        if obj.stopFlag? and obj.stopFlag > 0
            logger.debug "Downloader.next", "Skip, 'stopFlag' is #{obj.stopFlag}.", obj
            removeDownloading obj
            next()
        else
            reqStart obj, options

    # METHODS
    # --------------------------------------------------------------------------

    # Download an external file and save it to the specified location. The `callback`
    # has the signature (error, data). Returns the downloader object which is added
    # to the `queue`, which has the download properties and a `stop` helper to force
    # stopping it. Returns false on error or duplicate.
    # Tip: if you want to get the downloaded data without having to read the target file
    # you can get the downloaded contents via the `options.downloadedData`.
    # @param [String] remoteUrl The URL of the remote file to be downloaded.
    # @param [String] saveTo The full local path and destination filename.
    # @param [Object] options Optional, object with request options, for example auth.
    # @param [Method] callback Optional, a function (err, result) to be called when download has finished.
    # @return [Object] Returns the download job having timestamp, remoteUrl, saveTo, options, callback and stop helper.
    download: (remoteUrl, saveTo, options, callback) =>
        if not remoteUrl?
            logger.warn "Downloader.download", "Aborted, remoteUrl is not defined."
            return

        # Check options and callback.
        if not callback? and lodash.isFunction options
            callback = options
            options = null

        now = new Date().getTime()

        # Create the download object.
        downloadObj = {timestamp: now, remoteUrl: remoteUrl, saveTo: saveTo, options: options, callback: callback}

        # Prevent duplicates?
        if settings.downloader.preventDuplicates
            existing = lodash.filter downloading, {remoteUrl: remoteUrl, saveTo: saveTo}

            # If downloading the same file and to the same location, abort download.
            if existing.length > 0
                existing = existing[0]
                if existing.saveTo is saveTo
                    logger.warn "Downloader.download", "Aborted, already downloading.", remoteUrl, saveTo
                    err = {message: "Download aborted: same file is already downloading.", duplicate: true}
                    callback(err, downloadObj) if callback?
                    return false

        # Create a `stop` method to force stop the download by setting the `stopFlag`.
        # Accepts a `keep` boolean, if true the already downloaded data will be kept on forced stop.
        stopHelper = (keep) -> @stopFlag = (if keep then 1 else 2)

        # Update download object with stop helper and add to queue.
        downloadObj.stop = stopHelper
        queue.push downloadObj

        # Start download immediatelly if not exceeding the `maxSimultaneous` setting.
        next() if downloading.length < settings.downloader.maxSimultaneous

        return downloadObj


# Singleton implementation
# --------------------------------------------------------------------------
Downloader.getInstance = ->
    @instance = new Downloader() if not @instance?
    return @instance

module.exports = exports = Downloader.getInstance()