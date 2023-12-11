#!/bin/bash

# If no options are not provided, exit with exit status 0 and print a helpful message to
# the user, telling them how they just tried to use it, and how it is intended to be
# used.

# Initialize variables to store option values
OUTPUT=""
UNIQUE=""
EXISTING=""
ATTRS=()
INPUTS=()

# Usage function
usage() {
    echo "Usage: $0 -o <filename> -u <unique> -a <attr1> [-a <attr2> ...] -i <file1> [-i <file2> ...] [-h]"
    echo
    echo "Generate aggregated netCDF files, one for each attribute, from a list of time-stamped input files that all"
    echo "include the provided attributes / variables."
    echo
    echo "The files are save as <filename><unique>.nc or <filename>YYYYMMDD.nc if the \`o\` option is not provided"
    echo # We use 80 columns wide help:    # ---------------------------------------------------------------------------- #
    echo "Options:"
    echo "    -h                           Print this help message and exit."
    echo "    -o <filename>                The name of the output file. If not provided, the attribute name is provided."
    echo "                                 If the string 'attr' is part of the filename, the attribute name will be"
    echo "                                 replace this."
    echo "    -u <unique>                  Appended name of the output file. If not provided, this defaults to the date:"
    echo "                                 YYYYMMDD."
    echo "    -a <attr1> [-a <attr2> ...]  Name of the variable / attribute in the input files that should be saved."
    echo "    -i <file1> [-i <file2> ...]  Input files to concatenate. You may use the asterisk, \`*\`, for files that"
    echo "                                 should be expanded."
    echo "    -x <attr-file>               A previously made file of the same type as the output file that should be"
    echo "                                 extended. IT IS EXPECTED THAT THE FILE WAS CREATED BY THIS SCRIPT, therefore,"
    echo "                                 specify ONLY what would have been the \`-o\` value for its initial creation."
    echo "                                 See the examples below."
    echo
    echo "Examples:"
    echo "    \$ $0 -o attr-hello -a TREFHT -i 1850-01.nc -i 1850-02.nc -i 1850-03.nc -a FLNT"
    echo "    This creates two files, TREFHT-hello20231208.nc and FLNT-hello20231208.nc (20231208 is today's date), from"
    echo "    the three files 1850-01.nc, 1850-02.nc and 1850-03.nc."
    echo
    echo "    \$ $0 -u new -a TREFHT -i 1850-01.nc -i 1850-02.nc -i 1850-03.nc -a FLNT"
    echo "    This creates two files, TREFHTnew.nc and FLNTnew.nc, from the three files 1850-01.nc, 1850-02.nc and"
    echo "    1850-03.nc."
    echo
    echo "    \$ $0 -u new2 -a TREFHT -i 1850-11.nc -i 1850-12.nc -i 1851-01.nc -a FLNT -x new"
    echo "    This extends the previous two files, TREFHTnew.nc and FLNTnew.nc, with the attributes from the three files"
    echo "    1850-11.nc, 1850-12.nc and 1851-01.nc."
    echo
    echo "    \$ $0 -u first -a FLNT -a FSNT -i '1850-*' -i '1852-*'"
    echo "    \$ $0 -u second -a FLNT -a FSNT -i '1853-*' -i 1855-07.nc -x first"
    echo "    This will first create two files (FLNTfirst.nc and FSNTfirst.nc) that span 24 months (1850 and 1852), and"
    echo "    then those two will be expanded with the year 1853 and the month 1855/07. The files FLNTfirst.nc and"
    echo "    FSNTfirst.nc will be deleted and we are left with FLNTsecond.nc and FSNTsecond.nc."
    echo
    # Don't care about other than good exit statuses. Non-zero exits are expected to be
    # caused from outside of this script.
    exit 0
}

# Parse options using getopts
while getopts "o:u:a:i:x:h" opt; do
    case "$opt" in
    o)
        OUTPUT="$OPTARG"
        ;;
    u)
        UNIQUE="$OPTARG"
        ;;
    x)
        EXISTING="$OPTARG"
        ;;
    a)
        ATTRS+=("$OPTARG")
        ;;
    i)
        INPUTS+=("$OPTARG")
        ;;
    h)
        usage
        ;;
    *)
        usage
        ;;
    esac
done

# Check if the necessary CLI exist:
if ! command -v ncrcat &>/dev/null; then
    echo "The command \`ncrcat\` must be available."
    exit 0
fi

# Check if mandatory options are provided
if [[ -z "${ATTRS[0]}" || "${#INPUTS[@]}" -eq 0 ]]; then
    echo "You tried to run the script without providing all required options. \`-a\` and \`-i\` must be given."
    echo
    usage
fi

# Expand inputs if asterisk is given
for in_file in "${INPUTS[@]}"; do
    shopt -s nullglob
    INPUTS_EXP+=($in_file)
    shopt -u nullglob
done

# Function to check if all files are in the same directory
are_files_in_same_directory() {
    local first_dir
    first_dir="$(dirname "$1")"
    for file in "${INPUTS_EXP[@]}"; do
        if [ "$(dirname "$file")" != "$first_dir" ]; then
            return 1
        fi
    done
    return 0
}

# Check if all files are in the same directory
if ! are_files_in_same_directory "${INPUTS_EXP[0]}"; then
    echo "Error: Files in the \`-i\` option are not in the same directory."
    exit 0
fi

# If the asterisk syntax is used, but the files do not exist (no match), we are left
# with an empty INPUTS_EXP variable, so we check if it is empty again
if [[ "${#INPUTS_EXP[@]}" -eq 0 ]]; then
    echo "Error: No files matching the input files provided with the \`-i\` option could be found."
    exit 0
fi
for found_files in "${INPUTS_EXP[@]}"; do
    if [[ ! -f "$found_files" ]]; then
        echo "Error: I cannot find the file $found_files"
        exit 0
    fi
done

SAVEDIR="$(dirname "${INPUTS_EXP[0]}")/"

if [[ -z "$UNIQUE" ]]; then
    UNIQUE="$(date '+%Y%m%d')"
fi

# DONE CHECKING THE INPUTS AND STUFF, LETS IMPLEMENT THE PROGRAM --------------------- #

# Function that checks if the input files and the existing file (specified with the -x
# option) have overlapping time ranges.
# INFO: Upon a restart, the end file is re-generated, thus there will always be overlap.
# Setting the fourth argument to "silent" will make it exit with an error (1), but
# without printing the error message.
check_time_ranges() {
    # Last time of first file
    last_time_1=$(ncdump "$1" -i -v time | sed -e '1,/data:/d' -e '$d' | tail -1 | awk '{print $(NF-1)}' | tr -d '",')
    last_time_1_2=$(ncdump "$1" -i -v time | sed -e '1,/data:/d' -e '$d' | sed 2q | tail -1 | awk '{print $3}' | tr -d '",')
    last_time_2=$(ncdump "$2" -i -v time | sed -e '1,/data:/d' -e '$d' | sed 2q | tail -1 | awk '{print $3}' | tr -d '",')
    last_time_3=$(ncdump "$3" -i -v time | sed -e '1,/data:/d' -e '$d' | tail -1 | awk '{print $(NF-1)}' | tr -d '",')
    last_time_1_float="$(date -d "$last_time_1" +%s)"
    last_time_2_float="$(date -d "$last_time_2" +%s)"
    if [[ "$last_time_1_float" -ge "$last_time_2_float" ]]; then
        if [[ "$4" == "silent" ]]; then
            return 1
        else
            echo "$(date '+%Y%m%d-%H:%M:%S') |"
            echo "    Error: The file you want to extend with the \`-x\` option has end time sooner"
            echo "    than the earliest time of the input files; THEY MIGHT OVERLAP. Make sure the"
            echo "    input files are given in the correct order, and fix the issue manually."
            echo "    * Last time of $1: $last_time_1 (first time: $last_time_1_2)"
            echo "    * First time of inputs ($2): $last_time_2"
            echo "    * Last time of inputs ($3): $last_time_3"
            return 1
        fi
    else
        return 0
    fi
}

# Loop over attributes
for attr in "${ATTRS[@]}"; do
    # Create file name based on OUTPUT and UNIQUE.
    if [[ -z "$OUTPUT" ]]; then
        filename="$attr"
    elif [[ "$OUTPUT" == *"attr"* ]]; then
        filename="${OUTPUT//attr/$attr}"
    else
        filename="$OUTPUT"
    fi
    # Check if the file exists. If yes, skip to the next, but notify the user.
    if test -f "$SAVEDIR$filename$UNIQUE.nc"; then
        echo "$(date '+%Y%m%d-%H:%M:%S') $SAVEDIR$filename$UNIQUE.nc exists."
        continue
    else
        echo "$(date '+%Y%m%d-%H:%M:%S') Creating $SAVEDIR$filename$UNIQUE.nc..."
    fi
    if [[ "$EXISTING" == "latest" ]]; then
        # We check if there is only one file with the same name available. If this is
        # the case, we know this is the file we should expand.
        out=$(find . -wholename "$SAVEDIR$filename*" | wc -l)
        if [[ "$out" -eq 0 ]];then
            EXISTING_loop=""
        elif [[ "$out" -eq 1 ]]; then
            string=$(find . -wholename "$SAVEDIR$filename*")
            prefix="$SAVEDIR$filename"
            suffix=".nc"
            EXISTING_loop=${string#"$prefix"}
            EXISTING_loop=${EXISTING_loop%"$suffix"}
            echo "$(date '+%Y%m%d-%H:%M:%S') Found $SAVEDIR$filename$EXISTING_loop.nc that can be extended."
        else
            echo "$(date '+%Y%m%d-%H:%M:%S') Too many existing files named $SAVEDIR$filename. Skipping $SAVEDIR$filename$UNIQUE.nc."
            continue
        fi
        # break
    elif [[ -n "$EXISTING" ]] && [[ ! -f "$SAVEDIR$filename$EXISTING.nc" ]]; then
        # Let us make sure the existing file, the file we want to extend, actually
        # exists.
        echo "$(date '+%Y%m%d-%H:%M:%S') |"
        echo "    The file $SAVEDIR$filename$EXISTING.nc does not exist, so I cannot expand"
        echo "    it. Instead, I am creating $SAVEDIR$filename$UNIQUE.nc."
        EXISTING_loop=""
    else
        EXISTING_loop="$EXISTING"
    fi
    if [[ -z "$EXISTING_loop" ]]; then
        # If we create a brand new file.
        ncrcat -4 -o "$SAVEDIR$filename$UNIQUE.nc" -v "$attr" "${INPUTS_EXP[@]}"
    else # -- or --
        # If we create an output file that should be the extension of a previously made
        # file.
        # Let us first check if the input files and original files have a time overlap.
        # We check this twice, since upon a restart, CESM2 creates the last file over
        # again, which (I think) we do not need.
        if ! check_time_ranges "$SAVEDIR$filename$EXISTING_loop.nc" "${INPUTS_EXP[0]}" "${INPUTS_EXP[-1]}" "silent"; then
            if ! check_time_ranges "$SAVEDIR$filename$EXISTING_loop.nc" "${INPUTS_EXP[1]}" "${INPUTS_EXP[-1]}" "loud"; then
                continue
            else
                INPUTS_EXP=("${INPUTS_EXP[@]:1}") #removed the 1st element
            fi
        fi
        ncrcat -4 -o "$SAVEDIR$filename$UNIQUE.nc" -v "$attr" "${INPUTS_EXP[@]}"
        ncrcat -4 -o "$SAVEDIR"output-combined.nc -v "$attr" "$SAVEDIR$filename$EXISTING_loop.nc" "$SAVEDIR$filename$UNIQUE.nc"
        rm "$SAVEDIR$filename$UNIQUE.nc"
        # Instead of deleting old data, we rename them with the "-extended" suffix.
        mv "$SAVEDIR$filename$EXISTING_loop.nc" "$SAVEDIR$filename$EXISTING_loop-extended.nc"
        # We save using the OUTPUT variable instead of the older (original) name, since
        # often the date is used, and it makes sense to update this to the current date.
        mv "$SAVEDIR"output-combined.nc "$SAVEDIR$filename$UNIQUE.nc"
    fi
done
