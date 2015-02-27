#!/bin/bash
# ./royal_bk.sh
# by Sahal Ansari (github@sahal.info)
#
# desc: create tarballs of files/dirs listed in $to_backup at current
#       date $d and store in directory "$backup""$prefix""$d"
# todo: * support adding optional tar parameters
#       * add support for gpg
#       * add support for other archive formats
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

source "$DIR"/config/config.cfg

function main {
# print the run line to log
echo "Run Line: ""${0##*/:-}" $@ >> "$log_file" 2>&1

do_update_vars

#create "$backup""$prefix""$d" directory and change into it
mkdir -p "$backup""$prefix""$d"
cd "$backup""$prefix""$d"

files_to_backup=( $(grep -v "^#" < "$to_backup" ) )

for each_line in "${files_to_backup[@]}"
do
    # split each line -- at ; -- into paramaters
    # feed that to create_tarball function
    IFS=';' read -a create_tarball_parameters <<< "$each_line"
    create_tarball "${create_tarball_parameters[@]}"
done

if [ "$chown_or_naw" -eq "1" ]; then
    chown -R "$chowner" "$backup""$prefix""$d"
    chmod og= "$backup""$prefix""$d"
fi
}

# excludes directories specified in parameters $@
function do_exclude {

local excluded_files=( "${@}" )

# exclude BOTH from the excluded_files array AND the default_exclude array
for (( i=0; i<"${#excluded_files[@]:-}"; i++))
do
    if [ "${excluded_files[i]: -1}" = "/" ]; then
        echo -ne "--exclude=\"""${excluded_files[i]}""*\" "
    else
        echo -ne "--exclude=\"""${excluded_files[i]}""\" "
    fi
done

for (( i=0; i<"${#default_exclude[@]:-}"; i++))
do
    if [ "${default_exclude[i]: -1}" = "/" ]; then
        echo -ne "--exclude=\"""${default_exclude[i]}""*\" "
    else
        echo -ne "--exclude=\"""${default_exclude[i]}""\" "
    fi
done

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
echo -ne "Now running the following: " | tee -a "$log_file"
echo tar \
--create \
--gzip \
--preserve-permissions \
--absolute-names \
$(do_exclude "$@") \
--file="\"""$backup""$prefix""$d"/"$tarball_name""\"" "$file_or_dir" | tee -a "$log_file"
echo "Started: ""$(date)" >> "$log_file" 2>&1

# create tarball
eval tar --create --verbose --verbose --gzip --preserve-permissions --absolute-names $(do_exclude "$@") --file="\"""$backup""$prefix""$d"/"$tarball_name""\"" '$file_or_dir' 2>&1 >> "$log_file"

cat <<EOF | tee -a "$log_file"
Finished: $(date)

EOF

}

# $to_backup,$backup,$prefix,$chown_or_naw,$chowner 

function show_help {
cat <<EOF
Usage: ${0##*/:-} [OPTION...]
Creates backups for specified files/dirs in \$to_backup, stores in \$backup/\$prefix_\$d, where \$d is the date format

    -t full path to csv of dirs/files to backup (Default: \$DIR/config/to-backup)
    -b full path to backup directory (Default: /tmp/backup/)
    -p specify a prefix for the current backup directory (Default: hostname_)
    -d specify a date format (Default: hhmm) 
                             hhmm=%Y%m%d%I%M i.e. yyyymmddhhmm
                             ymd=%Y%m%d i.e. yyyymmdd
    -c if set then backup directory with be chowned to user:grp (optionally specified in -o)
    -o specify a chown user:grp (Default: root:root) must use with -c
    -h print this help


EOF

}

while getopts ":t:b:p:d:co:h" opt; do
    case "${opt:-}" in
        t) 
            echo "-t was triggered, Parameter: ""${OPTARG:-}" >&2
            if [ -e "${OPTARG:-}" ]; then
                to_backup="${OPTARG:-}"
            else
                echo "ERROR: $to_backup does not exist!"
                exit 1
            fi
        ;;

        b) 
            echo "-b was triggered, Parameter: ""${OPTARG:-}" >&2
            if [ "${OPTARG: -1}" != "/" ]; then
                echo "ERROR: Please specify a directory with a trailing slash!"
                exit 1
            else 
                backup="${OPTARG:-}"
            fi
        ;;

        p) 
            echo "-p was triggered, Parameter: ""${OPTARG:-}" >&2
            prefix="${OPTARG:-}"
        ;;

        d) 
            echo "-d was triggered, Parameter: ""${OPTARG:-}" >&2
            if [ "${OPTARG:-}" == "ymd" ]; then
                d="$(date +%Y%m%d)"
            elif [ "${OPTARG:-}" == "hhmm" ]; then
                d="$(date +%Y%m%d%I%M)"
            else
                echo "ERROR: invalid date format."
                exit 1
            fi
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
