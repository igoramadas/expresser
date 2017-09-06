# AWS DYNAMODB
# -----------------------------------------------------------------------------
# Wrapper for Amazon's DynamoDB.
class DynamoDB

    aws = require "aws-sdk"

    logger = null
    settings = null

    # Database and document clients are created on init.
    db = null
    docClient = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the DynamoDB module.
    init: (parent) ->
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        # Create the DynamoDB handler.
        db = new aws.DynamoDB {region: settings.aws.dynamodb.region}
        docClient = new aws.DynamoDB.DocumentClient {region: settings.aws.dynamodb.region}

        delete @init

    # TABLES AND MANAGEMENT
    # -------------------------------------------------------------------------

    # Creates a new table on DynamoDB.
    # @param {Object} params The table parameters.
    createTable: (params) =>
        logger.debug "AWS.DynamoDB.createTable", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.createTable")

            # Do some basic validation against the parameters.
            if not params?
                return reject "No parameters were passed for table creation."
            if not params?.TableName?
                return reject "A 'TableName' is mandatory."

            db.createTable params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.createTable", params, err
                    return reject err

                return resolve data

    # Deletes a table on DynamoDB.
    # @param {Object} params The table parameters.
    deleteTable: (params) =>
        logger.debug "AWS.DynamoDB.deleteTable", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.deleteTable")

            # Do some basic validation against the parameters.
            if not params?.TableName?
                return reject "A 'TableName' is mandatory."

            db.deleteTable params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.deleteTable", params, err
                    return reject err

                return resolve data

    # Waits for the specified event to be triggered.
    # @param {String} evt The event name.
    # @param {Object} params The table parameters.
    waitFor: (evt, params) =>
        logger.debug "AWS.DynamoDB.waitFor", evt, params

        # Do some basic validation against the parameters.
        if not evt?
            return reject "The event name is mandatory."

        return new Promise (resolve, reject) ->
            db.waitFor evt, params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.waitFor", evt, params, err
                    return reject err

                return resolve data

    # ITEMS
    # -------------------------------------------------------------------------

    # Read an item from the specified table.
    # @param {String} table The table name.
    # @param {Object} attributes Key/values equivalent to the ExpressionAttributeNames.
    # @param {Object} values Key/values equivalent to the ExpressionAttributeValues.
    # @param {String} expression Expression equivalent to the KeyConditionExpression.
    query: (table, attributes, values, expression) =>
        logger.debug "AWS.DynamoDB.query", table, key

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.query")

            # Do some basic validation against the parameters.
            if not table? or table is ""
                return reject "Please specify a valid table name."
            if not values? and not attrs?
                return reject "Please specify valid values and attributes to execute the query."

            params = {
                TableName: table
                KeyConditionExpression: expression
                ExpressionAttributeNames: attributes
                ExpressionAttributeValues: values
            }

            docClient.query params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.query", table, expression
                    return reject err

                return resolve data

    # Read an item from the specified table.
    # @param {String} table The table name.
    # @param {Object} key The item's key data.
    get: (table, key) =>
        logger.debug "AWS.DynamoDB.get", table, key

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.get")

            # Do some basic validation against the parameters.
            if not table? or table is ""
                return reject "Please specify a valid table name."
            if not key?
                return reject "The item's key must be a valid key/pair object."

            params = {
                TableName: table
                Key: key
            }

            docClient.get params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.get", table, key, err
                    return reject err

                return resolve data

    # Creates a new item on the specified table.
    # @param {Object} params The item creation parameters.
    put: (params) =>
        logger.debug "AWS.DynamoDB.put", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.put")

            # Do some basic validation against the parameters.
            if not params.TableName? or params.TableName is ""
                return reject "Please specify a valid TableName."
            if not params.Item?
                return reject "The Item must be a valid object."

            docClient.put params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.put", err
                    return reject err

                return resolve data

    # Update an item on the specified table.
    # @param {String} table The table name.
    # @param {Object} key The item's key data.
    # @param {Object} values Key/values equivalent to the ExpressionAttributeValues.
    # @param {String} expression Expression equivalent to the UpdateExpression.
    # @param optional {String} condition Optional condition expression.
    update: (params) =>
        logger.debug "AWS.DynamoDB.update", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.update")

            # Do some basic validation against the parameters.
            if not table? or table is ""
                return reject "Please specify a valid table name."
            if not key?
                return reject "The item's key must be a valid key/pair object."
            if not values? and not expression?
                return reject "Please set the update's expression and values."

            params = {
                TableName: table
                Key: key
                ExpressionAttributeValues: values
                UpdateExpression: expression
                ConditionExpression: condition
            }

            docClient.update params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.update", table, key, expression, err
                    return reject err

                return resolve data

    # Deletes an item from the specified table.
    # @param {Object} params The item deletion parameters.
    delete: (params) =>
        logger.debug "AWS.DynamoDB.delete", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.delete")

            # Do some basic validation against the parameters.
            if not table? or table is ""
                return reject "Please specify a valid table name."
            if not key?
                return reject "The key must be a valid object."

            params = {
                TableName: table
                Key: key
                ExpressionAttributeValues: values
                ConditionExpression: condition
            }

            docClient.delete params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.delete", table, key, err
                    return reject err

                return resolve data

# Singleton implementation
# -----------------------------------------------------------------------------
DynamoDB.getInstance = ->
    @instance = new DynamoDB() if not @instance?
    return @instance

module.exports = exports = DynamoDB.getInstance()
