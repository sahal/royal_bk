#!/bin/bash
# ./royal_bk.sh
# by Sahal Ansari (github@sahal.info)
#
# desc: create tarballs of files/dirs listed in $to_backup at current
#       date $d and store in directory $move ("$backup""$prefix""$d")
# todo: * support adding optional tar parameters
#       * add support for gpg
#
# Copyright (c) 2015 Sahal Ansari github@sahal.info
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE. 

set -e

# directory where script is located
DIR="$( cd "$( dirname "$0" )" && pwd )"

# backup directory and prefix
# include trailing slash
backup="/tmp/backup/"
prefix="$(/bin/hostname)""_"
#prefix="iLL_"

## DATE FORMAT set as $d
## set date to yyyymmdd
#d="$(date +%Y%m%d)"
## set date to yyyymmddhhmm
d="$(date +%Y%m%d%I%M)"

## final destination for backups
move="$backup""$prefix""$d"

# chown the tarballs to a specific user/group afterwards
# 1 - yes, any other number - no
chown_or_naw="0"
# chown the backups to a specific user
chowner="sahal:sahal"

# default exclude list (if not specified later) for tar
# include trailling slash for directories
default_exclude=( "/mnt/" "/proc/" "/run/" "/media/" )

# $to_backup is a csv (w/ a semicolon ";" delimter) of files/dirs to
#            backup in the following format
# backup.tar.gz;full-path-to_file/dir_to-backup;exclude1(optional);excludeN(optional)
# NOTE: there are NO spaces before/after the ";",
#       lines starting with a hash "#" are ignored,
#       for dirs to backup/exclude: include the trailing slash,
#       do not use asterisks to specify directories
# full path to $to_backup
to_backup="$DIR""/to-backup"

# or create the file here
if [ ! -e "$to_backup" ]; then
cat > "$to_backup" <<EOF
# backup csv with semicolon delimters
# home directories
home.tar.gz;/home/;/home/kropotkin/;/home/aspies/;/home/sacco/;/home/bakunin/
# root backups
#root_home.tar.gz;/root/
#etc.tar.gz;/etc/
EOF
fi


function main {
#create $move directory and change into it
mkdir -p "$move"
cd "$move"

files_to_backup=( $(grep -v "^#" < "$to_backup" ) )

for each_line in "${files_to_backup[@]}"
do
    # split each line -- at ; -- into paramaters
    # feed that to create_tarball function
    IFS=';' read -a create_tarball_parameters <<< "$each_line"
    create_tarball "${create_tarball_parameters[@]}"
done

if [ "$chown_or_naw" -eq "1" ]; then
    chown -R "$chowner" "$move"
fi
}

# excludes directories specified in parameters $@
function do_exclude {

local excluded_files=( "${@}" )

# if there are no explicitly excluded files we exclude from the default_exclude array
if [ "${#excluded_files[@]:-}" -ne "0" ]; then
    for (( i=0; i<"${#excluded_files[@]:-}"; i++))
    do
        if [ "${excluded_files[i]: -1}" = "/" ]; then
            echo -ne "--exclude=\"""${excluded_files[i]}""*\" "
        else
            echo -ne "--exclude=\"""${excluded_files[i]}""\" "
        fi
    done
else
    for (( i=0; i<"${#default_exclude[@]:-}"; i++))
    do
        if [ "${default_exclude[i]: -1}" = "/" ]; then
            echo -ne "--exclude=\"" "${default_exclude[i]}""*\" "
        else
            echo -ne "--exclude=\"""${default_exclude[i]}""\" "
        fi
    done
fi

}

# creates a tarball using specified parameters $@
function create_tarball { 

# this could be represented as tar --exclude $3 -czpPf $1 $2
# where $1 is the filename, $2 is the directory,
#       $3 is an array of exclude dirs/files

local tarball_name="${1}"
shift
local file_or_dir="${1}"
shift

# preview
echo -ne "Now running the following: " | tee -a "$DIR"/log-file
echo tar \
--create \
--gzip \
--preserve-permissions \
--absolute-names \
$(do_exclude "$@") \
--file="\"""$move"/"$tarball_name""\"" "$file_or_dir" | tee -a "$DIR"/log-file
echo "Started: ""$(date)" >> "$DIR"/log-file 2>&1

# create tarball
eval tar --create --verbose --verbose --gzip --preserve-permissions --absolute-names $(do_exclude "$@") --file="\"""$move"/"$tarball_name""\"" '$file_or_dir' 2>&1 >> "$DIR"/log-file

cat <<EOF | tee -a "$DIR"/log-file
Finished: $(date)

EOF

}

# $to_backup,$backup,$prefix,$chown_or_naw,$chowner 

function show_help {
cat <<EOF
Usage: ${0##*/:-} [OPTION...]
Creates backups for specified files/dirs in \$to_backup, stores in \$backup/\$prefix_\$d, where \$d is the date format

    -t full path to csv of dirs/files to backup (Default: \$DIR/to-backup)
    -b full path to backup directory (Default: /tmp/backup)
    -p specify a prefix for the current backup directory (Default: hostname_)
    -d specify a date format (Default: %Y%m%d%I%M i.e. yyyymmddhhmm)
    -c if set then backup directory with be chowned to user:grp (optionally specified in -o)
    -o specify a chown user:grp (Default: root:root) must use with -c
    -h print this help


EOF

}

while getopts ":t:b:p:d:co:h" opt; do
    case "${opt:-}" in
        t) 
            echo "-t was triggered, Parameter: ""${OPTARG:-}" >&2
            to_backup="${OPTARG:-}"
        ;;

        b) 
            echo "-b was triggered, Parameter: ""${OPTARG:-}" >&2
            backup="${OPTARG:-}"
        ;;

        p) 
            echo "-p was triggered, Parameter: ""${OPTARG:-}" >&2
            prefix="${OPTARG:-}"
        ;;

        d) #todo: fix the fact that this currently accepts invalid date formats
            echo "-d was triggered, Parameter: ""${OPTARG:-}" >&2
            dformat="${OPTARG:-}"
            d="$(date +$dformat)"
        ;;

        c) 
            echo "-c was triggered." >&2
            chown_or_naw="1"
        ;;

        o) 
            echo "-o was triggered, Parameter: ""${OPTARG:-}" >&2
            if [ "$chown_or_naw" -eq "1" ]; then
                chowner="${OPTARG:-}"
            else
                echo "NOTICE: -c must be triggered, if -o owner:grp is specified."
                show_help
                exit 1
            fi
        ;;

        h) 
            show_help
            exit 0
        ;;

        \?) # any other single character
            echo "Invalid option: -""${OPTARG:-}" >&2
            echo
            show_help
            exit 1
        ;;

        :)
            echo "Option -""${OPTARG:-}"" requires an argument." >&2
            echo
            show_help
            exit 1
        ;;
    esac
done

# call the main function; see above
main