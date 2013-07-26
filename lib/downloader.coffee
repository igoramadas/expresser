# EXPRESSER DOWNLOADER
# --------------------------------------------------------------------------
# Handles external downloads.
# Parameters on [settings.html](settings.coffee): Settings.Downloader

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
        if settings.general.debug
            logger.warn "Expresser", "Downloader.downloadError", err, obj

        removeDownloading obj
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
            options.port = 443 if not urlInfo.port?
            httpHandler = https
        else
            httpHandler = http

        # Start the request.
        req = httpHandler.get options, (response) =>

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

                # Listener: write data.
                response.addListener "data", (data) =>
                    fileWriter.write data

                # Listener: end data.
                response.addListener "end", () =>
                    fileWriter.addListener "close", () =>

                        # If temp download file can't be found, stop here but do not throw an error.
                        if fs.existsSync?
                            fileExists = fs.existsSync saveToTemp
                        else
                            fileExists = path.existsSync saveToTemp

                        return if not fileExists

                        # Delete the old file (if there's one) and rename the .download file to its original name.
                        if fs.existsSync?
                            fileExists = fs.existsSync obj.saveTo
                        else
                            fileExists = path.existsSync obj.saveTo

                        fs.unlinkSync obj.saveTo if fileExists

                        # Remove .download extension.
                        fs.renameSync saveToTemp, obj.saveTo

                        # Remove from `downloading` list and proceed with the callback.
                        removeDownloading obj
                        obj.callback(err, obj) if obj.callback?

                        if settings.general.debug
                            logger.info "Expresser", "Downloader.next", "End", obj

                    fileWriter.end()
                    fileWriter.destroySoon()

        # Unhandled error, call the downloadError helper.
        req.on "error", (err) =>
            downloadError err, obj

    # Process next download.
    next = ->
        return if queue.length < 0

        # Get first download from queue.
        obj = queue.shift()
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
        options = lodash.assign options, obj.options, parseUrlOptions obj

        # Start the download.
        reqStart obj, options


    # METHODS
    # --------------------------------------------------------------------------

    # Download an external file and save it to the specified location. The `callback`
    # has the signature (error, data).
    download: (remoteUrl, saveTo, options, callback) =>
        if not remoteUrl?
            logger.warn "Expresser", "Downloader.download", "Aborted, remoteUrl is not defined."
            return

        # Check options and callback.
        if not callback? and lodash.isFunction options
            callback = options
            options = null

        now = new Date().getTime()

        # Prevent duplicates?
        if settings.downloader.preventDuplicates
            existing = lodash.filter downloading, {remoteUrl: remoteUrl, saveTo: saveTo}

            # If downloading the same file and to the same location, abort download.
            if existing.length > 0
                existing = existing[0]
                if existing.saveTo is saveTo
                    logger.warn "Expresser", "Downloader.download", "Aborted, already downloading.", remoteUrl, saveTo
                    err = {message: "Download aborted: same file is already downloading.", duplicate: true}
                    callback(err, null) if callback?
                    return

        # Add download to the queue.
        queue.push {timestamp: now, remoteUrl: remoteUrl, saveTo: saveTo, options: options, callback: callback}

        # Start download immediatelly if not exceeding the `maxSimultaneous` setting.
        next() if downloading.length < settings.downloader.maxSimultaneous


# Singleton implementation
# --------------------------------------------------------------------------
Downloader.getInstance = ->
    @instance = new Downloader() if not @instance?
    return @instance

module.exports = exports = Downloader.getInstance()