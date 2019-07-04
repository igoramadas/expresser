"use strict";
// Expresser: logger.ts
/** @hidden */
const _ = require("lodash");
/** @hidden */
const jaul = require("jaul");
/** @hidden */
let settings = require("setmeup").settings;
/** Logger helper class to configure the Anyhow logging module. */
class Logger {
    /** Recursive arguments cleaner. */
    static argsCleaner(obj, index) {
        const max = settings.logger.maxDepth;
        // Argument is array?
        if (_.isArray(obj)) {
            for (let i = 0; i < obj.length; i++) {
                if (index >= max) {
                    obj[i] = "...";
                }
                else if (_.isFunction(obj[i])) {
                    obj[i] = "[Function]";
                }
                else {
                    Logger.argsCleaner(obj[i], index + 1);
                }
            }
        }
        // Arg is an object? Then recurisvely clean its sub properties.
        else if (_.isObject(obj)) {
            let keys = _.keys(obj);
            for (let key of keys) {
                let value = obj[key];
                try {
                    if (index >= max) {
                        obj[key] = "...";
                    }
                    else if (settings.logger.obfuscateFields && settings.logger.obfuscateFields.indexOf(key) >= 0) {
                        obj[key] = "****";
                    }
                    else if (settings.logger.maskFields && settings.logger.maskFields[key]) {
                        let maskedValue;
                        // Actual value might be hidden inside a value, text or data sub-property.
                        if (_.isObject(value)) {
                            maskedValue = value.value || value.text || value.data || value.toString();
                        }
                        else {
                            maskedValue = value.toString();
                        }
                        obj[key] = jaul.data.maskString(maskedValue, "*", settings.logger.maskFields[key]);
                    }
                    else if (settings.logger.removeFields && settings.logger.removeFields.indexOf(key) >= 0) {
                        delete obj[key];
                    }
                    else if (_.isArray(value)) {
                        for (let i = 0; i < value.length; i++) {
                            Logger.argsCleaner(value[i], index + 1);
                        }
                    }
                    else if (_.isFunction(value)) {
                        obj[key] = "[Function]";
                    }
                    else if (_.isObject(value)) {
                        Logger.argsCleaner(value, index + 1);
                    }
                }
                catch (ex) {
                    /* istanbul ignore next */
                    delete obj[key];
                    /* istanbul ignore next */
                    obj[key] = "[Unreadable]";
                }
            }
        }
    }
    /** Used as a preprocessor for the Anyhow logger. */
    static clean(args) {
        let result = [];
        for (let arg of args) {
            if (_.isError(arg)) {
                result.push(arg.toString());
            }
            else if (_.isObject(arg) || _.isArray(arg)) {
                let cloned = _.cloneDeep(arg);
                Logger.argsCleaner(cloned, 0);
                result.push(cloned);
            }
            else if (_.isFunction(arg)) {
                result.push("[Function]");
            }
            else {
                result.push(arg);
            }
        }
        return result;
    }
}
module.exports = Logger;
