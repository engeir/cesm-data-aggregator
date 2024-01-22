#!/bin/bash

# Job name:
#SBATCH --job-name=variable-archive-script
#
# Project:
#SBATCH --account=nn9817k
#
# Wall time limit:
#SBATCH --time=00-01:50:00
#
# Other parameters:
#SBATCH --qos=short
# comment out SBATCH --mem=100G
#SBATCH --nodes=1

# Run as sbatch ./do_on_all_atm_dirs.sh
# srun --nodes=1 --time=00:55:00 --partition=bigmem --mem=10G --account=nn9817k --pty bash -i

# set -o errexit # Exit the script on any error
set -o nounset # Treat any unset variables as an error

# Load modules
module --quiet purge # Reset the modules to the system default
module load NCO/5.1.3-iimpi-2022a

HERE="$PWD"
# Go to where we want to be (this script could be run from anywhere)
cd /cluster/projects/nn9817k/cesm/archive/ || exit 1
# Select all:
DIRS=$(ls -d ./*/atm/hist)
# Or define a custom set of dirs (but this is more easily done inside the loop, in the
# "case" statement):
# DIRS="one\ntwo"
VAR=(-a TREFHT -a AODVISstdn -a FLNT -a FSNT -a TMSO2 -a ICEFRAC -a TMso4_a1 -a TMso4_a2 -a TMso4_a3 -a TROP_P -a SST -a OH -a U)
FREQ="h0"
# Relevant variables for h0:
#   -a TREFHT -a AODVISstdn -a FLNT -a FSNT -a TMSO2 -a ICEFRAC -a TMso4_a1 -a TMso4_a2 -a TMso4_a3 -a TROP_P -a SST -a OH -a U
# Relevant variables for h1:
#   -a TREFHT -a AODVISstdn -a FLNT -a FSNT -a TMSO2 -a ICEFRAC -a TMso4_a1 -a TMso4_a2 -a TMso4_a3 -a TROP_P -a SST

OUTPUT="attr-$FREQ-"
# Loop over all simulation directories.
for p in $DIRS; do
    tmpdir="$p"
    # Find the leftmost directory name, but avoid "." and "/".
    while [ "$(dirname "$tmpdir")" != "." ] && [ "$(dirname "$tmpdir")" != "/" ]; do
        tmpdir="$(dirname "$tmpdir")"
    done

    # A "case" statement makes it easy to add any directory that we want to use. If we
    # want to use all directories, comment out the "*)" case as well (or remove the
    # `continue` statement), which matches everything.
    case "$tmpdir" in
        ./e_BASELINE)
            # We don't want to work on the `e_BASELINE` simulation. It's too long.
            continue
            ;;
        *fSST1850-ens5*)
            # Let us say we only want to include some simulation we just completed, for
            # example all simulations run with the fSST1850 "compset":
            ;;
        *BWma1850-ens1-medium-plus)
            continue
            ;;
        *BWma1850-ens*-medium-plus) ;;

        *)
            continue
            ;;
    esac

    if [[ ! $# -eq 0 ]] && [[ $1 == "test" ]]; then
        echo "$tmpdir"
        continue
    fi
    # Step in, do work, then step out.
    # The gen_agg_nco.sh script should be able to take a bunch of files, combine them
    # and create a single `.nc` file for one or more of the variables. It should be
    # saved as `<VAR_NAME>YYYYMMDD.nc`. Since the frequency is also very relevant, we
    # save it as well, and instead specify the date ourselves (above).
    cd "$p" || exit 1
    echo "Moving into $PWD"
    echo "$HERE"/gen_agg_nco.sh "${VAR[@]}" -i \""$tmpdir"*cam."$FREQ"*\" -o "$OUTPUT" -x "latest"
    "$HERE"/gen_agg_nco.sh "${VAR[@]}" -i "$tmpdir*cam.$FREQ*" -o "$OUTPUT" -x "latest"
    cd - 1>/dev/null || exit 1 && echo "Going back to $PWD"
    echo ""
done
