// Anyhow: Utils (largely based on lodash.js)

/**
 * Get the passed object's tag.
 * @param value Object or value.
 */
export const getTag = (value) => {
    const toString = Object.prototype.toString

    if (value == null) {
        return value === undefined ? "[object Undefined]" : "[object Null]"
    }

    return toString.call(value)
}

/**
 * Check if the passed value is an object.
 * @param value Object or value.
 */
export const isObject = (value): boolean => {
    return typeof value === "object" && value !== null
}

/**
 * Check if the passed value is a plain object.
 * @param value Object or value.
 */
export const isPlainObject = (value): boolean => {
    if (!isObject(value) || getTag(value) != "[object Object]") {
        return false
    }

    if (Object.getPrototypeOf(value) === null) {
        return true
    }

    let proto = value
    while (Object.getPrototypeOf(proto) !== null) {
        proto = Object.getPrototypeOf(proto)
    }

    return Object.getPrototypeOf(value) === proto
}

/**
 * Check if the passed value is an array.
 * @param value Object or value.
 */
export const isArray = (value): boolean => {
    return value && Array.isArray(value)
}

/**
 * Check if the passed value is same as args.
 * @param value Object or value.
 */
export const isArguments = (value): boolean => {
    return isObject(value) && getTag(value) == "[object Arguments]"
}

/**
 * Check if the passed value is an error.
 * @param value Object or value.
 */
export const isError = (value): boolean => {
    if (!isObject(value)) {
        return false
    }

    const tag = getTag(value)
    return tag == "[object Error]" || tag == "[object DOMException]" || (typeof value.message === "string" && typeof value.name === "string" && !isPlainObject(value))
}

/**
 * Check if the passed value is a string.
 * @param value Object or value.
 */
export const isFunction = (value): boolean => {
    return typeof value === "function"
}

/**
 * Check if the passed value is null or undefined.
 * @param value Object or value.
 */
export const isNil = (value): boolean => {
    return value === null || typeof value == "undefined"
}

/**
 * Check if the passed value is a string.
 * @param value Object or value.
 */
export const isString = (value): boolean => {
    const type = typeof value
    return type === "string" || (type === "object" && value != null && !Array.isArray(value) && getTag(value) == "[object String]")
}

/**
 * Flatten the passed array.
 * @param value Object or value.
 */
export const flattenArray = (array, depth?, result?): any[] => {
    const length = array == null ? 0 : array.length
    if (!length) return []

    if (isNil(depth)) depth = 1 / 0
    if (isNil(result)) result = []

    const predicate = (value) => Array.isArray(value) || isArguments(value) || !!(value && value[Symbol.isConcatSpreadable])

    if (array == null) {
        return result
    }

    for (const value of array) {
        if (depth > 0 && predicate(value)) {
            if (depth > 1) {
                flattenArray(value, depth - 1, result)
            } else {
                result.push(...value)
            }
        } else {
            result[result.length] = value
        }
    }

    return result
}
