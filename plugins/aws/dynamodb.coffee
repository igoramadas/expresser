# AWS DYNAMODB
# -----------------------------------------------------------------------------
aws = require "aws-sdk"

errors = null
logger = null
settings = null

###
# Methods to read and modify data on AWS DynamoDB databases. On `init()` it will
# create a DynamoDB and a DocumentClient targeting the region defined on the
# settings. If you wish to change the region on runtime, please call the
# `createClients()` method manually passing {region: "REGION_ID"}.
###
class DynamoDB

    ##
    # Exposes a default DynamoDB main object to external modules.
    # @property
    # @type aws-DynamoDB
    db: null

    ##
    # Exposes a default DynamoDB document client to external modules.
    # @property
    # @type aws-DocumentClient
    docClient: null

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the AWS DynamoDB module. Should be called automatically by the main AWS module.
    # @param {AWS} parent The AWS main module.
    # @private
    ###
    init: (parent) =>
        errors = parent.expresser.errors
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        @createClients()
        delete @init

    ###
    # Creates the default DB and document clients. This is called on `init()`
    # automatically, but you can use it to change region and other options as desired.
    # @param {Object} options Database and document client options, optional.
    # @param {String} [options.region] The AWS region, if not passed will use default from settings.
    ###
    createClients: (options) =>
        options = {region: settings.aws.dynamodb.region} if not options?

        @db = new aws.DynamoDB options
        @docClient = new aws.DynamoDB.DocumentClient options

    # SDK HELPER
    # -------------------------------------------------------------------------

    ###
    # Helper to call the SDK method with the specified parameters.
    # @param {Object} obj AWS SDK object (db, docClient, etc).
    # @param {String} method AWS SDK method name.
    # @param {Object} method Parameters to be passed to the method above.
    # @return {Object} AWS SDK call result.
    # @private
    # @promise
    ###
    sdkCall: (obj, method, params) ->
        logger.debug "AWS.DynamoDB.#{method}", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            obj[method] params, (err, data) ->
                if err?
                    err = errors.reject "Problem calling DynamoDB on AWS.", err
                    logger.error "AWS.DynamoDB.#{method}", params, err
                    return reject err

                return resolve data

    # TABLES AND MANAGEMENT
    # -------------------------------------------------------------------------

    ###
    # Creates a new table on DynamoDB.
    # @param {Object} params The table parameters.
    # @return {Object} AWS SDK table creation results.
    # @promise
    ###
    createTable: (params) => return @sdkCall @db, "createTable", params

    ###
    # Deletes a table on DynamoDB.
    # @param {Object} params The table parameters.
    # @return {Object} AWS SDK table deletion results.
    # @promise
    ###
    deleteTable: (params) => return @sdkCall @db, "deleteTable", params

    # ITEMS
    # -------------------------------------------------------------------------

    ###
    # Gets all items (with optional filter) from the specified table.
    # @param {Object} params The query parameters.
    # @return {Object} AWS SDK scan results.
    # @promise
    ###
    scan: (params) => return @sdkCall @docClient, "scan", params

    ###
    # Query item(s) from the specified table.
    # @param {Object} params The query parameters.
    # @return {Object} AWS SDK query results.
    # @promise
    ###
    query: (params) => return @sdkCall @docClient, "query", params

    ###
    # Read an item from the specified table.
    # @param {Object} params The item parameters.
    # @return {Object} AWS SDK get results.
    # @promise
    ###
    get: (params) => return @sdkCall @docClient, "get", params

    ###
    # Creates a new item on the specified table.
    # @param {Object} params The item creation parameters.
    # @return {Object} AWS SDK put results.
    # @promise
    ###
    put: (params) => return @sdkCall @docClient, "put", params

    ###
    # Update item(s) on the specified table.
    # @param {Object} params The item update parameters.
    # @return {Object} AWS SDK update results.
    # @promise
    ###
    update: (params) => return @sdkCall @docClient, "update", params

    ###
    # Deletes item(s) from the specified table.
    # @param {Object} params The item deletion parameters.
    # @return {Object} AWS SDK delete results.
    # @promise
    ###
    delete: (params) => return @sdkCall @docClient, "delete", params

# Singleton implementation
# -----------------------------------------------------------------------------
DynamoDB.getInstance = ->
    @instance = new DynamoDB() if not @instance?
    return @instance

module.exports = DynamoDB.getInstance()
