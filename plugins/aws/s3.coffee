# AWS S3
# -----------------------------------------------------------------------------
aws = require "aws-sdk"
fs = require "fs"
path = require "path"
errors = null
lodash = null
logger = null
settings = null

###
# Handles communication with AWS S3.
###
class S3

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the S3 module. Called automatically by the main main AWS module.
    # @param {AWS} parent The main AWS module.
    # @private
    ###
    @init: (parent) ->
        errors = parent.expresser.errors
        lodash = parent.expresser.libs.lodash
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        delete @init

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Download a file from S3 and optionally save to the specified destination.
    # @param {String} bucket Name of the S3 bucket to download from.
    # @param {String} key Key of the target S3 bucket resource (usually a filename).
    # @param {String} destination Optional, full path to the destination where file should be saved.
    # @return {Object} The file contents as binary / buffer / string, depending on content type.
    # @promise
    ###
    @download: (bucket, key, destination) ->
        logger.debug "AWS.S3.download", bucket, key, destination

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3 = new aws.S3 {region: settings.aws.s3.region}
            params = {Bucket: bucket, Key: key}

            # First make sure the file exists in the S3 bucket, then fetch it.
            try
                s3.headObject params, (err, meta) ->
                    if err?
                        logger.error "AWS.S3.download", "headObject", bucket, key, err

                        # Hint for the user to login with the "mai" command.
                        if err.statusCode is 401 or err.statusCode is 403
                            logger.warn "AWS.S3.download", "Invalid permissions or not authorized to read #{bucket} #{key}."

                        return reject err

                    # Get data from S3 and write it to local disk.
                    s3.getObject params, (err, data) ->
                        if err?
                            logger.error "AWS.S3.download", "getObject", bucket, key, err
                            return reject err

                        body = data.Body

                        # Destination set? If so, write to disk.
                        if destination?
                            fs.writeFile destination, body, {encoding: settings.general.encoding}, (err) ->
                                if err?
                                    err = errors.reject "cantSaveFile", err
                                    logger.error "AWS.S3.download", "writeFile", bucket, key, destination, err
                                    return reject err
                                else
                                    logger.info "AWS.S3.download", bucket, key, "Saved #{data.ContentType}, #{data.ContentLength} bytes to #{destination}."
                                    return resolve body

                        # No destination? Simply return the file contents.
                        else
                            return resolve body
            catch ex
                logger.error "AWS.S3.download", "headObject", bucket, key, ex
                reject ex

    ###
    # Upload a file to S3.
    # @param {String} bucket Name of the S3 bucket to upload to.
    # @param {String} key Key of the target S3 bucket resource (usually a filename).
    # @param {Object} body Contents of the file to be uploaded.
    # @param {Object} options Upload options (please see AWS SDK for all options).
    # @param {String} [options.acl] ACL to be used, default is "public-read".
    # @param {String} [options.contentType] Content type of the file.
    # @return {Object} The upload result.
    # @promise
    ###
    @upload: (bucket, key, body, options) ->
        logger.debug "AWS.S3.upload", bucket, key, body, options

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3Bucket = new aws.S3 {region: settings.aws.s3.region, params: {Bucket: bucket}}
            options = lodash.defaults options, {acl: "public-read"}

            # Automagically discover the content type, if not set.
            if not options.contentType?
                ext = path.extname key
                options.contentType = "image/jpeg" if ext is ".jpg"
                options.contentType = "image/gif" if ext is ".gif"
                options.contentType = "image/png" if ext is ".png"
                options.contentType = "image/bmp" if ext is ".bmp"

            s3upload = s3Bucket.upload {
                ACL: options.acl,
                Body: body,
                Key: key,
                ContentType: options.contentType
            }

            # Upload the specified files!
            s3upload.send (err, result) ->
                if err?
                    err = errors.reject "cantUploadFile", err
                    logger.error "AWS.S3.upload", bucket, key, err
                    reject err
                else
                    logger.info "AWS.S3.upload", bucket, key
                    resolve result

    ###
    # Delete object(s) from S3. Keys can be a string or an array of strings.
    # @param {String} bucket Name of the S3 bucket to upload to.
    # @param {Array|String} keys Keys of items to be deleted from the bucket.
    # @return {Object} The delete result.
    # @promise
    ###
    @delete: (bucket, keys) ->
        logger.debug "AWS.S3.delete", bucket, keys

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3Bucket = new aws.S3 {region: settings.aws.s3.region, params: {Bucket: bucket}}

            objects = []
            keys = [keys] if lodash.isString keys
            objects.push {Key: value} for value in keys

            params = {
                Delete: {
                    Objects: objects
                }
            }

            # Delete the specified files!
            s3Bucket.deleteObjects params, (err, result) =>
                if err?
                    err = errors.reject "cantDeleteFile", err
                    logger.error "AWS.S3.delete", bucket, keys, err
                    reject err
                else
                    logger.info "AWS.S3.delete", bucket, keys
                    resolve result

# Exports
# -----------------------------------------------------------------------------
module.exports = S3
