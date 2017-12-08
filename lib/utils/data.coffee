# EXPRESSER UTILS: DATA
# -----------------------------------------------------------------------------
# General data utilities.
class DataUtils
    newInstance: -> return new DataUtils()

    lodash = require "lodash"
    util = require "util"

    # Removes all the specified characters from a string. For example you can cleanup
    # phone numbers by using removeFromString(phone, [" ", "-", "(", ")"]).
    # @param {String} value The original value / string.
    # @param {Array} charsToRemove List of characters to be removed from the original string.
    # @return {String} Resulting value with the characters removed.
    removeFromString: (value, charsToRemove) ->
        return value if not value? or value is ""

        result = value
        result = result.toString() if not lodash.isString result
        result = result.split(c).join("") for c in charsToRemove

        return result

    # Masks the specified string. For eaxmple to mask a phone number but leave the
    # last 4 digits visible you could use maskString(phone, "X", 4).
    # @param {String} value The original value / string.
    # @param {String} maskChar Optional character to be used on the masking, default is *.
    # @param {Number} leaveLast Optional, leave last X positiongs of the string unmasked.
    # @return {String} Masked string.
    maskString: (value, maskChar, leaveLast) ->
        return value if not value? or not value or value is ""

        # Make sure value is a string!
        value = value.toString() if not lodash.isString value

        separators = [" ", "-", "_", "+", "=", "/"]
        maskChar = "*" if not maskChar? or maskChar is ""
        leaveLast = 0 if not leaveLast? or leaveLast < 1
        result = ""
        i = 0

        # First split characters, then iterate to replace.
        arr = value.split ""

        while i < arr.length - leaveLast
            char = arr[i]

            if separators.indexOf(char) < 0
                result += maskChar
            else
                result += char

            i++

        # Add last characters?
        if leaveLast > 0
            result += value.substr(value.length - leaveLast)

        return result

    # Minify the passed JSON value. Removes comments, unecessary white spaces etc.
    # @param {String} source The JSON text to be minified.
    # @param {Boolean} asString If true, return as string instead of JSON object.
    # @return {String} The minified JSON, or an empty string if there's an error.
    minifyJson: (source, asString) ->
        source = JSON.stringify(source, null, 0) if typeof source is "object"
        index = 0
        length = source.length
        result = ""
        symbol = undefined
        position = undefined

        # Main iterator.
        while index < length

            symbol = source.charAt index
            switch symbol

                # Ignore whitespace tokens. According to ES 5.1 section 15.12.1.1,
                # whitespace tokens include tabs, carriage returns, line feeds, and
                # space characters.
                when "\t", "\r"
                , "\n"
                , " "
                    index += 1

                # Ignore line and block comments.
                when "/"
                    symbol = source.charAt(index += 1)
                    switch symbol

                        # Line comments.
                        when "/"
                            position = source.indexOf("\n", index)

                            # Check for CR-style line endings.
                            position = source.indexOf("\r", index)  if position < 0
                            index = (if position > -1 then position else length)

                        # Block comments.
                        when "*"
                            position = source.indexOf("*/", index)
                            if position > -1

                                # Advance the scanner's position past the end of the comment.
                                index = position += 2
                                break
                            throw SyntaxError "Unterminated block comment."
                        else
                            throw SyntaxError "Invalid comment."

                # Parse strings separately to ensure that any whitespace characters and
                # JavaScript-style comments within them are preserved.
                when "\""
                    position = index
                    while index < length
                        symbol = source.charAt(index += 1)
                        if symbol is "\\"

                            # Skip past escaped characters.
                            index += 1
                        else break  if symbol is "\""
                    if source.charAt(index) is "\""
                        result += source.slice(position, index += 1)
                        break
                    throw SyntaxError "Unterminated string."

                # Preserve all other characters.
                else
                    result += symbol
                    index += 1

        # Check if should return as string or JSON.
        if asString
            return result
        else
            return JSON.parse result

    # Generates a RFC1422-compliant unique ID using random numbers.
    # @return {String} A single unique ID.
    uuid: ->
        baseStr = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        generator = (c) ->
            r = Math.random() * 16 | 0
            v = if c is "x" then r else (r & 0x3|0x8)
            v.toString 16

        return baseStr.replace(/[xy]/g, generator)

# Singleton implementation
# --------------------------------------------------------------------------
DataUtils.getInstance = ->
    @instance = new DataUtils() if not @instance?
    return @instance

module.exports = DataUtils.getInstance()
