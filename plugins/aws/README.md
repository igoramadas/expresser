# Expresser AWS

This is a wrapper around the AWS SDK for Node.js apps. Currently implements S3 and SNS features.

### Basic requirements

Fore more info on how to get your AWS credentials:

http://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/getting-your-credentials.html

And how to set your credentials on Node.js apps:

http://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html

### S3

Downloading a file from a S3 bucket:

    aws = require "expresser-aws"

    aws.s3.download "my-bucket-id", "my-filenametxt", "/var/myfiles/my-filename.txt", (err, result) =>
        if err?
            console.error err
        else
            console.log "Downloaded complete!"

Uploading a file to S3:

    aws = require "expresser-aws"

    aws.s3.upload "my-bucket-id", "my-upload.txt", "this is my file text", (err, result) =>
        if err?
            console.error err
        else
            console.log "Upload complete!"
