# EXPRESSER IMAGING
# --------------------------------------------------------------------------
# Handles and manipulates images on the server using ImageMagick.
# Parameters on settings.coffee: Settings.Logger

class Imaging

    # Required modules.
    fs = require "fs"
    im = require "imagemagick"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Converts the specified SVG to PNG, by creating a new file with same name
    # but different extension. Image will also be resized and scale to the specified
    # dimensions (width and height). A callback (err, result) can be passed as well.
    svgToPng: (svgSource, dimensions, callback) =>
        fs.exists svgSource, (exists) ->
            if exists
                try
                    size = ""

                    # Get proper dimensions.
                    width = dimensions.width if dimensions.width?
                    height = dimensions.height if dimensions.height?

                    # Set size.
                    if width? and width > 0
                        size += width
                    if height? and height > 0
                        size += "x" + height

                    # Try converting the SVG to a PNG file and trigger the `callback`, if passed.
                    im.convert [svgSource, "-resize", size, svgSource.replace(".svg", ".png")]

                    if callback?
                        callback null, true

                    if settings.General.debug
                        logger.info "Expresser", "Imaging.svgToPng", svgSource, dimensions

                # In case of exception, log it and pass to the `callback`.
                catch err
                    logger.error "Expresser", "Imaging.svgToPng", err
                    callback(err, false) if callback?

            else

                # SVG does not exist, so log the warning and trigger
                # the `callback` if one was passed.
                logger.warn "Expresser", "Imaging.svgToPng", "Abort, SVG file does not exist.", svgSource
                callback(null, false) if callback?


# Singleton implementation
# --------------------------------------------------------------------------
Imaging.getInstance = ->
    @instance = new Imaging() if not @instance?
    return @instance

module.exports = exports = Imaging.getInstance()