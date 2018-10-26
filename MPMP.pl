#! /N/soft/rhel7/perl/gnu/5.24.1/bin/perl -w

use warnings;
use strict;
#Specify the path to mapgd_parallel

print "
 This parallel mapgd pipeline finds all mpileup files in <DATA_DIR>, produces mapgd proview files in parallel, then combines all mapgd proview files into one using a java program (CombineProview.java), and then does the rest of the mapgd pipeline for population genetics computation.
		
	Usage: perl MPMP.pl <DATA_DIR> <Output>	"; 
my $n=0;
my $n_mpileup=0;
my $n_proview_not_exist=0;
my $n_proview_all=0;
my $n_proview_exist=0;
my $mapgd_parallel="~/daphnia/mapgd-parallel/";
my $file;
my @dir;
my $OUTPUT=" ";
	
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

my $str_len = length($DATA_DIR);
my $last_slash=rindex($DATA_DIR,"/");

if ($last_slash==$str_len-1)
{
	$DATA_DIR=substr $DATA_DIR, 0, $str_len-1;
}
$str_len = length($DATA_DIR);
$last_slash=rindex($DATA_DIR,"\\");
if ($last_slash==$str_len-1)
{
	$DATA_DIR=substr $DATA_DIR, 0, $str_len-1;
}
print "\n The data directory is:
				$DATA_DIR
	"; 
	
my $emailaddress='ouqd@hotmail.com';
my $HeaderFile="$DATA_DIR/PA42.header";
my $walltime="100:00:00";
	
my $SampleID=trim($ARGV[1]); 

if ( $SampleID eq "")
{
	print "

	Please input a population/Sample ID (The 2nd args), which will be used as the names of the output files.
	
	"; 
	exit
}

print "Population/SampleID is: $SampleID\n\n";

#Now we find the mpileup files and produce a batch file for them

opendir (DIR, $DATA_DIR) or die "can't open the directory!";
@dir = readdir DIR;
foreach $file (@dir) 
{
	$str_len = length($file);
	my $last_dot=rindex($file,".");
	$OUTPUT=substr $file, 0, $last_dot;
	my $extension=substr $file, $last_dot, $str_len-$last_dot;	
	
	if ( $extension eq ".proview") {
		$n_proview_all+=1;	
	}
	if ( $extension eq ".mpileup") {
		$n_mpileup+=1;			
		if(-e "$DATA_DIR/$OUTPUT.proview")
		{
			$n_proview_exist+=1;	
		}
		else
		{		
			$n_proview_not_exist+=1;	
		}			
	}
}

if ($n_mpileup==0)
{
	print "No mpileup file found!\n";
}
if ($n_proview_all==0)
{
	print "No proview file found!\n";
}
if (($n_mpileup+$n_proview_all)==0)
{
	print "Nothing to do, program will exit!\n";
	exit;
}

my $localtime = localtime();
open OUT1, ">./mapgd-parallel-$SampleID.pbs" or die "cannot open file: $!";
print OUT1 
"#!/bin/bash 
#PBS -N mapgd-$SampleID
#PBS -k o
#PBS -l nodes=1:ppn=16,walltime=$walltime
#PBS -l vmem=100gb
#PBS -M $emailaddress
#PBS -m abe
#PBS -j oe

# Updated on 05/28/2018
# This pipeline pbs is produced by the perl script:
# 		perl MPMP.pl $ARGV[0] $ARGV[1] 

# Date and time: $localtime

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
set -x

time samtools view -H $SampleID-001-qFf-RG_Sorted_dedup_realigned_Clipped.bam \> $HeaderFile

set +x
echo ===============================================================
echo 1. Make a pro file of nucleotide-read quartets -counts of A, C, G, and T, from each of the mpileup files of the clones.
echo ===============================================================
set -x
date
";
close(DIR);
opendir (DIR, $DATA_DIR) or die "can't open the directory!";
@dir = readdir DIR;
foreach $file (@dir) 
{
	$str_len = length($file);
	my $last_dot=rindex($file,".");
	$OUTPUT=substr $file, 0, $last_dot;
	my $extension=substr $file, $last_dot, $str_len-$last_dot;	

	#print $OUTPUT." ".$extension."\n ";
	
	if ( $extension eq ".mpileup") {
		
		print "\n$n_mpileup: $file --> $OUTPUT.proview";
		
		if(-e "$DATA_DIR/$OUTPUT.proview")
		{
			print ": already exist.\n "; 
		}
		else
		{		
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

if (($n_mpileup+$n_proview_all)==0)
{
	print "No mpileup or proview file found!\n";
	exit;
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
time java -cp $mapgd_parallel CombineProview $DATA_DIR $SampleID
set +x
echo ===============================================================
echo 3. Exclude mtDNA data from the pro file.
echo ===============================================================
echo  if mtDNA sequence is not included in the reference genome, skip this step:
echo  if mtDNA sequence is included in the reference genome, execute the following commands:
echo  mv PA2013.combined.Pro.txt PA2013.combined.Nuc+mt.pro.txt
echo  time grep -v '^PA42_mt_genome' PA2013.combined.Nuc+mt.pro.txt \\\> PA2013.combined.pro.txt
set +x

echo ===============================================================
echo 4. Run the allele command to estimate allele and genotype frequencies from the pro file.
echo ===============================================================
set -x
time mapgd allele -i $DATA_DIR/$SampleID.combined.pro.txt -o $DATA_DIR/$SampleID.combined.map -p $DATA_DIR/$SampleID.combined.clean
set +x

echo ===============================================================
echo 5. Run the filter command to filter the map file of ML estimates of the parameters.
echo ===============================================================
set -x

date

time mapgd filter -i $DATA_DIR/$SampleID.combined.map.map -p 20 -q 0.05 -Q 0.45 -c 800 -C 2400 -o $DATA_DIR/$SampleID.combined_filtered.map

date

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
time mapgd genotype -p $DATA_DIR/$SampleID.combined.clean.pro -m $DATA_DIR/$SampleID.combined_filtered.map.map > $DATA_DIR/$SampleID.combined.genotype
set +x

echo ===============================================================
echo 6-1. Remove the unnecessary header and footer
echo ===============================================================
set -x
time awk \'{if (\$3 != \"MN_FREQ\" && \$3 >= 0.0 && \$3 <= 1.0) print}\' $DATA_DIR/$SampleID.combined.genotype \> $DATA_DIR/$SampleID.combined_F.genotype
set +x
echo ===============================================================
echo 6-2. Randomly pick a specified number - 200000 of SNPs from the file of genotype likelihoods 
echo ===============================================================

set -x
time /N/dc2/projects/daphpops/Software/MAPGD-0.4.26/extras/sub_sample.py $DATA_DIR/$SampleID.combined_F.genotype -N 200000 > $DATA_DIR/$SampleID.combined_F_200K.genotype
set +x
echo ===============================================================
echo 6-3. Extract the header from the file of genotype likelihoods
echo ===============================================================
set -x
time head -n -1 $DATA_DIR/$SampleID.combined.genotype | awk \'{if (\$3 == NULL || \$1 ~ /^@/) print}\' \> $DATA_DIR/$SampleID.combined_header.genotype
set +x
echo ===============================================================
echo 6-4. Extract the footer from the file of genotype likelihoods
echo ===============================================================

set -x
time tail -n 1 $DATA_DIR/$SampleID.combined.genotype > $DATA_DIR/$SampleID.combined_footer.genotype
set +x
echo ===============================================================
echo 6-5. Add the header and footer to the sub-sample of the file of genotype likelihoods
echo ===============================================================

set -x
time cat $DATA_DIR/$SampleID.combined_header.genotype $DATA_DIR/$SampleID.combined_F_200K.genotype $DATA_DIR/$SampleID.combined_footer.genotype > $DATA_DIR/$SampleID.combined_F_200K_wh_wf.genotype

set +x
echo ===============================================================
echo 7. Run the relatedness command
echo ===============================================================

set -x

date

time mapgd relatedness -i $DATA_DIR/$SampleID.combined_F_200K_wh_wf.genotype -o $DATA_DIR/$SampleID.combined_F_200K_wh_wf_rel.out

date

set +x
echo ===============================================================
echo =============Task completed.===================
echo ===============================================================

";	
if (($n_mpileup+$n_proview_all)>0)
{		
print "
	$n_mpileup mpileup file(s) are found. 
	$n_proview_exist of them have existing proveiw files.
	$n_proview_not_exist of them have no mapgd proview file(s). 
	and there are $n_proview_all existing proveiw files.
	A parallel mapgd pipeline (./mapgd-parallel.pbs) is produced.
	
	To proceed, simply submit and run: 
	============================================================
		qsub ./mapgd-parallel-$SampleID.pbs	
	============================================================
		
	\"$SampleID.combined\" will be used as the initial of the names of the output files.
	
	When complete, $n_proview_not_exist proview file(s) will be produced and 
	$n_proview_not_exist+$n_proview_all  proview file(s) will be combined into one proview file.
	And then, it will proceed to the rest of the original mapgd pipeline.
	
	";
}

if ($n_mpileup>0&&$n_proview_not_exist==0)
{	
print "
	All mpileup file(s) already have proview file(s) exist.
	
	If you want to reproduce proview file(s), please remove the existing proview files firstly.
	
	"; 
}

if ($n_proview_all>0)
{
	print "
	Plese note that the $n_proview_all existing proveiw files in the data 
	dir will also be combined and included in the downstream analysis.
		
	";
}


sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

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
