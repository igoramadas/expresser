# Expresser AWS

This is a wrapper around the AWS SDK for Node.js apps:

https://www.npmjs.com/package/aws-sdk

Currently implements some restricted features of DynamoDB, S3 and SNS.

### Basic requirements

Fore more info on how to get your AWS credentials:

http://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/getting-your-credentials.html

And how to set your credentials on Node.js apps:

http://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html

### S3

Downloading a file from a S3 bucket:

    expresser = require("expresser")
    aws = require("expresser-aws")

    try
        var result = aws.s3.download("my-bucket-id", "my-filenametxt", "/var/myfiles/my-filename.txt")
        console.log(result)
    catch ex
        expresser.logger.error(ex)

Uploading a file to S3:

    expresser = require("expresser")
    aws = require("expresser-aws")

    try
        result = aws.s3.upload("my-bucket-id", "my-upload.txt", "this is my file text")
        console.log(result)
    catch ex
        expresser.logger.error(ex)
