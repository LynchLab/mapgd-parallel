## Parallel mapgd pipeline for population genetics computation on NGS data
### Lynch Lab, CME, Biodesign, ASU 
#### Curated by: Xiaolong Wang, Takahiro Maruki, Zhiqiang Ye, Chaoxian Zhao, R. Taylor Raborn and Michael Lynch
#### Correspondence to: Michael Lynch <mlynch11@asu.edu>
#### Bug reporting to: Xiaolong Wang <ouqd@hotmail.com>
#### Initialized May 28, 2018

===========================================================================
### How to make and run the parallel mapgd pipeline  
============================================================================			
		
After mapping all the reads to the reference genome, you have got a number of .mpileup files: 

	========================================================
	
		SampleID-001.mpileup
		SampleID-002.mpileup
			......
			......
		SampleID-096.mpileup
		
	========================================================

1. Make a parallel mapgd pipeline: 

	========================================================
	
		perl MPMP.pl <DATA_DIR> <Output>
		
	========================================================
	
This will find all mpileup files in the data directory and produce a parallel mapgd pipeline (mapgd-parallel.pbs) for them.

2. Submit the parallel mapgd pipeline:

	===============================================

		qsub mapgd-parallel.pbs
		
	===============================================
	
This parallel mapgd pipeline will produce a mapgd proview file for each mpileup file in parallel, combine all mapgd proview files into one using a java program (CombineProview.java), and then do the rest of the mapgd pipeline the same as the original mapgd pipeline(mapgd_original.pbs).

===========================================================================
### How does the parallel mapgd pipeline work? 
	--What is the diffrence from the original pipeline?
===========================================================================

Comparing with the original mapgd pipeline, the only difference is the way how mapgd proview files are produced.

In the original pipeline, mapgd proview files are produced by the following command:

	=========================================================================
 
		mapgd proview -i *.mpileup -H $HeaderFile > output.pro.txt 
		
 	=========================================================================

mapgd will find all mpileup files and then produce a proview file for each mpileup file one by one. This is simple and straightforward. However, it is very slow because it is not fully parallelized. This step may takes up to 50-100 hours for a population with 96 clones. 

To reduce the computation time, in this new pipeline (mapgd-parallel.pbs, produced by MPMP.pl), the proview files are generated independently and in parallel:
 
	====================================================================================
	
	mapgd proview -i $SampleID-001.mpileup -H $HeaderFile > $SampleID-001.proview &
	mapgd proview -i $SampleID-002.mpileup -H $HeaderFile > $SampleID-002.proview &
	mapgd proview -i $SampleID-003.mpileup -H $HeaderFile > $SampleID-003.proview &
	
			... ...
			
	mapgd proview -i $SampleID-096.mpileup -H $HeaderFile > $SampleID-096.proview &
	
	wait
	
	=====================================================================================

Then, the mapgd proview files produced are combined by using a java program (CombineProview.java), which will find all mapgd proview files and combined them into one (and transform the file format from one clone to multi-clone):

	=============================================================
	
		java -cp ./ CombineProview <DATA_DIR> <output>
		
	=============================================================
	
In this way, mapgd proview files are produced for each of the clones in a population. Because all processes can be run simutaneously in independent threads, the computation time is greatly reduced in a multi-core computer.

In addition, it also helps to identify a bad mpileup file (if any) more conviniently. When one of the mpileup files is invalid, it breaks only one of the mapgd proview threads, and will not break the whole pipeline. Just fix (or ignore) the bad one, no need to re-compute the whole population.
	
================================END=======================================
