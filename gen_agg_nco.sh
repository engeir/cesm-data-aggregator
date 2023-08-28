#!/bin/bash

# If any of the options are not provided, exit with exit status 0 and print a helpful
# message to the user, telling them how they just tried to use it, and how it is
# intended to be used.

# Initialize variables to store option values
OUTPUT=""
EXISTING=""
ATTRS=()
INPUTS=()

# Usage function
usage() {
    echo "Usage: $0 -o <filename> -a <attr1> [-a <attr2> ...] -i <file1> [-i <file2> ...] [-h]"
    echo
    echo "Generate aggregated netCDF files, one for each attribute, from a list of time-stamped input files that all"
    echo "include the provided attributes / variables."
    echo
    echo "The files are save as <ATTR><OUTPUT>.nc or <ATTR>YYYYMMDD.nc if the \`o\` option is not provided"
    echo # We use 80 columns wide help:    # ---------------------------------------------------------------------------- #
    echo "Options:"
    echo "    -h                           Print this help message and exit."
    echo "    -o <filename>                Appended name of the output file. If not provided, this defaults to the date:"
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
    echo "    \$ $0 -o new -a TREFHT -i 1850-01.nc -i 1850-02.nc -i 1850-03.nc -a FLNT"
    echo "    This creates two files, TREFHTnew.nc and FLNTnew.nc, from the three files 1850-01.nc, 1850-02.nc and"
    echo "    1850-03.nc."
    echo
    echo "    \$ $0 -o new2 -a TREFHT -i 1850-11.nc -i 1850-12.nc -i 1851-01.nc -a FLNT -x new"
    echo "    This extends the previous two files, TREFHTnew.nc and FLNTnew.nc, with the attributes from the three files"
    echo "    1850-11.nc, 1850-12.nc and 1851-01.nc."
    echo
    echo "    \$ $0 -o first -a FLNT -a FSNT -i '1850-*' -i '1852-*'"
    echo "    \$ $0 -o second -a FLNT -a FSNT -i '1853-*' -i 1855-07.nc -x first"
    echo "    This will first create two files (FLNTfirst.nc and FSNTfirst.nc) that span 24 months (1850 and 1852), and"
    echo "    then those two will be expanded with the year 1853 and the month 1855/07. The files FLNTfirst.nc and"
    echo "    FSNTfirst.nc will be deleted and we are left with FLNTsecond.nc and FSNTsecond.nc."
    echo
    # Don't care about other than good exit statuses. Non-zero exits are expected to be
    # caused from outside of this script.
    exit 0
}

# Parse options using getopts
while getopts "o:a:i:x:h" opt; do
    case "$opt" in
    o)
        OUTPUT="$OPTARG"
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
for in_file in ${INPUTS[@]}; do
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
SAVEDIR="$(dirname "${INPUTS_EXP[0]}")/"

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$(date '+%Y%m%d')"
fi

# DONE CHECKING THE INPUTS AND STUFF, LETS IMPLEMENT THE PROGRAM --------------------- #

# Loop over attributes
for attr in "${ATTRS[@]}"; do
    # Check if the file exists. If yes, skip to the next, but notify the user.
    if test -f "$SAVEDIR$attr$OUTPUT.nc"; then
        echo "$SAVEDIR$attr$OUTPUT.nc exists."
        continue
    else
        echo "Creating $SAVEDIR$attr$OUTPUT.nc..."
    fi
    if [[ -z "$EXISTING" ]]; then
        # If we create a brand new file.
        ncrcat -4 -o "$SAVEDIR$attr$OUTPUT.nc" -v "$attr" "${INPUTS_EXP[@]}"
    else # -- or --
        # If we create an output file that should be the extension of a previously made
        # file.
        ncrcat -4 -o "$SAVEDIR$attr$OUTPUT.nc" -v "$attr" "${INPUTS_EXP[@]}"
        ncrcat -4 -o "$SAVEDIR"output-combined.nc -v "$attr" "$SAVEDIR$attr$EXISTING.nc" "$SAVEDIR$attr$OUTPUT.nc"
        rm "$SAVEDIR$attr$OUTPUT.nc"
        rm "$SAVEDIR$attr$EXISTING.nc"
        # We save using the OUTPUT variable instead of the older (original) name, since
        # often the date is used, and it makes sense to update this to the current date.
        mv "$SAVEDIR"output-combined.nc "$SAVEDIR$attr$OUTPUT.nc"
    fi
done
