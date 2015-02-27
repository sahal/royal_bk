# royal_bk
Yet another backup solution... this one is royal.

How to use
----------
This comes with two scripts royal_bk.sh and trim_bk.sh.

**royal_bk.sh**

    Usage: ./royal_bk.sh [OPTION...]
    Creates backups for specified files/dirs in $to_backup, stores in $backup/$prefix_$d, where $d is the date format

        -t full path to csv of dirs/files to backup (Default: $DIR/config/to-backup)
        -b full path to backup directory (Default: /tmp/backup/)
        -p specify a prefix for the current backup directory (Default: hostname_)
        -d specify a date format (Default: hhmm) 
                                 hhmm=%Y%m%d%I%M i.e. yyyymmddhhmm
                                 ymd=%Y%m%d i.e. yyyymmdd
        -c if set then backup directory with be chowned to user:grp (optionally specified in -o)
        -o specify a chown user:grp (Default: root:root) must use with -c
        -h print this help

**trim_bk.sh**

    ./trim_bk.sh -h
    Usage: ./trim_bk.sh [OPTION...]
    Prints a list of directories with $prefix in $backup that should be deleted based on rotation schedule.

        -e full path to file that stores a list of directories to delete (Default: $DIR/config/to-delete)
        -b full path to backup directory (Default: /tmp/backup/)
        -p specify a prefix for the current backup directory (Default: hostname_)
        -a ask (or prompt) to append $to_delete
        -h print this help

Todo
----

* royal_bk.sh
  * gpg encryption of the tarballs
  * specify additional tar parameters
  * incremental backups
* trim_bk.sh
* better documentation
