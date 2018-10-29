
#### Filtering Map Using FilMapPro

Program FilMapPro.java is used for filtering the sites by coverage, polymorphic likelihood ratio test and heterozygotes M:m ratio chi-square test. 

After downloading, cd to the directory and type the following command:

(1) To compile the java program, type:
javac -cp ./ FilMapPro.java

(2) To filter the sites by coverage, polymorphic likelihood ratio and M:m ratio chi-square tests:
java -cp ./ FilMapPro <-e e> <-E E> <-c c> <-C C> <-d WD> <-m MapFile> <-p ProFile>

e: Error rate for polymorphic likelihood ratio test
E: Error rate for heterozygotes M:m ratio chi-square tests
c: Min population total Coverage
C: Max population total Coverage
WD: working directory ;
MapFile: .clean.map file name;	
ProFile: .clean.pro file name
Please note that in the commands to run FilMapPro, 
(1) Both clean Map File and clean Pro File must be produced by mapgd the newest version: 0.4.35.
(2) The e or E value must be 0.05 or 0.01. 

For example:

java -cp ./ FilMapPro2 -e 0.05 -E 0.05 -c 300 -C 3000 -d /N/dc2/scratch/xw63/Maps-0.4.34 -m PA2017.clean.map.map -p PA2017.clean.pro > FilMapPro2-Out-PA2017-1.txt

java -cp ./ FilMapPro2 -e 0.01 -E 0.01 -c 800 -C 2400 -d /N/dc2/scratch/xw63/Maps-0.4.34 -m PA2013.clean.map.map -p PA2013.clean.pro > FilMapPro2-Out-PA2013-2.txt

### The output files:

After finished runing, the program will produce three output files:
(1) MapFile.All-e-e-E-E-C-c-C-Fis.txt: contains all sites of the map (including zeros). This file is useful for extracting the  sequences, such as CDSs, exon, intron, which can be used in downstream data analysis, such as computing dN/dS or piN/piS. Note that because mapgd do not check the reference genome and fill in the reference sequence that are absent in the input mpileup file but fill them with "Ns" instead, you must check the reference genome and fill in the reference sequence. You may do this using the following programs:
To creat a annotated reference genome sequence (combining the reference genome sequence and the GFF file:
    java -cp ./ CombineRefGFF
To check the reference genome and fill in the reference sequence:
    java -cp ./ AnnotateFilteredMaps  MapFile.All-e-e-E-E-C-c-C-Fis.txt
To extract CDSs:
    java -cp ./ ExtractCDSs
 
(2) MapFile.Polymorphic-e-e-E-E-C-c-C-Fis.txt: contains Polymorphic sites of the map (not including zeros).  This file is useful for downstream data analysis, such as allele / genotype frequency, heterozygosity, Fis analysis.
(3) MapFile-e-e-E-E-C-c-C-out.txt: contains the number of sites that are removed in the filtering process.

###Description of the headline of the output file: 

Sca: scaffold      
Pos: Position
GROUP: group used for plotting 
Ref: reference
Maj: Major type
Min: Minor type
P:  MAF
Poly_LR: Polymorphic likelihood ratio
Het_Chi: M:m test Chi-square
Cov: Coverage
Pi=2*P(1-P)
H: Heterozygote (Mm) frequency report by mapgd
F: Inbreeding coefficient report by mapgd
Fis: Inbreeding coefficient (computed)

Note:

Please send email to ouqd@hotmail.com if you find bugs or have any questions or suggestions, thanks!.
