# MAILER TEMPLATES
# --------------------------------------------------------------------------
# Helper class to load and parse email templates.
class Templates

    fs = require "fs"
    logger = null
    moment = null
    path = require "path"
    settings = null
    utils = null

    # Holds all cached templates.
    cache = {}

    # Init the Templates class.
    init: (parent) =>
        logger = parent.expresser.logger
        moment = parent.expresser.libs.moment
        settings = parent.expresser.settings
        utils = parent.expresser.utils

        delete @init

    # Load and return the specified template. Get from the cache or from the disk
    # if it wasn't loaded yet. Templates are stored inside the `/emailtemplates`
    # folder by default and should have a .html extension. The base template,
    # which is always loaded first, should be called base.html by default.
    # The contents will be inserted on the {contents} tag.
    # @param {String} name The template name, without .html.
    # @return {String} The template HTML.
    get: (name) =>
        name = name.toString()
        name = name.replace(".html", "") if name.indexOf(".html")

        cached = cache[name]

        # Is it already cached? If so do not hit the disk.
        if cached? and cached.expires > moment()
            logger.debug "Mailer.templates.get", name, "Loaded from cache."
            return cache[name].template
        else
            logger.debug "Mailer.expresser.", name

        # Set file system reading options.
        readOptions = {encoding: settings.general.encoding}
        baseFile = utils.io.getFilePath path.join(settings.mailer.templates.path, settings.mailer.templates.baseFile)
        templateFile = utils.io.getFilePath path.join(settings.mailer.templates.path, "#{name}.html")

        # Read base and `name` template and merge them together.
        base = fs.readFileSync baseFile, readOptions
        template = fs.readFileSync templateFile, readOptions
        result = @parse base, {contents: template}

        # Save to cache.
        cache[name] = {}
        cache[name].template = result
        cache[name].expires = moment().add settings.general.ioCacheTimeout, "s"

        return result

    # Parse the specified template to replace keywords. The `keywords` is a set of key-values
    # to be replaced. For example if keywords is `{id: 1, friendlyUrl: "abc"}` then the tags
    # `{id}` and `{friendlyUrl}` will be replaced with the values 1 and abc.
    # @param {String} template The template (its value, not its name!) to be parsed.
    # @param {Object} keywords Object with keys to be replaced with its values.
    # @return {String} The parsed template, keywords replaced with values.
    parse: (template, keywords) =>
        logger.debug "Mailer.templates.parse", template, keywords

        template = template.toString()

        for key, value of keywords
            template = template.replace new RegExp("\\{#{key}\\}", "gi"), value

        return template

    # Force clear the templates cache.
    clearCache: =>
        count = Object.keys(cache).length
        cache = {}
        logger.info "Mailer.templates.clearCache", "Cleared #{count} templates."

# Singleton implementation
# --------------------------------------------------------------------------
Templates.getInstance = ->
    @instance = new Templates() if not @instance?
    return @instance

module.exports = exports = Templates.getInstance()
