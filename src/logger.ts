// Expresser: logger.ts

import {isArray, isError, isFunction, isObject} from "./utils"
import jaul = require("jaul")
const settings = require("setmeup").settings

/** Logger helper class to configure the Anyhow logging module. */
class Logger {
    /** Recursive arguments cleaner. */
    static argsCleaner(obj, index) {
        const max = settings.logger.maxDepth

        // Argument is array?
        if (isArray(obj)) {
            for (let i = 0; i < obj.length; i++) {
                if (index >= max) {
                    obj[i] = "..."
                } else if (isFunction(obj[i])) {
                    obj[i] = "[Function]"
                } else {
                    Logger.argsCleaner(obj[i], index + 1)
                }
            }
        }
        // Arg is an object? Then recurisvely clean its sub properties.
        else if (isObject(obj)) {
            let keys = Object.keys(obj)

            for (let key of keys) {
                let value = obj[key]

                try {
                    if (index >= max) {
                        obj[key] = "..."
                    } else if (settings.logger.obfuscateFields && settings.logger.obfuscateFields.indexOf(key) >= 0) {
                        obj[key] = "****"
                    } else if (settings.logger.maskFields && settings.logger.maskFields[key]) {
                        let maskedValue

                        // Actual value might be hidden inside a value, text or data sub-property.
                        if (isObject(value)) {
                            maskedValue = value.value || value.text || value.data || value.toString()
                        } else {
                            maskedValue = value.toString()
                        }

                        obj[key] = jaul.data.maskString(maskedValue, "*", settings.logger.maskFields[key])
                    } else if (settings.logger.removeFields && settings.logger.removeFields.indexOf(key) >= 0) {
                        delete obj[key]
                    } else if (isArray(value)) {
                        for (let i = 0; i < value.length; i++) {
                            Logger.argsCleaner(value[i], index + 1)
                        }
                    } else if (isFunction(value)) {
                        obj[key] = "[Function]"
                    } else if (isObject(value)) {
                        Logger.argsCleaner(value, index + 1)
                    }
                } catch (ex) {
                    /* istanbul ignore next */
                    delete obj[key]
                    /* istanbul ignore next */
                    obj[key] = "[Unreadable]"
                }
            }
        }
    }

    /** Used as a preprocessor for the Anyhow logger. */
    static clean(args: any[]): any {
        let result = []

        for (let arg of args) {
            // Extract error details from error objects.
            // Clone objects and arrays before parsing.
            // Add function text for Functions.
            if (isError(arg)) {
                result.push(arg.toString())
            } else if (isObject(arg) || isArray(arg)) {
                let cloned = JSON.parse(JSON.stringify(arg, null, 0))
                Logger.argsCleaner(cloned, 0)
                result.push(cloned)
            } else if (isFunction(arg)) {
                result.push("[Function]")
            } else {
                result.push(arg)
            }
        }

        return result
    }
}

// Exports...
export = Logger
