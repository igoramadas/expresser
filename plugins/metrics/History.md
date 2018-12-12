# Changelog for expresser-metrics

3.2.0
=====
* NEW! Possible to add extra data to a metric object using setData().
* BREAKING! Due to new "data" feature above, the old "data" property was renamed to "tag".
* Now including a package-lock.json file.
* Updated dependencies.

3.1.6
=====
* Check for invalid metric on getLast (to get last samples).

3.1.5
=====
* Improved resilience on Metrics start / end.
* Default cleanup interval reduced to 30 minutes.
* Updated dependencies.

3.1.4
=====
* HTTP server start / kill returns false if already / not running.

3.1.3
=====
* General improvements and updated documentation.

3.1.2
=====
* BREAKING! Metrics expiration is now passed as milliseconds instead of seconds.
* Fixed metrics "expired" and "error" counters.
* Updated dependencies.

3.1.0
=====
* NEW! You can now set an expiry time (in seconds) for metrics.
* NEW! Expired metrics count shown on output as "expired".
* Changed default intervals and percentiles on output.

3.0.2
=====
* Fixed percentile values on metrics output (sometimes came as null).

3.0.1
=====
* Fixed average values on metrics output.

3.0.0
=====
* New option "cleanupEmpty" to remove empty metrics from the collection.
* Maintenance release for Expresser 3.0.0.

1.1.3
=====
* Maintenance release.

1.1.2
=====
* Maintenance release for Expresser > 2.3.2.

1.1.1
=====
* Improved logging of metrics cleanup.
* Default cleanup interval increased to 60min.

1.1.0
=====
* History starts here :-)
