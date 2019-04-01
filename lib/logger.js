"use strict";
/**
 * Expresser: Logger
 */
const _ = require("lodash");
const jaul = require("jaul");
const settings = require("setmeup").settings;
class Logger {
    argsCleaner(obj, index) {
        const max = 8;
        if (_.isArray(obj)) {
            for (let i = 0; i < obj.length; i++) {
                if (index > max) {
                    obj[i] = "...";
                }
                else if (_.isFunction(obj[i])) {
                    obj[i] = "[Function]";
                }
                else {
                    this.argsCleaner(obj[i], index + 1);
                }
            }
        }
        else if (_.isObject(obj)) {
            Object.keys(obj).forEach(function (key) {
                let value = obj[key];
                try {
                    if (index > max) {
                        obj[key] = "...";
                    }
                    else if ((settings.logger.obfuscateFields != null ? settings.logger.obfuscateFields.indexOf(key) : undefined) >= 0) {
                        obj[key] = "****";
                    }
                    else if ((settings.logger.maskFields != null ? settings.logger.maskFields[key] : undefined) != null) {
                        let maskedValue;
                        if (_.isObject(value)) {
                            maskedValue = value.value || value.text || value.contents || value.data || "*";
                        }
                        else {
                            maskedValue = value.toString();
                        }
                        obj[key] = jaul.data.maskString(maskedValue, "*", settings.logger.maskFields[key]);
                    }
                    else if ((settings.logger.removeFields != null ? settings.logger.removeFields.indexOf(key) : undefined) >= 0) {
                        delete obj[key];
                    }
                    else if (_.isArray(value)) {
                        for (let i = 0; i < value.length; i++) {
                            this.argsCleaner(value[i], index + 1);
                        }
                    }
                    else if (_.isFunction(value)) {
                        obj[key] = "[Function]";
                    }
                    else if (_.isObject(value)) {
                        this.argsCleaner(value, index + 1);
                    }
                }
                catch (ex) {
                    delete obj[key];
                    obj[key] = "[Unreadable]";
                }
            });
        }
    }
    clean() {
        const result = [];
        // Iterate arguments and execute cleaner on objects.
        for (let argKey in arguments) {
            const arg = arguments[argKey];
            try {
                if (_.isArray(arg)) {
                    for (let a of Array.from(arg)) {
                        if (_.isError(a)) {
                            result.push(a);
                        }
                        else if (_.isObject(a)) {
                            this.argsCleaner(a, 0);
                            result.push(a);
                        }
                        else if (_.isFunction(a)) {
                            result.push("[Function]");
                        }
                        else {
                            result.push(a);
                        }
                    }
                }
                else {
                    arg;
                    this.argsCleaner(arg, 0);
                    result.push(arg);
                }
            }
            catch (ex) {
                console.warn("Logger.argsCleaner", argKey, ex);
            }
        }
        return result;
    }
}
module.exports = Logger;
