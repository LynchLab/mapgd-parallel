#! /bin/usr/perl -w

$DATA_DIR=$ARGV[0];

if($DATA_DIR eq "")
{
	print "\n\nThe 1nd input (args) is the data directory. Please input the data directory.\n\n"; 
	exit
}

if(!(-e (glob($DATA_DIR))[0]))
{
	print "\nThe 1nd input (args) is the data directory. The data directory is not found:
				$DATA_DIR
	
	"; 
	exit
}

print "\n The data directory is:
				$DATA_DIR
	"; 

$Sample_ID=$ARGV[1]; 

if ($Sample_ID eq "")
{
	print "\n\nPlease input a population/Sample ID (The 2nd args).\n\n"; 
	exit
}

$MaxNumberofSamples=125;
$emailaddress='ouqd@hotmail.com';
$HeaderFile="$DATA_DIR/PA42.header";
$walltime="120:00:00";

# The paths to the software used in this pipeline
# You must first make sure you have all these software installed and they are all functional

#Now we find the mpileup files and produce a batch file for them

open OUT1, ">./mapgd-parallel.pbs" or die "cannot open file: $!";

print OUT1 
"#!/bin/bash 
#PBS -N mapgd-parallel-$Sample_ID
#PBS -k o
#PBS -l nodes=1:ppn=16,walltime=$walltime
#PBS -l vmem=100gb
#PBS -M $emailaddress
#PBS -m abe
#PBS -j oe

# Updated on 05/28/2018
set +x

module rm gcc
module load gcc
module load gsl  
module load samtools

set -x
cd $DATA_DIR
set +x
echo ===============================================================
echo 0. Make a header file
echo ===============================================================
time samtools view -H PA2013-001-RG_Sorted_dedup_realigned_Clipped.bam \> $HeaderFile

echo ===============================================================
echo 1. Make a pro file of nucleotide-read quartets -counts of A, C, G, and T, from each of the mpileup files of the clones.
echo ===============================================================
set -x
date
";

$n=0;
$n1=0;
$n2=0;
while ($n<=$MaxNumberofSamples+1) {
	$n=$n+1;
	$nstr001= sprintf ("%03d", $n-1);
	$OUTPUT="$Sample_ID-$nstr001";
	
	if(-e "$DATA_DIR/$OUTPUT.mpileup"){ 
		$n1=$n1+1;	
		if(-e "$DATA_DIR/$OUTPUT.proview"){
			print "$DATA_DIR/$OUTPUT.proview already exist. if you want to reproduce it, please delete it first.\n"; 
		}
		else
		{		
			$n2=$n2+1;	
			#print ", Okay, a mpileup file is found! lets make a mapgd pro file:$OUTPUT.proview\n"; 
			print "$n1: $OUTPUT.mpileup\n";
			print OUT1 "\n			
time /N/dc2/projects/daphpops/Software/MAPGD-0.4.26/bin/mapgd proview -i $OUTPUT.mpileup -H $HeaderFile > $OUTPUT.proview &\n";	
		}			
	}
}

print OUT1 
"\nwait\n
date
set +x
echo ===============================================================
echo 2. Combine all mapgd proview files into one.
echo ===============================================================
set -x
time java -cp ~/daphnia/DaphniaVariantCall CombineProview $DATA_DIR $Sample_ID
set +x
echo ===============================================================
echo 3. Exclude mtDNA data from the pro file.
echo ===============================================================
echo if mtDNA sequence is not included in the reference genome, skip this step:
echo if mtDNA sequence is included in the reference genome, execute this:
set -x
echo time grep -v '^PA42_mt_genome' $Sample_ID.combined.pro.txt \> Nuc_$Sample_ID.combined.pro.txt
echo mv Nuc_$Sample_ID.combined.Pro.txt $Sample_ID.combined.pro.txt
set +x

echo ===============================================================
echo 4. Run the allele command to estimate allele and genotype frequencies from the pro file.
echo ===============================================================
set -x
time mapgd allele -i $DATA_DIR/$Sample_ID.combined.pro.txt -o $DATA_DIR/$Sample_ID.combined.map -p $DATA_DIR/$Sample_ID.combined.clean
set +x

echo ===============================================================
echo 5. Run the filter command to filter the map file of ML estimates of the parameters.
echo ===============================================================
set -x
time mapgd filter -i $DATA_DIR/$Sample_ID.combined.map.map -p 20 -q 0.05 -Q 0.45 -c 800 -C 2400 -o $DATA_DIR/$Sample_ID.combined_filtered.map
set +x
echo -p: minimum value of the likelihood-ratio test statistic for polymorphism 
echo -q: minimum minor-allele frequency estimate
echo -Q: maximum minor-allele frequency estimate
echo -c: minimum population coverage
echo -C: maximum population coverage
echo ===============================================================
echo 6. Run the genotype command to generate a file of genotype likelihoods
echo ===============================================================
set -x
time mapgd genotype -p $DATA_DIR/$Sample_ID.combined.clean.pro -m $DATA_DIR/$Sample_ID.combined_filtered.map.map > $DATA_DIR/$Sample_ID.combined.genotype
set +x

echo ===============================================================
echo 6-1. Remove the unnecessary header and footer
echo ===============================================================
set -x
time awk \'{if (\$3 != \"MN_FREQ\" && \$3 >= 0.0 && \$3 <= 1.0) print}\' $DATA_DIR/$Sample_ID.combined.genotype \> $DATA_DIR/$Sample_ID.combined_F.genotype
set +x
echo ===============================================================
echo 6-2. Randomly pick a specified number - 200000 of SNPs from the file of genotype likelihoods 
===============================================================

set -x
time /N/dc2/projects/daphpops/Software/MAPGD-0.4.26/extras/sub_sample.py $DATA_DIR/$Sample_ID.combined_F.genotype -N 200000 > $DATA_DIR/$Sample_ID.combined_F_200K.genotype
set +x
echo ===============================================================
echo 6-3. Extract the header from the file of genotype likelihoods
echo ===============================================================
set -x
time head -n -1 $DATA_DIR/$Sample_ID.combined.genotype | awk \'{if (\$3 == NULL || \$1 ~ /^@/) print}\' \> $DATA_DIR/$Sample_ID.combined_header.genotype
set +x
echo ===============================================================
echo 6-4. Extract the footer from the file of genotype likelihoods
echo ===============================================================

set -x
time tail -n 1 $DATA_DIR/$Sample_ID.combined.genotype > $DATA_DIR/$Sample_ID.combined_footer.genotype
set +x
echo ===============================================================
echo 6-5. Add the header and footer to the sub-sample of the file of genotype likelihoods
echo ===============================================================

set -x
time cat $DATA_DIR/$Sample_ID.combined_header.genotype $DATA_DIR/$Sample_ID.combined_F_200K.genotype $DATA_DIR/$Sample_ID.combined_footer.genotype > $DATA_DIR/$Sample_ID.combined_F_200K_wh_wf.genotype

set +x
echo ===============================================================
echo 7. Run the relatedness command
echo ===============================================================

set -x
time mapgd relatedness -i $DATA_DIR/$Sample_ID.combined_F_200K_wh_wf.genotype -o $DATA_DIR/$Sample_ID.combined_F_200K_wh_wf_rel.out

set +x
echo ===============================================================
echo =============Task completed.===================
echo ===============================================================

";	
		
if ($n1>0)
{
print "\n$n1 mpileup file(s) are found in $DATA_DIR.\n\n";
}
else
{
	print "No mpileup file is found in $DATA_DIR.\n\n\n";
}

if ($n2>0)
{
	print "\n$n2 mpileup file(s) have no mapgd proview file(s).\n\n";
	print "
	============================================================
	Type the following command to produce the mapgd proview files: 

	  qsub ./mapgd-parallel.pbs
	============================================================
	
	
	";
}
else
{
	print "All mpileup file(s) already have proview file(s) exist.\n\n\n";
	print "If you want to reproduce proview file(s), please delete it firstly.\n"; 
}

