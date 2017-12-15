# AWS DYNAMODB
# -----------------------------------------------------------------------------
aws = require "aws-sdk"
logger = null
settings = null

# Database and document clients are created on init.
db = null
docClient = null

###
# Reads and modify data on AWS DynamoDB databases.
###
class DynamoDB

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the DynamoDB module. Called automatically by the main main AWS module.
    # @private
    ###
    @init: (parent) ->
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        # Create the DynamoDB handler.
        db = new aws.DynamoDB {region: settings.aws.dynamodb.region}
        docClient = new aws.DynamoDB.DocumentClient {region: settings.aws.dynamodb.region}

        delete @init

    # SDK HELPER
    # -------------------------------------------------------------------------

    ###
    # Helper to call the SDK method with the specified parameters.
    # @private
    ###
    @sdkCall: (obj, method, params) ->
        logger.debug "AWS.DynamoDB.#{method}", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.#{method} aborted because settings.aws.enabled is false.")

            obj[method] params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.#{method}", params, err
                    return reject err

                return resolve data

    # TABLES AND MANAGEMENT
    # -------------------------------------------------------------------------

    ###
    # Creates a new table on DynamoDB.
    # @param {Object} params The table parameters.
    ###
    @createTable: (params) -> return @sdkCall db, "createTable", params

    # Deletes a table on DynamoDB.
    # @param {Object} params The table parameters.
    @deleteTable: (params) -> return @sdkCall db, "deleteTable", params

    # ITEMS
    # -------------------------------------------------------------------------

    ###
    # Gets all items (with optional filter) from the specified table.
    # @param {Object} params The query parameters.
    ###
    @scan: (params) -> return @sdkCall docClient, "scan", params

    ###
    # Query item(s) from the specified table.
    # @param {Object} params The query parameters.
    ###
    @query: (params) -> return @sdkCall docClient, "query", params

    ###
    # Read an item from the specified table.
    # @param {Object} params The item parameters.
    ###
    @get: (params) -> return @sdkCall docClient, "get", params

    ###
    # Creates a new item on the specified table.
    # @param {Object} params The item creation parameters.
    ###
    @put: (params) -> return @sdkCall docClient, "put", params

    ###
    # Update item(s) on the specified table.
    # @param {Object} params The item update parameters.
    ###
    @update: (params) -> return @sdkCall docClient, "update", params

    ###
    # Deletes item(s) from the specified table.
    # @param {Object} params The item deletion parameters.
    ###
    @delete: (params) -> return @sdkCall docClient, "delete", params

# Exports
# -----------------------------------------------------------------------------
module.exports = DynamoDB
