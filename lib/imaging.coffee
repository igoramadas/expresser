# EXPRESSER IMAGING
# --------------------------------------------------------------------------
# Handles and manipulates images on the server using ImageMagick.
# <!--
# @see Settings.imaging
# -->
class Imaging

    fs = require "fs"
    im = require "imagemagick"
    logger = require "./logger.coffee"
    path = require "path"
    settings = require "./settings.coffee"


    # IMAGE METHODS
    # --------------------------------------------------------------------------

    # Internal method to convert image filetypes. Image will also be resized and scale to the specified
    # dimensions (width and height). A callback (err, stdout) can be passed as well.
    convert = (source, filetype, options, callback) =>
        fs.exists source, (exists) ->
            if exists
                try
                    callback = options if typeof options is "function" and not callback?

                    # Create arguments for the ImageMagick `convert` command.
                    args = []
                    args.push source

                    # Get proper dimensions.
                    size = options.size
                    width = options.width if options.width?
                    height = options.height if options.height?

                    # Set size based on options.
                    if not size?
                        size = ""
                        if width? and width > 0
                            size += width
                        if height? and height > 0
                            size += "x" + height

                    # Resize?
                    if size? and size is ""
                        args.push "-resize"
                        args.push size

                    # Set quality?
                    if options.quality? and options.quality isnt ""
                        args.push "-quality"
                        args.push options.quality

                    # Add target filename argument.
                    args.push source.replace(path.extname(source), filetype)

                    # Try converting the source to the destination filetype trigger the `callback`, if passed.
                    im.convert args, (err, stdout) -> callback(err, stdout) if callback?

                    logger.debug "Imaging.convert", source, options

                # In case of exception, log it and pass to the `callback`.
                catch ex
                    logger.error "Imaging.convert", ex
                    callback(ex, false) if callback?

            else

                # Source file does not exist, so log the warning and trigger
                # the `callback` if one was passed.
                logger.warn "Imaging.convert", "Abort, source file does not exist.", source
                callback("Source file does not exist.", false) if callback?

    # Converts the specified image to GIF.
    # @param [String] source Path to the source image.
    # @param [Object] options Options to be passed to the converter, optional.
    # @param [Method] callback Function (err, result) to be called when GIF conversion has finished.
    toGif: (source, options, callback) =>
        convert source, ".gif", options, callback

    # Converts the specified image to JPG.
    # @param [String] source Path to the source image.
    # @param [Object] options Options to be passed to the converter, optional.
    # @param [Method] callback Function (err, result) to be called when JPG conversion has finished.
    toJpg: (source, options, callback) =>
        convert source, ".jpg", options, callback

    # Converts the specified image to PNG.
    # @param [String] source Path to the source image.
    # @param [Object] options Options to be passed to the converter, optional.
    # @param [Method] callback Function (err, result) to be called when PNG conversion has finished.
    toPng: (source, options, callback) =>
        convert source, ".png", options, callback


# Singleton implementation
# --------------------------------------------------------------------------
Imaging.getInstance = ->
    @instance = new Imaging() if not @instance?
    return @instance

module.exports = exports = Imaging.getInstance()