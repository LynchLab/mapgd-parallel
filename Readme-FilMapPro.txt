
#### Filtering Map Using FilMapPro ####

Program FilMapPro.java is used for filtering the sites by coverage, polymorphic likelihood ratio test and heterozygotes M:m ratio chi-square test. 

After downloading, to filter the sites by coverage, polymorphic likelihood ratio and M:m ratio chi-square tests, cd to the directory and type the following command:

java -cp ./ FilMapPro <-e e> <-E E> <-c c> <-C C> <-d WD> <-m MapFile> <-p ProFile>

e: Error rate for polymorphic likelihood ratio test
E: Error rate for heterozygotes M:m ratio chi-square tests
c: Min population total Coverage
C: Max population total Coverage
WD: working directory ;
MapFile: .clean.map file name;	
ProFile: .clean.pro file name

Both MapFile and ProFile must be produced by mapgd the newest version: 0.4.35.

If you need compile the java program, type:
javac -cp ./ FilMapPro.java

Please send email to ouqd@hotmail.com if you find bugs or have any questions or suggestions, thanks!.
