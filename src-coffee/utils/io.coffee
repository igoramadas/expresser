# EXPRESSER UTILS: IO
# -----------------------------------------------------------------------------
errors = require "../errors.coffee"
fs = require "fs"
lodash = require "lodash"
path = require "path"

###
# IO utilities.
###
class IOUtils
    newInstance: -> return new IOUtils()

    ###
    # Helper to get the correct file path for the specified filename. This will look into the current
    # directory, the running directory and the root directory of the app.
    # Returns null if no file is found.
    # @param {String} filename The base filename (with extension) of the file.
    # @return {String} The full path to the file if one was found, or null if not found.
    ###
    getFilePath: (filename) ->
        originalFilename = filename.toString()

        # Check if file exists.
        hasFile = fs.existsSync "./#{filename}"
        return filename if hasFile

        # Try current path.
        filename = path.resolve process.cwd(), originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Try application root path.
        filename = path.resolve path.dirname(require.main.filename), originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Try parent paths...
        filename = path.resolve __dirname, "../../", originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        filename = path.resolve __dirname, "../", originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Nothing found, so return null.
        return null

    ###
    # Copy the `src` file to the `target`, both must be the full file path.
    # @param {String} src The full source file path.
    # @param {String} target The full target file path.
    ###
    copyFileSync: (src, target) ->
        srcContents = fs.readFileSync src
        fs.writeFileSync target, srcContents

    ###
    # Make sure the "target" directory exists by recursively iterating through its parents
    # and creating the directories. Returns nothing if all good or error.
    # @param {String} target The full target path, with or without a trailing slash.
    ###
    mkdirRecursive: (target) ->
        return if fs.existsSync path.resolve(target)

        callback = (p, made) ->
            made = null if not made

            p = path.resolve p

            try
                fs.mkdirSync p
            catch ex
                if ex.code is "ENOENT"
                    made = callback path.dirname(p), made
                    callback p, made
                else
                    try
                        stat = fs.statSync p
                    catch ex1
                        errors.throw "cantCreateDirectory", ex1
                    if not stat.isDirectory()
                        errors.throw "cantCreateDirectory", ex

            return made

        return callback target

    ###
    # Helper to delay async code execution. To be used inside async functions using await.
    # @param {Number} milliseconds How long to stall the execution for.
    # @promise
    ###
    sleep: (milliseconds) =>
        return new Promise (resolve, reject) -> setTimeout(resolve, milliseconds)

# Singleton implementation
# --------------------------------------------------------------------------
IOUtils.getInstance = ->
    @instance = new IOUtils() if not @instance?
    return @instance

module.exports = IOUtils.getInstance()