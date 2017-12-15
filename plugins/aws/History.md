# Changelog for expresser-aws

3.2.0
=====
* NEW! SDK now exposed via the aws.sdk property.
* BREAKING! S3.download now returns the body as it is instead of .toString().
* Updated AWS SDK.

3.1.3
=====
* Updated AWS SDK.

3.1.2
=====
* Updated AWS SDK.

3.1.1
=====
* Updated AWS SDK.

3.1.0
=====
* NEW! DynamoDB is now implemented on the module.
* Updated AWS SDK.

3.0.2
=====
* Improved handling of S3 downloads and uploads.
* Updated AWS SDK.

3.0.1
=====
* Updated AWS SDK.

3.0.0
=====
* NEW! Now using Promises and compatible with async / await.
* Compatible with Expresser 3.0.0.

1.0.5
=====
* Maintenance release.

1.0.4
=====
* Updated AWS SDK.

1.0.3
=====
* Updated AWS SDK.

1.0.2
=====
* Param "options" is now optional on s3.upload.

1.0.1
=====
* Improved logging on SNS publish.

1.0.0
=====
* First release, support for AWS S3 only.
