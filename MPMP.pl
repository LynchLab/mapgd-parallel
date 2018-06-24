#! /N/soft/rhel7/perl/gnu/5.24.1/bin/perl -w
=pod
======================================================================
 This parallel mapgd pipeline finds all mpileup files in <DATA_DIR>, produces mapgd proview files in parallel, then combines all mapgd proview files into one using a java program (CombineProview.java), and then does the rest of the mapgd pipeline for population genetics computation.

		Usage: perl MPMP.pl <DATA_DIR> <Output>	

=====================================================================
Written by:                   
Xiaolong Wang
email: ouqd@hotmail.com
website: http://www.DNAplusPro.com
=====================================================================
In hope useful in genomics and bioinformatics studies.
This software is released under GNU/GPL license
Copyright (c) 2018 to:
1. Lynch Lab, CME, Biodesign, Arizona State University
2. Lab of Molecular and Computational Biology, Ocean University of China,
=====================================================================
=cut
	print "
 This parallel mapgd pipeline finds all mpileup files in <DATA_DIR>, produces mapgd proview files in parallel, then combines all mapgd proview files into one using a java program (CombineProview.java), and then does the rest of the mapgd pipeline for population genetics computation.
		
	Usage: perl MPMP.pl <DATA_DIR> <Output>	"; 
use warnings;
use strict;

if(@ARGV < 2)
{
	print "\n\n\t\tPlease input the <data directory> and <output file name>.\n\n"; 
	exit
}
my $DATA_DIR=trim($ARGV[0]);

if($DATA_DIR eq "")
{
	print "\n\n Please input the data directory and output file name.\n\n"; 
	exit
}


if(!(-e (glob($DATA_DIR))[0]))
{
	print "
	
	The 1nd input (args) is the data directory, but it is not found:
				$DATA_DIR
	
	"; 
	exit
}

print "\n The data directory is:
				$DATA_DIR
	"; 

my $emailaddress='ouqd@hotmail.com';
my $HeaderFile="$DATA_DIR/PA42.header";
my $walltime="120:00:00";
	
my $Sample_ID=trim($ARGV[1]); 

if ( $Sample_ID eq "")
{
	print "

	Please input a population/Sample ID (The 2nd args), which will be used as the names of the output files.
	
	"; 
	exit
}

print "Population/Sample_ID is: $Sample_ID\n\n";

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

my $n=0;
my $n1=0;
my $n2=0;

my $file;
my @dir;
my $OUTPUT=" ";

opendir (DIR, $DATA_DIR) or die "can't open the directory!";
@dir = readdir DIR;
foreach $file (@dir) 
{
	my $str_len = length($file);
	my $last_dot=rindex($file,".");
	$OUTPUT=substr $file, 0, $last_dot;
	my $extension=substr $file, $last_dot, $str_len-$last_dot;	
	#print $OUTPUT." ".$extension."\n ";
	if ( $extension eq ".mpileup") {
		$n1=$n1+1;	
		
		print "\n$n1: $file --> $OUTPUT.proview";
		
		if(-e "$DATA_DIR/$OUTPUT.proview")
		{
			print ": already exist.\n "; 
		}
		else
		{		
			$n2=$n2+1;	
			print ": will produce.\n "; 
			print OUT1 "
			
time /N/dc2/projects/daphpops/Software/MAPGD-0.4.26/bin/mapgd proview -i $file -H $HeaderFile > $OUTPUT.proview &
";	
		}			
	}
	else 
	{
		#print "$file: Not a mpileup file!\n";
	}
}

print OUT1 
"
wait

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
	print "\n\n$n1 mpileup file(s) are found in $DATA_DIR.\n\n";
}
else
{
	print "\n\nNo mpileup file is found in the data directory:
		$DATA_DIR
	the mpileup files must be named as:
	$Sample_ID-001.mpileup 
	$Sample_ID-002.mpileup 
	
		......
	
	$Sample_ID-100.mpileup 
	";
	
	exit;
}

if ($n2>0)
{
	print "
	
	$n2 of the mpileup file(s) have no mapgd proview file(s).
	
	Submit the following pbs to run mapgd pipeline in parallel: 
	============================================================

		qsub ./mapgd-parallel.pbs
	
	============================================================
	
	
	";
}
else
{
	print "
	
	All mpileup file(s) already have proview file(s) exist.
	
	If you want to reproduce proview file(s), please delete it firstly.
	
	"; 
}

print "Population/Sample_ID is: $Sample_ID, will be used as the names of the output files.\n\n";

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };