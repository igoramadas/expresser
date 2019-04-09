// Expresser: logger.ts

/** @hidden */
const _ = require("lodash")
/** @hidden */
const jaul = require("jaul")
/** @hidden */
const settings = require("setmeup").settings

/** Logger helper class to configure the Anyhow logging module. */
class Logger {
    static argsCleaner(obj, index) {
        const max = settings.logger.maxDepth

        if (_.isArray(obj)) {
            for (let i = 0; i < obj.length; i++) {
                if (index >= max) {
                    obj[i] = "..."
                } else if (_.isFunction(obj[i])) {
                    /* istanbul ignore next */
                    obj[i] = "[Function]"
                } else {
                    Logger.argsCleaner(obj[i], index + 1)
                }
            }
        } else if (_.isObject(obj)) {
            Object.keys(obj).forEach(function(key) {
                let value = obj[key]

                try {
                    if (index > max) {
                        obj[key] = "..."
                    } else if (settings.logger.obfuscateFields && settings.logger.obfuscateFields.indexOf(key) >= 0) {
                        obj[key] = "****"
                    } else if (settings.logger.maskFields && settings.logger.maskFields[key]) {
                        let maskedValue

                        /* istanbul ignore if */
                        if (_.isObject(value)) {
                            maskedValue = value.value || value.text || value.contents || value.data || "*"
                        } else {
                            maskedValue = value.toString()
                        }

                        obj[key] = jaul.data.maskString(maskedValue, "*", settings.logger.maskFields[key])
                    } else if (settings.logger.removeFields && settings.logger.removeFields.indexOf(key) >= 0) {
                        delete obj[key]
                    } else if (_.isArray(value)) {
                        for (let i = 0; i < value.length; i++) {
                            Logger.argsCleaner(value[i], index + 1)
                        }
                    } else if (_.isFunction(value)) {
                        obj[key] = "[Function]"
                    } else if (_.isObject(value)) {
                        Logger.argsCleaner(value, index + 1)
                    }
                } catch (ex) {
                    /* istanbul ignore next */
                    delete obj[key]
                    /* istanbul ignore next */
                    obj[key] = "[Unreadable]"
                }
            })
        }
    }

    static clean(args: any[]) {
        const result = []

        // Iterate array and execute cleaner on objects.
        for (let a of args) {
            try {
                if (_.isError(a)) {
                    result.push(a)
                } else if (_.isObject(a)) {
                    Logger.argsCleaner(a, 0)
                    result.push(a)
                } else if (_.isFunction(a)) {
                    /* istanbul ignore next */
                    result.push("[Function]")
                } else {
                    result.push(a)
                }
            } catch (ex) {
                /* istanbul ignore next */
                console.warn("Logger.argsCleaner", a, ex)
            }
        }

        return result
    }
}

// Exports...
export = Logger
