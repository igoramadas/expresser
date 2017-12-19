# AWS S3
# -----------------------------------------------------------------------------
aws = require "aws-sdk"
fs = require "fs"
path = require "path"

expresser = require "expresser"
errors = expresser.errors
lodash = expresser.libs.lodash
logger = expresser.logger
settings = expresser.settings

###
# Handles communication with AWS S3.
###
class S3

    ###
    # Download a file from S3 and optionally save to the specified destination.
    # @param {Object} options Download options.
    # @param {String} [options.bucket] Name of the S3 bucket to download from.
    # @param {String} [options.key] Key of the target S3 bucket resource (usually a filename).
    # @param {String} [options.destination] Optional, full path to the destination where file should be saved.
    # @param {String} [options.region] The AWS region, if not passed will use default from settings.
    # @return {Object} The file contents as binary / buffer / string, depending on content type.
    # @promise
    ###
    download: (options) =>
        logger.debug "AWS.S3.download", options

        # DEPRECATED! Please use a single `options` with named parameters.
        if arguments.length > 1
            logger.deprecated "AWS.S3.download(bucket, key, destination)", "Please use download(options) passing the named parameters."

            options = {
                bucket: arguments[0]
                key: arguments[1]
                destination: arguments[2]
            }

        # Accept uppercased parameters as well, like in the AWS SDK.
        options.bucket = options.Bucket if not options.bucket?
        options.key = options.Key if not options.key?

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3 = new aws.S3 {region: options.region or settings.aws.s3.region}

            params = {
                Bucket: options.bucket
                Key: options.key
            }

            # First make sure the file exists in the S3 bucket, then fetch it.
            try
                s3.headObject params, (err, meta) ->
                    if err?
                        logger.error "AWS.S3.download", "headObject", options.bucket, options.key, err

                        # Hint for the user to login with the "mai" command.
                        if err.statusCode is 401 or err.statusCode is 403
                            logger.warn "AWS.S3.download", "Invalid permissions or not authorized to read #{options.bucket} #{options.key}."

                        return reject err

                    # Get data from S3 and write it to local disk.
                    s3.getObject params, (err, data) ->
                        if err?
                            logger.error "AWS.S3.download", "getObject", options.bucket, options.key, err
                            return reject err

                        # Destination set? If so, write to disk.
                        if options.destination?
                            fs.writeFile options.destination, data.Body, {encoding: settings.general.encoding}, (err) ->
                                if err?
                                    err = errors.reject "cantSaveFile", err
                                    logger.error "AWS.S3.download", "writeFile", options.bucket, options.key, err
                                    return reject err
                                else
                                    logger.info "AWS.S3.download", "writeFile", options.bucket, options.key, {data.ContentType, "#{data.ContentLength} bytes", options.destination
                                    return resolve data.Body

                        # No destination? Simply return the file contents.
                        else
                            return resolve data.Body
            catch ex
                logger.error "AWS.S3.download", "headObject", options, ex
                reject ex

    ###
    # Upload a file to S3.
    # @param {Object} options Upload options.
    # @param {String} [options.bucket] Name of the S3 bucket to upload to.
    # @param {String} [options.key] Key of the target S3 bucket resource (usually a filename).
    # @param {Object} [options.body] Contents of the file to be uploaded.
    # @param {String} [options.contentType] Content type of the file.
    # @param {String} [options.acl] ACL to be used, default is "public-read".
    # @param {String} [options.region] The AWS region, if not passed will use default from settings.
    # @return {Object} The upload result.
    # @promise
    ###
    upload: (options) =>
        logger.debug "AWS.S3.upload", options

        # DEPRECATED! Please use a single `options` with named parameters.
        if arguments.length > 1
            logger.deprecated "AWS.S3.upload(bucket, key, body, options)", "Please use upload(options) passing the named parameters."

            options = if arguments.length > 2 then arguments[3] else {}
            options.Bucket = arguments[0]
            options.Key = arguments[1]
            options.Body = arguments[2]

        # Accept uppercased parameters as well, like in the AWS SDK.
        options.bucket = options.Bucket if not options.bucket?
        options.key = options.Key if not options.key?
        options.body = options.Body if not options.body?
        options.contentType = options.ContentType if not options.contentType?

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3Bucket = new aws.S3 {region: options.region or settings.aws.s3.region, params: {Bucket: options.bucket}}

            # Default ACL is public-read!
            options.acl = "public-read" if not options.acl?

            # Automagically discover the content type, if not set.
            if not options.contentType?
                ext = path.extname key
                options.contentType = "image/jpeg" if ext is ".jpg"
                options.contentType = "image/gif" if ext is ".gif"
                options.contentType = "image/png" if ext is ".png"
                options.contentType = "image/bmp" if ext is ".bmp"

            s3upload = s3Bucket.upload {
                ACL: options.acl,
                Body: options.body,
                Key: options.key,
                ContentType: options.contentType
            }

            # Upload the specified files!
            s3upload.send (err, result) ->
                if err?
                    err = errors.reject "cantUploadFile", err
                    logger.error "AWS.S3.upload", options.bucket, options.key, options.contentType, err
                    reject err
                else
                    logger.info "AWS.S3.upload", options.bucket, options.key, options.contentType
                    resolve result

    ###
    # Delete object(s) from S3.
    # @param {Object} options Delete options.
    # @param {String} [options.bucket] Name of the S3 bucket to upload to.
    # @param {Array|String} [options.keys] Keys of items to be deleted from the bucket.
    # @param {String} [options.region] The AWS region, if not passed will use default from settings.
    # @return {Object} The delete result.
    # @promise
    ###
    delete: (options) ->
        logger.debug "AWS.S3.delete", options

        # DEPRECATED! Please use a single `options` with named parameters.
        if arguments.length > 1
            logger.deprecated "AWS.S3.delete(bucket, keys)", "Please use download(options) passing the named parameters."

            options = {
                bucket: arguments[0]
                keys: arguments[1]
            }

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            s3Bucket = new aws.S3 {region: options.region or settings.aws.s3.region, params: {Bucket: options.bucket}}

            objects = []
            options.keys = [keys] if lodash.isString options.keys
            objects.push {Key: value} for value in options.keys

            params = {
                Delete: {
                    Objects: objects
                }
            }

            # Delete the specified files!
            s3Bucket.deleteObjects params, (err, result) =>
                if err?
                    err = errors.reject "cantDeleteFile", err
                    logger.error "AWS.S3.delete", options.bucket, options.keys, err
                    reject err
                else
                    logger.info "AWS.S3.delete", options.bucket, options.keys, keys
                    resolve result

# Singleton implementation
# --------------------------------------------------------------------------
S3.getInstance = ->
    @instance = new S3() if not @instance?
    return @instance

module.exports = S3.getInstance()
