Start/stop/delete/restart apps on any given org/space
=======================================================

pcfadmin is a powerful bash script that can be used to start/stop/restart/delete the applications in a given org or space. This would be very useful for the bulk operations like stoping all the apps in an org regardless of the spaces under that. The script is making use of CC API V2 and V3 for all the tasks. 

Prerequisites
-------------
You would need `cf` and `jq` installed in your system. 
You also need to be logged into the CF environment using `cf login` before you run the script.

Caution!
---------
Please be warned that if you are using this script without paying much attention to what org/space you are passing, it would do what it's supposed to do !! The script would ask your permission before it starts executing the needed task.

Usage
-----

Log into Cloud Foundry with your user credentials; you don't have to target any organization/space. 

```
Usage: ./pcfadmin.sh [-o org] [-s space] [-a app] [-act action]
  -o, --org   Organization
  -s, --space Space
  -a, --app   Application
  -act, --action   Start/Stop/Restart/Delete
```

Examples
--------
```
./pcfadmin.sh -o Finance -s stage -a all -act stop
```

In the above example, it's going to stop all the apps under the Org `Finance` and Space `stage`. The script will also generate a log file in the csv format with that details of `org, space, app, action` 

To delete all the apps under an org
------------------------------------

```
./pcfadmin.sh -o HR -s all -a all -act delete
```

This would iterate through all the Spaces and delete all the apps for the given Org `HR`. Please make sure that you are giving the correct Org name. Delete changes can't be undone!

To restart all the apps under all the org
-----------------------------------------

```
./pcfadmin.sh -o all -s all -a all -act restart
```

This would operate on all the Orgs that you have access to and restart all the apps under all the spaces and orgs.

