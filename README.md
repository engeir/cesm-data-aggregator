# CESM data aggregator

<sup>Latest version: v1.0.1</sup> <!-- x-release-please-version -->

## Basic usage

This repo includes two shell scripts that both can be run alone. The
`./do_on_all_atm_dirs.sh` script will use `./gen_agg_nco.sh` internally and can be
called either as

```bash
./do_on_all_atm_dirs.sh
```

if it does not require too much resources, or using the `sbatch` command as

```bash
sbatch ./do_on_all_atm_dirs.sh
```

The script `./gen_agg_nco.sh` has been written to only be run as a standard shell
script (the `-h` flag will print a help message):

```bash
./gen_agg_nco.sh -h
```

## Directory structure

Before running the script `./do_on_all_atm_dirs.sh`, it should be noted that this
expects a specific directory structure, which is what the CESM2 climate model will
generate in its archive directory. The archive directory I have is also hard coded into
the script, and must be adjusted according to the users needs.

The specific directory structure is

```tree
e_BWma1850-control/atm/hist/
e_BWma1850-double-overlap/atm/hist/
e_BWma1850-ens1-2xco2/atm/hist/
e_BWma1850-ens1-medium/atm/hist/
e_BWma1850-ens1-medium-plus/atm/hist/
e_BWma1850-ens1-strong/atm/hist/
...
```

The script will by default look for files in all such directories, using

```bash
DIRS=$(ls -d ./*/atm/hist)
```

## Dependencies

The only dependency is [`ncrcat`](https://nco.sourceforge.net/nco.html#ncrcat). If one
wish to run the script using `sbatch`, typically on a HPC cluster, then this must of
course also be available.
