# MAILER TEMPLATES
# --------------------------------------------------------------------------
fs = require "fs"
path = require "path"

lodash = null
logger = null
moment = null
settings = null
utils = null

# Holds all cached templates.
cache = {}

###
# Helper class to load and parse email templates.
###
class EmailTemplates

    ###
    # Init the Templates class.
    ###
    init: (parent) =>
        lodash = parent.expresser.libs.lodash
        logger = parent.expresser.logger
        moment = parent.expresser.libs.moment
        settings = parent.expresser.settings
        utils = parent.expresser.utils

        delete @init

    ###
    # Load and return the specified template. Get from the cache or from the disk
    # if it wasn't loaded yet. Templates are stored inside the `/emailtemplates`
    # folder by default and should have a .html extension. The base template,
    # which is always loaded first, should be called base.html by default.
    # The contents will be inserted on the {contents} tag.
    # @param {String} name The template name, without .html.
    # @return {String} The template HTML.
    ###
    get: (name) ->
        readOptions = {encoding: settings.general.encoding}

        # Load base template only?
        if name is true or name is "" or name is "base"
            baseOnly = true
        else
            baseOnly = false
            name = name.toString()
            name = name.replace(".html", "") if name.indexOf(".html")

            cached = cache[name]

            # Is it already cached? If so do not hit the disk.
            if cached? and cached.expires > moment()
                logger.debug "Mailer.templates.get", name, "Loaded from cache."
                return cache[name].template
            else
                logger.debug "Mailer.templates.get", name

        # Set file system reading options.
        baseFile = utils.io.getFilePath path.join(settings.mailer.templates.path, settings.mailer.templates.baseFile)

        # Read base template first.
        try
            base = fs.readFileSync baseFile, readOptions
        catch ex
            logger.warn "Mailer.templates.get", "Could not read base.html file, will use contents as body", ex
            base = "{contents}"

        # Load base only?
        if baseOnly
            result = base
        else
            templateFile = utils.io.getFilePath path.join(settings.mailer.templates.path, "#{name}.html")

            logger.debug "Mailer.templates.get", "Templates from", baseFile, templateFile

            # Read the actual template file.
            try
                template = fs.readFileSync templateFile, readOptions
                result = @parse base, {contents: template}
            catch ex
                logger.error "Mailer.templates.get", "Could not read #{templateFile}", ex

            # Save to cache.
            cache[name] = {}
            cache[name].template = result
            cache[name].expires = moment().add settings.general.ioCacheTimeout, "s"

        return result

    ###
    # Parse the specified template to replace keywords. The `keywords` is a set of key-values
    # to be replaced. For example if keywords is `{id: 1, friendlyUrl: "abc"}` then the tags
    # `{id}` and `{friendlyUrl}` will be replaced with the values 1 and abc.
    # Set circular to true to parse keywords inside other keywords as well.
    # @param {String} template The template (its value, not its name!) to be parsed.
    # @param {Object} keywords Object with keys to be replaced with its values.
    # @param {Boolean} circular If true, keywords will be parsed against themselves as well.
    # @return {String} The parsed template, keywords replaced with values.
    ###
    parse: (template, keywords, circular = false) =>
        if not template? or template is ""
            logger.debug "Mailer.templates.parse", "Empty template", keywords
            return ""

        template = template.toString()

        logger.debug "Mailer.templates.parse", template.replace(/(\r\n|\n|\r)/gm,""), keywords

        # Parse keywords inside other keywords?
        if circular
            keywords = lodash.cloneDeep keywords

            for key, value of keywords
                keywords[key] = @parse keywords[key], keywords

        for key, value of keywords
            template = template.replace new RegExp("\\{#{key}\\}", "gi"), value

        return template

    ###
    # Force clear the templates cache.
    ###
    clearCache: ->
        count = Object.keys(cache).length
        cache = {}
        logger.info "Mailer.templates.clearCache", "Cleared #{count} templates."

# Singleton implementation
# --------------------------------------------------------------------------
EmailTemplates.getInstance = ->
    @instance = new EmailTemplates() if not @instance?
    return @instance

module.exports = exports = EmailTemplates.getInstance()
