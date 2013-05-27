# EXPRESSER IMAGING
# --------------------------------------------------------------------------
# Handles and manipulates images on the server using ImageMagick.
# Parameters on settings.coffee: Settings.Logger

class Imaging

    # Required modules.
    fs = require "fs"
    im = require "imagemagick"
    logger = require "./logger.coffee"
    path = require "path"
    settings = require "./settings.coffee"

    # INIT
    # --------------------------------------------------------------------------

    # Init the Imaging module.
    init: =>



    # IMAGE METHODS
    # --------------------------------------------------------------------------

    # Internal method to convert image filetypes. Image will also be resized and scale to the specified
    # dimensions (width and height). A callback (err, result) can be passed as well.
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
                    if size? and size istn ""
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

                    # Log convert action if debug is enabled.
                    if settings.General.debug
                        logger.info "Expresser", "Imaging.convert", source, options

                # In case of exception, log it and pass to the `callback`.
                catch ex
                    logger.error "Expresser", "Imaging.convert", ex
                    callback(ex, false) if callback?

            else

                # Source file does not exist, so log the warning and trigger
                # the `callback` if one was passed.
                logger.warn "Expresser", "Imaging.svgToPng", "Abort, source file does not exist.", source
                callback("Source file does not exist.", false) if callback?

    # Converts the specified image to JPG, with optional options and callback.
    toJpg: (source, options, callback) =>
        convert source, ".jpg", options, callback

    # Converts the specified image to PNG, with optional options and callback.
    toPng: (source, options, callback) =>
        convert source, ".png", options, callback


# Singleton implementation
# --------------------------------------------------------------------------
Imaging.getInstance = ->
    @instance = new Imaging() if not @instance?
    return @instance

module.exports = exports = Imaging.getInstance()