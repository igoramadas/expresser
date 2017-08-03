# AWS S3
# -----------------------------------------------------------------------------
# Handles communication with AWS S3.
class S3

    aws = require "aws-sdk"
    fs = require "fs"
    path = require "path"

    lodash = null
    logger = null
    settings = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the S3 module.
    init: (parent) ->
        lodash = parent.expresser.libs.lodash
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        delete @init

    # METHODS
    # -------------------------------------------------------------------------

    # Download a file from S3 and optionally save to the specified destination.
    # @param {String} bucket Name of the S3 bucket to download from.
    # @param {String} key Key of the target S3 bucket resource (usually a filename).
    # @param {String} destination Optional, full path to the destination where file should be saved.
    download: (bucket, key, destination) ->
        s3 = new aws.S3 {region: settings.aws.s3.region}
        params = {Bucket: bucket, Key: key}

        # First make sure the file exists in the S3 bucket, then fetch it.
        return new Promise (resolve, reject) ->
            s3.headObject params, (err, meta) ->
                if err?
                    if err.retryable and err.retryDelay < 60
                        logger.error "AWS.S3.download", "headObject", "Retry in #{err.retryDelay}s", bucket, key, err
                    else
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

                    body = data.Body.toString()

                    # Destination set? If so, write to disk.
                    if destination?
                        fs.writeFile destination, body, {encoding: settings.general.encoding}, (err) ->
                            if err?
                                logger.error "AWS.S3.download", "writeFile", bucket, key, destination, err
                                reject err
                            else
                                resolve body

                    # No destination? Simply return the file contents.
                    else
                        resolve body

    # Upload a file to S3.
    # @param {String} bucket Name of the S3 bucket to upload to.
    # @param {String} key Key of the target S3 bucket resource (usually a filename).
    # @param {Object} body Contents of the file to be uploaded.
    # @param {Object} options Upload options.
    # @option options {String} acl ACL to be used, default is "public-read".
    # @option options {String} contentType Content type of the file.
    upload: (bucket, key, body, options) ->
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

        # Send file to S3!
        return new Promise (resolve, reject) ->
            s3upload.send (err, result) ->
                if err?
                    logger.error "AWS.S3.upload", bucket, key, err
                    reject err
                else
                    logger.info "AWS.S3.upload", bucket, key
                    resolve result

    # Delete object(s) from S3. Keys can be a string or an array of strings.
    delete: (bucket, keys) ->
        s3Bucket = new aws.S3 {region: settings.aws.s3.region, params: {Bucket: bucket}}
        objects = []

        # Make sure keys is an array and set the delete parameters.
        keys = [keys] if lodash.isString keys
        objects.push {Key: value} for value in keys

        params = {
            Delete: {
                Objects: objects
            }
        }

        # Delete files!
        return new Promise (resolve, reject) ->
            s3Bucket.deleteObjects params, (err, result) =>
                if err?
                    logger.error "AWS.S3.delete", bucket, keys, err
                    reject err
                else
                    logger.info "AWS.S3.delete", bucket, keys
                    resolve result

# Singleton implementation
# -----------------------------------------------------------------------------
S3.getInstance = ->
    @instance = new S3() if not @instance?
    return @instance

module.exports = exports = S3.getInstance()
