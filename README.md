# Private Allele Tracker


This script was designed to detect private alleles among a group of "populations of origin" and their movement and/or persistence in a population of interest.  Tracking movement and persistence of private alleles is a conservative but precise way to track gene flow into a population of interest over time as well as detect persistence of unique, local variation following introgression.  **This script works exclusively with Stacks v2.0 and later (Rochette et al. 2019) output files.**

![schmatic](https://github.com/slcapel/chapter-1-publication-scripts/blob/master/Private%20Allele%20Population%20Schematic.png?raw=true)

This script works by gradually filtering down loci to those sampled across all populations considered containing private alleles among the populations of origin.  The final products of this script are (1) a distribution of the number of private alleles among populations of origin and (2) a distribution of how many of those private alleles are found in the population of origin.

![schmatic](https://github.com/slcapel/chapter-1-publication-scripts/blob/master/Private%20Allele%20SNP%20Filtering%20Schematic.png?raw=true)

## DISCLAIMERS: 
This script was designed with data that <ins>did not contain fixed differences</ins> among populations, rather private alleles occurred when a single population of origin was biallelic at a given locus while all other populations were monoallelic.

I highly recommend working on a server with multiple cores as this script may be inefficient working on a desktop CPU.

## Requirements
* Linux-based environment with bash-5.0 or later
* Stacks v2.0 or later (works with both de_novo.pl and ref_map.pl)

## Instructions
**Prior to running this script** you will need to run the _populations_ program of Stacks **twice** to detect private alleles within the population of interest as follows:
* First run populations on ALL of your populations (i.e. populations of origin and population of interest) with the `-p` (`--min-populations`) option set to the total number of populations. Create a <ins>whitelist</ins> from this run (`tail -n +7 populations.sumstats.tsv | cut -f 1,4 | uniq > whitelist.tsv`) to feed into the second run of populations; this run will be referred to as **"all populations"** or **"all"** within the script code
* Next run _populations_ on just your populations of origin (i.e. excluding the population of interest) while employing the whitelist (`-W /path/to/file`) from the first _populations_ run (**do not** apply the `-r` filter but **do** apply the `--min_maf` filter) - this allows private alleles to be coded correctly by populations.sumstats.tsv; this run will be referred to as **"original populations"** or **"orig"** within the script code

Once you have completed both runs of _populations_ the script requires manual input of directory paths and other information specific to your data within the "INPUTS" box located near the top of the script:
* Following `all=` input the path to the **directory** containing the populations.sumstats.tsv file produced running _populations_ on all of your populations
* Following `orig=` input the path to the **directory** containing the populations.sumstats.tsv file produced running _populations_ on only your populations of origin
* Following `opn=` input an integer reporting the number of populations of origin in your dataset
* Within the quotations following `popint=` insert the name of your population of interest as recorded in the population map you utilized

After you have completed all the required inputs simply run the script from your command line `./population_private_alleles.sh`.  The script will output text on the command line indicating current steps, any errors that may have occurred, and results of the analysis. There are comments throughout the script indicating what each section is executing.

## Output files:
* `dist.private.all_sampled.tsv`: the distribution of private alleles among populations of origin
* `dist_PA_into_$popint.tsv`: the distribution of private alleles from each population of origin detected in the population of interest where `$popint` is the string designated to the population of origin
* The script removes all intermediate/temporary files at the very end.  If you wish to keep any of these files simply delete the corresponding `rm` command(s)
