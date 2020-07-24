#!/bin/bash
#
# by Samantha LR Capel <scapel2@illinois.edu> <slr.capel2@gmail.com>

# DISCLAIMER: this script was somewhat specific to my data - all of the private alleles in my populations were due to one popultion being biallelic at a locus while all others were monoallelic, so this script DOES NOT WORK WITH FIXED DIFFERENCES among populations

# PRIOR TO RUNNING THIS SCRIPT you will need to run populations TWICE to look at movement of private alleles into a population of interest as follows:
	# First run populations on ALL of your populations with the -p (--min-populations) option set to the total number of populations. Create a whitelist from this run (cat populations.sumstats.tsv | grep -v "#" | cut -f 1,4 | uniq > whitelist.tsv) to feed into the second run of populations; this run will be refered to as "all populations" or "all"
	# Next run populations excluding the population that should be "recieving" the private alleles while employing the whitelist (-W path_to_file) from the first run (don't apply -r or --min_maf filters) - this allows private alleles to be coded correctly by populations.sumstats.tsv; this run will be refered to as "original populations" or "orig"


########################################## INPUTS ##########################################
all=  # instert the path to the directory containing "all" populations.sumstats.tsv file   #
orig=  # instert the path to the directory containing "orig" populations.sumstats.tsv file #
opn=   # inster the number of populations of origin                                        #
popint=""  # inster the name of population of interest as recorded in your population map  #
############################################################################################


#### Filter populations.sumstats.tsv of original populations to only those loci that contain private alleles ####

## covert Locus ID and Col columns into a single column sepparated with '_'##
cd $orig
echo "Converting Locus and Col columns to single Locus_Col column and cutting excess coumns..."
cat populations.sumstats.tsv | cut -f 1,4-21 | sed -E 's/(^[0-9]+)\t([0-9]+.+)/\1_\2/' | sed -E 's/ID\tCol/ID_Col/' > populations.sumstats_orig.Locus_Col.tsv
if (( $(cat populations.sumstats.tsv | wc -l) == $(cat populations.sumstats_orig.Locus_Col.tsv | wc -l) ))
then
    echo "        populations.sumstats_orig.Locus_Col.tsv HAS CORRECT NUMBER OF LINES"
else
    echo "        ERROR: INCORRECT NUMBER OF LINES IN populations.sumstats_orig.Locus_Col.tsv"
    exit
fi
echo " "

top=$(head -n 5 $orig/populations.sumstats_orig.Locus_Col.tsv | tail -n 1)

## create list of loci with private alleles##
echo "Creating list of private allele loci..."
cat populations.sumstats_orig.Locus_Col.tsv | awk '{ if ($18 == 1) {print $1} }' > loci_PA.csv &&
total_PA=$(cat loci_PA.csv | wc -l)
echo "        NUMBER OF LOCI SAMPLED AMONG ORIGIN POPULATIONS CONTAINING PRIVATE ALLELES: $total_PA" &&
echo " "

## return populations.sumstats lines for loci with private alleles
echo "Editing populations.sumstats_orig.Locus_Col.tsv down to loci with private alleles..."
cat loci_PA.csv | while read line
do
    cat populations.sumstats_orig.Locus_Col.tsv | grep -w $line
done > populations.sumstats_orig.PA.tsv
sed -i "1 i $top" populations.sumstats_orig.PA.tsv
if (($(cat populations.sumstats_orig.PA.tsv | wc -l) == $(expr $total_PA \* $opn + 1)))
then
    echo "        CORRECT NUMBER OF LINES IN populations.sumstats_orig.PA.tsv"
else
    echo "        ERROR: INCORRECT NUMBER OF LINES IN populations.sumstats_orig.PA.tsv"
    echo "        	NUMBER OF LINES IN populations.sumstats_orig.PA.tsv: $(cat populations.sumstats_orig.PA.tsv | wc -l)"
    echo "        	NUMBER OF LINES THAT THERE SHOULD BE: $(expr $total_PA \* $opn + 1)"
    exit
fi
echo " "

## check to make sure there's only $opn instances of each locus
echo "Checking that final private allele sumstats file only has $opn instances of each locus..."
lociNE=$(cat populations.sumstats_orig.PA.tsv | cut -f 1 | uniq -c | grep -v -w $opn | wc -l)
if [ $lociNE == 1 ]
then
    echo "        FINAL sumstats FILE CONTAINS CORRECT NUMBER OF INSTANCES OF EACH LOCUS"
else
    echo "        ERROR: FINAL sumstats FILE CONTAINS INCORRECT NUMBER OF INSTANCES OF EACH LOCUS"
    exit
fi
echo " "

## make sure that the most common allele is always the same nucleotide
echo "Checking that the most common allele is always the same nucleotide across populations..."
PNuc_num=`cat populations.sumstats_orig.PA.tsv | cut -f 3 | uniq -c | sed -E 's/([0-9]+)\s+[A-Z]{1}/\1/' | sort -g | uniq | tail -n+2`
for line in $PNuc_num
do
    if (( $line % $opn == 0 ))
    then
	echo "        ALL GOOD -- ALL P Nuc ARE THE SAME ALLELE ACROSS POPULATIONS"
    else
	echo "        ERROR: NOT ALL P Nuc ARE THE SAME ACROSS POPULATIONS"
	exit
    fi
done
echo " "
echo " "


#### Filter populations.sumstats.tsv for all populations down to loci with private alleles among original populations ####
cd $all

## Converting population.sumstats.tsv so that Locus and Col are merged into one
echo "!!!  MOVING TO ALL POPULATIONS RUN  !!!"
echo " "
echo "Converting Locus and Col columns to single Locus_Col column and cutting excess columns..."
cat populations.sumstats.tsv | cut -f 1,4-21 | sed -E 's/(^[0-9]+)\t([0-9]+.+)/\1_\2/' | sed -E 's/ID\tCol/ID_Col/' > populations.sumstats_all.Locus_Col.tsv
if (( $(cat populations.sumstats.tsv | wc -l) == $(cat populations.sumstats_all.Locus_Col.tsv | wc -l) ))
then
    echo "        populations.sumstats_all.Locus_Col.tsv HAS CORRECT NUMBER OF LINES"
else
    echo "        ERROR: populations.sumstats_all.Locus_Col.tsv HAS INCORRECT NUMBER OF LINES"
    exit
fi
echo " "

## Filter down populations.sumstats_all.Locus_Col.tsv to loci containing the private alleles identified in origin populations
echo "Creating refined populations.sumstats of $popint loci containing private alleles from origin populations..."
cat $orig/loci_PA.csv | while read line
do
    cat populations.sumstats_all.Locus_Col.tsv | grep $popint | grep -w $line
done > populations.sumstats_all.PA_$popint.tsv
sed -i "1 i $top" populations.sumstats_all.PA_$popint.tsv
if (( $(cat populations.sumstats_all.PA_$popint.tsv | wc -l) == 0 )) || (( $(cat populations.sumstats_all.PA_$popint.tsv | wc -l) == 1 ))
then
    echo "        ERROR: SOMETHING WRONG WITH CREATING populations.sumstats_all.PA_$popint.tsv"
    exit
fi
echo "        NUMBER OF PRIVATE ALLELE LOCI WITHIN ORIGIN POPULAITONS SAMPLED IN $popint: $(tail -n +2 populations.sumstats_all.PA_$popint.tsv | wc -l)"
echo " "

## Create a final list of loci sampled across all populations containing private alleles among origin populations
echo "Creating list of private allele loci from $popint filtered data..."
cat populations.sumstats_all.PA_$popint.tsv | cut -f 1 | tail -n+2 > loci_PA_$popint.csv &&
if (( $(cat populations.sumstats_all.PA_$popint.tsv | wc -l) - 1 == $(cat loci_PA_$popint.csv | wc -l) ))
then
    echo "        loci_PA_$popint.csv HAS CORRECT NUMBER OF LINES"
else
    echo "        ERROR: SOMETHING WRONG WITH CREATING loci_PA_$popint.csv"
    exit
fi
echo " "
echo " "


#### Find private loci that moved into population of interest #####
cd $orig

echo "!!! MOVING BACK TO ORIGINAL POPULATIONS TO REFILTER AND CHECK P NUC ALLELES !!!"
echo " "
## Refine populations.sumstats_orig to private allele loci sampled in population of interest
echo "Refining original population sumstats loci to those sampled in $popint"
cat $all/loci_PA_$popint.csv | while read line
do
    cat populations.sumstats_orig.PA.tsv | grep -w $line
done > populations.sumstats_all.PA_$popint.sampled.tsv
sed -i "1 i $top" populations.sumstats_all.PA_$popint.sampled.tsv
if (( $(cat populations.sumstats_all.PA_$popint.sampled.tsv | wc -l) == 0 )) || (( $(cat populations.sumstats_all.PA_$popint.sampled.tsv | wc -l) == 1 ))
then
    echo "        ERROR: SOMETHING WRONG WITH CREATING populations.sumstats_all.PA_$popint.sampled.tsv"
    exit
fi
echo " "

## Make sure P Nuc is the same in all populations sumstats and orig populations sumstats
echo "Checking P Nuc is the same in all populations within origin population loci..."
tail -n +2 populations.sumstats_all.PA_$popint.sampled.tsv | cut -f 3 | uniq -c | sed -E 's/\s+([0-9]+).+/\1/' | sort -g | uniq > temp.txt
cat temp.txt | while read line
do
    if (( $line % 4 == 0 ))
    then
	echo "GOOD"
    else
	echo "ERROR: NOT ALL P NUC THE SAME AMONG POPULATIONS WIHTIN LOCI"
	exit
    fi
done

echo "Making sure P Nuc is the same in $popint and origin populations"
pop=$(tail -n +2 populations.sumstats_all.PA_$popint.sampled.tsv | head -n 1 | cut -f 2)
tail -n +2 populations.sumstats_all.PA_$popint.sampled.tsv | grep $pop | cut -f 3 > orig_P_Nuc.csv &&
echo "        total P_Nuc in orig pops: $(cat orig_P_Nuc.csv | wc -l)" &&
tail -n +2 $all/populations.sumstats_all.PA_$popint.tsv | cut -f 3 > $popint.P_Nuc.csv &&
echo "        total P_Nuc in $popint: $(cat $popint.P_Nuc.csv | wc -l)" &&
diff -y $popint.P_Nuc.csv orig_P_Nuc.csv | awk '{ if ($1 == $2) {print "MATCH"} else print "DIFF\t"$0 }' | uniq -c
echo " "

## Make sure instances of private alleles are only from loci that are biallelic
echo "Checking that all private alleles are due to biallelic loci"
echo "    -- ALL NON-PRIVATE SHOULD ONLY HAVE '-' WHILE ALL PRIVATE SHOULD HAVE A NUCLEOTIDE --"
tail -n+2 populations.sumstats_all.PA_$popint.sampled.tsv | awk '{ if ($18 == 1) {print "        Private alleles:"$4} else print "        Non-private:"$4}' | sort -g | uniq -c &&
echo " "
echo " "


echo "!!!!!!!!!!! MOVEMENT OF PRIVATE ALLELES !!!!!!!!!!!"
echo " "

##filter down to just private allele populations
echo "Creating list of just private alleles from original populations -- private_alleles_orig.tsv"
cat populations.sumstats_all.PA_$popint.sampled.tsv | awk '{ if ($18 == 1) {print $0} }' > private_alleles_oirg.tsv &&
sed -i "1 i $top" private_alleles_oirg.tsv
echo "        done"
echo " "

##create list of the distribution of private allele loci sampled across all populations
cat private_alleles_oirg.tsv | cut -f 2 | sort -g | uniq -c | head -n $opn > dist.private.all_sampled.tsv &&
echo "DISTRIBUTION OF PRIVATE ALLELES IN ORIGINAL POPULATIONS:"
cat dist.private.all_sampled.tsv
echo " "

##make comparison file for population of interest and orig population private alleles and tally number of private alleles in population of interest
cat private_alleles_oirg.tsv | cut -f 2,4 > orig.Q_Nuc.tsv &&
cat $all/populations.sumstats_all.PA_$popint.tsv | cut -f 2,4 > $popint_Q_Nuc.tsv &&
paste $popint_Q_Nuc.tsv orig.Q_Nuc.tsv > $popint_Q_Nuc.vs.orig.Q_Nuc.tsv &&
cat $popint_Q_Nuc.vs.orig.Q_Nuc.tsv | awk '{ if ($2 == $4) {print $3} }' | sort -g | uniq -c > dist_PA_into_$popint.tsv
echo "MOVEMENT OF PRIVATE ALLELES INTO $popint:"
cat dist_PA_into_$popint.tsv

# delete temporary files
rm orig.Q_Nuc.tsv
rm $popint_Q_Nuc.tsv
rm $popint_Q_Nuc.vs.orig.Q_Nuc.tsv
rm $orig/populations.sumstats_orig.Locus_Col.tsv
rm $orig/loci_PA.csv
rm $orig/populations.sumstats_orig.PA.tsv
rm $all/populations.sumstats_all.Locus_Col.tsv
rm $all/populations.sumstats_all.PA_$popint.tsv
rm $all/loci_PA_$popint.csv
rm $orig/populations.sumstats_all.PA_$popint.sampled.tsv
rm $orig/temp.txt
rm $orig/orig_P_Nuc.csv
rm $orig/$popint.P_Nuc.csv
rm $orig/private_alleles_oirg.tsv
