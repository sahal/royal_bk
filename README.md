# royal_bk
Yet another backup solution... this one is royal.

How to use
----------
This comes with two scripts royal_bk.sh and trim_bk.sh.

**royal_bk.sh**

    ./royal_bk -h
    Usage: ./royal_bk.sh [OPTION...]
    Creates backups for specified files/dirs in $to_backup, stores in $backup/$prefix_$d, where $d is the date format

        -t full path to csv of dirs/files to backup (Default: $DIR/to-backup)
        -b full path to backup directory (Default: /tmp/backup)
        -p specify a prefix for the current backup directory (Default: hostname_)
        -d specify a date format (Default: %Y%m%d%I%M i.e. yyyymmddhhmm)
        -c if set then backup directory with be chowned to user:grp (optionally specified in -o)
        -o specify a chown user:grp (Default: root:root) must use with -c
        -h print this help

**trim_bk.sh**

    ./trim_bk.sh [prompt]
    Saves a list of outdated backups to a file "to-delete" in the $backup directory


Todo
----

* unify the configuration of both scripts.
* royal_bk.sh
  * gpg encryption of the tarballs
  * specify additional tar parameters
  * incremental backups
* trim_bk.sh
  * add getopts support
* better documentation
