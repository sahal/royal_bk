#!/bin/bash
# ./trimbackups.sh [prompt]
# desc: Use this for trimming backup directories stored as $prefix_yyyymmdd[hhmm] in $backup dir
# todo: 
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

# directory where script is located
DIR="$( cd "$( dirname "$0" )" && pwd )"

source "$DIR"/config/config.cfg

function main {

# overwrite todelete each time this is run for [insert reason here]
echo > "$to_delete"

if [ ! -d "$backup" ]; then
    echo "NOTICE: $backup does not exist as a directory."
fi

do_update_vars

do_print_mark

do_write_or_prompt

}

function do_write_or_prompt {

if [ "$prompt_or_naw" -eq "1" ]; then

    # print hr
    echo "*************************************************************"

    for (( i=0; i<"${#dirnames[@]:-}"; i++))
    do
        do_chknprint_dirname "${dirnames[i]:-}"
        ask_delete "${dirnames[i]:-}"
    done

elif [ "$prompt_or_naw" -eq "0" ]; then
    # check each item in array $deletelist to see if it exists in file $todelete
    # if not, add it to the file
    for (( i=0; i<"${#deletelist[@]:-}"; i++))
    do

        grep "${deletelist[i]:-}" "$to_delete" > /dev/null 2>&1
        if [ "$?" -eq "0" ]; then
            continue
        fi

        echo "${deletelist[i]:-}" >> "$to_delete" 2>&1

    done
fi
}

function ask_delete { # this is used by the prompt function below
echo " -- delete?"
select yn in "Yes" "No"; do
case "$yn" in
    Yes ) echo "$1" >> "$to_delete"; break;;
    No ) break;;
esac
done
}

function do_chknprint_dirname {

#checks if the date is already listed in $to_delete, if so skips it
grep "${1:-}" "$to_delete" > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
    continue
fi

# print the date in a pretty format
# i've selected Mmm dd, yyyy [hh:mm] b/c 'MERICA
year="${1:$offset:4}"
month="${1:$offset+4:2}"
day="${1:$offset+6:2}"
week="$(date --date=$year$month$day +%U)"

echo -ne "${1:-}"":  "
echo -ne "${months["$month"]}"" ""$day"", ""$year"

# check if there are 8 or 12 digits after prefix (hour+minute was set)
date_length=$(( ${#1} - $offset ))
if [ "$date_length" = "12" ]; then
    hour="${1:$offset+8:2}"
    minute="${1:$offset+10:2}"
    echo -ne " ""$hour"":""$minute"
fi

}

function do_print_mark {
# print a list of directories in human readable format
# If a directory is followed by a mark (e.g., *, **, ., x) then it is marked for deletion.
#    older than 365 days (with an ?x?)
#    from the current month
#        and from current week
#            but not the most recent daily backup (?*?)
#        and from the current week
#            but not the most recent backup for that week (?.?)
#    not from the current month
#        but not the most recent backup for that month (?**?)

for (( i=0; i<"${#dirnames[@]:-}"; i++))
do

    do_chknprint_dirname "${dirnames[i]:-}"

    daysago="$((( $(date +%s) - $(date -d $year$month$day +%s) ) / 86400 ))"
    if [ "$daysago" -gt "365" ]; then
        echo " x"
        deletelist+=("${dirnames[i]:-}")
        continue
    fi

    if [ "$i" -ne "0" ]; then

        lyear="${dirnames[i-1]:$offset:4}"
        lmonth="${dirnames[i-1]:$offset+4:2}"
        lday="${dirnames[i-1]:$offset+6:2}"
        lweek="$(date --date=$lyear$lmonth$lday +%U)"

        # if month is equal to the month before it, then it's interesting
        if [ "$lmonth" -eq "$month" ]; then

            # if month is equal to the current month
            if [ "$month" -eq "$cmonth" ]; then

                # if week is equal to the week before it, then it's interesting
                if [ "$lweek" -eq "$week" ]; then

                    # if week is equal to the current week
                    if [ "$cweek" -eq "$week" ]; then

                        if [ "$lday" -eq "$day" ]; then
                            echo " *"
                            deletelist+=("${dirnames[i]:-}")
                        else
                            echo
                        fi

                    else
                        echo " ."
                        deletelist+=("${dirnames[i]:-}")
                    fi
                else
                    echo #"weeks do not match."
                fi
            else
                echo " **"
                deletelist+=("${dirnames[i]:-}")
            fi

        else
            echo
        fi

    else
        echo
    fi
done

}

function show_help {
cat <<EOF
Usage: ${0##*/:-} [OPTION...]
Prints a list of directories with \$prefix in \$backup that should be deleted based on rotation schedule.

    -e full path to file that stores a list of directories to delete (Default: \$DIR/config/to-delete)
    -b full path to backup directory (Default: /tmp/backup/)
    -p specify a prefix for the current backup directory (Default: hostname_)
    -a ask (or prompt) to append \$to_delete
    -h print this help


EOF

}

while getopts ":e:b:p:d:ah" opt; do
    case "${opt:-}" in
        e)
            echo "-e was triggered, Parameter: ""${OPTARG:-}" >&2
            to_delete="${OPTARG:-}"
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

        a) 
            echo "-a was triggered" >&2
            prompt_or_naw="1"
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

main