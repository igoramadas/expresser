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

            db.deleteTable params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.deleteTable", params, err
                    return reject err

                return resolve data

    # Waits for the specified event to be triggered.
    # @param {String} evt The event name.
    # @param {Object} params The event trigger parameters.
    waitFor: (evt, params) =>
        logger.debug "AWS.DynamoDB.waitFor", evt, params

        return new Promise (resolve, reject) ->
            db.waitFor evt, params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.waitFor", evt, params, err
                    return reject err

                return resolve data

    # ITEMS
    # -------------------------------------------------------------------------

    # Read an item from the specified table.
    # @param {Object} params The query parameters.
    query: (params) =>
        logger.debug "AWS.DynamoDB.query", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.query")

            docClient.query params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.query", params, err
                    return reject err

                return resolve data

    # Read an item from the specified table.
    # @param {Object} params The item parameters.
    get: (params) =>
        logger.debug "AWS.DynamoDB.get", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.get")

            docClient.get params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.get", params, err
                    return reject err

                return resolve data

    # Creates a new item on the specified table.
    # @param {Object} params The item creation parameters.
    put: (params) =>
        logger.debug "AWS.DynamoDB.put", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.put")

            docClient.put params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.put", params, err
                    return reject err

                return resolve data

    # Update an item on the specified table.
    # @param {Object} params The item update parameters.
    update: (params) =>
        logger.debug "AWS.DynamoDB.update", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.update")

            docClient.update params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.update", params, err
                    return reject err

                return resolve data

    # Deletes an item from the specified table.
    # @param {Object} params The item deletion parameters.
    delete: (params) =>
        logger.debug "AWS.DynamoDB.delete", params

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "DynamoDB.delete")

            docClient.delete params, (err, data) ->
                if err?
                    logger.error "AWS.DynamoDB.delete", params, err
                    return reject err

                return resolve data

# Singleton implementation
# -----------------------------------------------------------------------------
DynamoDB.getInstance = ->
    @instance = new DynamoDB() if not @instance?
    return @instance

module.exports = exports = DynamoDB.getInstance()
