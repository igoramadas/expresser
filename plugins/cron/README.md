! Expresser Cron

The Cron is a built-in scheduled jobs manager. You can use it by loading jobs from JSON files or by calling its methods programmatically.

!!! Loading from json

By default {{ settings.cron.loadOnInit == true }} the Cron will look for a cron.json file and load it on init. You can also load your own specific files by calling the {{ cron.load }} method passing the filename and general options.

The most important options are {{ autoStart }} and {{ basePath }}. If autoStart is true, it will run all jobs straight away when loading. The basePath sets the base path relative to the app root where the specified module / scripts are located. So for example if you want to load scripts from files located on /lib/modules/, call {{ load("my_cron_filename.json", {basePath: "lib/modules/"}) }}.

A sample of a cron.json file:

{{
{
    "mydatabase.coffee": [
        {
            "callback": "cleanup",
            "args": ["collection1", "collection2"],
            "description": "Clean database every 300 seconds.",
            "schedule": 300,
            "enabled": true
        },
        {
            "callback": "report",
            "description": "Send database reports 3 times a day. Temporarily disabled.",
            "schedule": ["11:00:00", "18:00:00", "23:00"],
            "enabled": false
        }
    ],
    "controller.coffee": [
        {
            "callback": "verifySomething",
            "args": "something here",
            "description": "Verify something every 2 minutes.",
            "schedule": 120,
            "enabled": true
        }
    ]
}
}}

And a brief description of the properties of a cron.json file:
* *mydatabase.coffee* The filename of the module / script which contains the methods to be executed by the cron. It's value must be an array with the details specified below.
** *callback* The name of the method to be executed.
** *args* Optional arguments to be passed along the callback.
** *description* Brief description of the cron job.
** *schedule* Interval in seconds if a number, or an array of specific times of the day.
** *enabled* If false, the job won't be scheduled, default is true.

The callback will receive the full job specification as argument. So you can add extra properties to the job specification and access them inside the callback. For example:

{{
function cleanup(job) {
  console.log(job.description);
  doCleanUp(job.args);
}
}}

!!! Adding jobs programmatically

Use the {{ cron.add(jobId, jobSpecs) }} method, passing an optional job ID and the following specifications:
* *callback* The function to be executed.
* *schedule* Interval in seconds if a number, or an array of specific times of the day.
* *description* Optional, job description.
* *once* Optional, if true it will run the job only once.

Please note that if {{ settings.cron.allowReplacing }} is false, adding an existing job (same ID) won't be allowed.

!!! Controlling jobs programmatically

To stop jobs (won't run on schedule anymore), use the {{ cron.stop }} method passing the job ID or a filter. Filters can be any job property, like its module name or description.

To start jobs again (in case they were stopped before), use the {{ cron.start }} method. Same thing as stopping, pass the ID or filter.


For detailed info on specific features, check the annotated source on /docs folder.
