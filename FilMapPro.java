
import java.io.*;
import java.util.Arrays;

public class FilMapPro{
	public static String Error1 ; //Error rate
	public static String Error2 ; //Error rate
	public static double MinPLR = 0; //Min likelyhood polymorphic
	public static double MinHLR = 0; //Min chi-square of M:m ratio 
	public static int MinC = 0; //Min Cov
	public static int MaxC = 0; //Max Cov
	public static String WD ;
	public static String MapFile;	
	public static String ProFile;

public static void main(String[] args)
{
	int S=0; //S
	int L=0; //Position	
	int nTotal=0;
	int nPolymorphic=0;
	int nSigPolymorphic=0;
	int nInSigPolymorphic=0;
	int nMmBiased=0;
	int nLowCov=0;
	int nHighCov=0;
	int	nGoodCov=0;
	int nMmBiasedSig=0;
	int nLowCovSig=0;
	int nHighCovSig=0;
	int	nGoodCovSig=0;
	int nF1=0;
	int nF2=0;
	int nF3=0;
	int nF4=0;
	String OStr="";
	String lineMap ="";
	String linePro ="";
	String [] a=new String [100];
	String [] b=new String [30];
	String [] CloneIDs=new String [100];
	int [][] quarters=new int [100][4];
	double P =0.0; //gene freq (pi)
	double pi =0.0; //gene freq (pi)
	double Q =0.0; //gene freq (qi)
	double H =0.0; //Hetero freq (pi)
	double F =0.0; // Inbreeding Coefficient estimate (Fis) 
	String group="";
	String Ref ="";
	String Maj ="";
	String Min ="";
	int    COV = 0 ; //Cov
	double MJ_FREQ =0.0; // 
	double VR_FREQ =0.0; // 
	double ERROR =0.0; // 
	double NULL_ER =0.0; // 
	double NULL_ER2 =0.0; // 
	double F_STAT =0.0; // 
	double MM_FREQ =0.0; // 
	double Mm_FREQ =0.0; // 
	double mm_FREQ =0.0; // 
	double HETERO =0.0; // 
	double PLR =0.0; // 
	double HWE_LR =0.0; // 
	double GOF =0.0; // 
	double EF_CHRM =0.0; // 
	double IND_INC =0.0; // 
	double IND_CUT =0.0; // 
	double BEST_LL =0.0; // 
	double HLR =0.0;
	int isPolymorphic=0;
	String Pstr ="";
	String PLRstr ="";
	String HLRstr ="";
	String COVstr ="";
	String Hstr ="";
	String pistr ="";
	String Fisstr =""; // Inbreeding Coefficient estimate
	String F_Str ="";//mapgd output
try
{	
	FilMapPro FAobj=new FilMapPro();
	
	if (args.length!=14) 
	{
		System.out.println("\nThis program is to Filter mapgd .map file and .pro by Cov, polymorphic likelyhood ratio and heterozygotes M:m ratio chi-square test at given error rates.\n"); 
		System.out.println("\nUsage: Java -cp ./ FilMapPro <-e e> <-E E> <-c FilMapPro.MinC> <-C FilMapPro.MaxC> <-d FilMapPro.WD> <-m FilMapPro.MapFile> <-p FilMapPro.ProFile>\n"); 
		System.exit(1);	
	}
	
	// Parse args
	String argstr="";
	for(int j=0;j<args.length;j++)
	{
		argstr=argstr+args[j].trim()+" ";
	}
	
	int InputErrors=0;
	InputErrors=FilMapPro.CheckInputArgs(argstr);
	
	if(InputErrors>=1) {System.exit(1);	}

	BufferedReader brMap = new BufferedReader(new InputStreamReader(new BufferedInputStream(new FileInputStream(new File(FilMapPro.MapFile))),"utf-8"),5*1024*1024); // reading file using 5M buffer
	
	BufferedReader brPro = new BufferedReader(new InputStreamReader(new BufferedInputStream(new FileInputStream(new File(FilMapPro.ProFile))),"utf-8"),5*1024*1024); // reading file using 5M buffer
	
	String fFilter="e-"+FilMapPro.Error1+"-E-"+FilMapPro.Error2+"-C-"+FilMapPro.MinC+"-"+FilMapPro.MaxC+"-Fis.txt";	
	String fFileName = FilMapPro.MapFile.substring(0, FilMapPro.MapFile.indexOf(".map.map"));
	String fAll = fFileName+".All."+fFilter;
	String fPolymorphic = fFileName+".Polymorphic."+fFilter;

	//String fDimorphic = fFileName+".Dimorphic."+fFilter;
	
	
	BufferedWriter bwfAll = new BufferedWriter(new OutputStreamWriter( new BufferedOutputStream(new FileOutputStream(new File(fAll))),"utf-8"),1024*1024); // Writing file using 1M buffer 
		
	BufferedWriter bwfPolymorphic = new BufferedWriter(new OutputStreamWriter( new BufferedOutputStream(new FileOutputStream(new File(fPolymorphic))),"utf-8"),1024*1024); // Writing file using 1M buffer 
		
	//BufferedWriter bwfDimorphic = new BufferedWriter(new OutputStreamWriter( new BufferedOutputStream(new FileOutputStream(new File(fDimorphic))),"utf-8"),1024*1024); // Writing file using 1M buffer 
	
	String headline="";
	headline+="Sca\t"; 
	headline+="Pos\t"; 
	headline+="GROUP\t"; 
	headline+="Ref\t"; 
	headline+="Maj\t"; 
	headline+="Min\t"; 
	headline+="P\t";  
	headline+="Poly_LR\t";  
	headline+="Het_LR\t";  
	headline+="Cov\t";  
	headline+="pi\t"; 
	headline+="H\t";  
	headline+="F\t";  
	headline+="Fis\n";

	bwfAll.write(headline);
	bwfPolymorphic.write(headline);
	lineMap=brMap.readLine();
	linePro=brPro.readLine();
	
	System.out.println("Reading the .map files:\n");
	System.out.print("Map File:"+FilMapPro.MapFile+"\n ");	
	System.out.println(lineMap+"\n");
	
	if (lineMap.indexOf("@NAME:GENOME")<0)
	{		
		System.out.println("The .map file is incorrect!\n");
		InputErrors++;
		if(lineMap.indexOf("VERSION:0.4.3")<0)
		{			
			System.out.println("Your mapgd version is low. The .map file must be produced by mapgd VERSION 0.4.3x!\n");
			InputErrors++;
		}
	}
	
	System.out.println("Reading the .pro files:\n");
	System.out.print("Pro File:"+FilMapPro.ProFile+"\n ");
	System.out.println(linePro+"\n");
	
	if (linePro.indexOf("@NAME:QUARTETS")<0)
	{		
		System.out.println("The .pro file is incorrect!\n");
		InputErrors++;
		if(linePro.indexOf("VERSION:0.4.3")<0)
		{			
			System.out.println("Your mapgd version is low. The .pro file must be produced by mapgd VERSION 0.4.3x!\n");
			InputErrors++;
		}
	}
	if(InputErrors>=1) {	System.exit(1);	}
	
	while((lineMap=brMap.readLine()) != null)
	{
		linePro=brPro.readLine();
		
		if (linePro==null) {break;}
		
		//System.out.print(lineMap+"\n");
		//System.out.print(linePro+"\n");
		
		a = linePro.split("\t");
		b = lineMap.split("\t");
		
		if (linePro.indexOf("@ID0")>=0) // the first line
		{	
			
			for(int k=3;k<a.length;k++)
			{
				int firstdot=a[k].indexOf(".");
				if (firstdot>0) 
				{
					a[k]=a[k].substring(0,firstdot);
				}
				CloneIDs[k-3]=a[k];
				//System.out.print(CloneIDs[k-3]+"\n");
			}			
		}
		if (lineMap.indexOf("scaffold_")>=0)  
		{		
			nTotal++;
			
			//System.out.print(lineMap+"\n");
			//System.out.print(linePro+"\n");

			OStr="";
			
			for(int k=3;k<a.length;k++)
			{
				String [] quarterstr=a[k].trim().split("/");
				quarters[k-3][0]=Integer.parseInt(quarterstr[0]);
				quarters[k-3][1]=Integer.parseInt(quarterstr[1]);
				quarters[k-3][2]=Integer.parseInt(quarterstr[2]);
				quarters[k-3][3]=Integer.parseInt(quarterstr[3]);
				
				/*if (nTotal%1000000==0) 
				{
					System.out.print(quarters[k-3][0]+"|");
					System.out.print(quarters[k-3][1]+"|");
					System.out.print(quarters[k-3][2]+"|");
					System.out.print(quarters[k-3][3]+",\t");
				}*/
			}
			
			//if (nTotal%1000000==0) {System.out.print("\n");} 
						
			for(int k=0;k<b.length;k++)
			{
				if (b[k]==null) 				{b[k]="0.0000";};
				if (b[k].trim().isEmpty()) 		{b[k]="0.0000";};
				if (b[k].trim().equals(".")) 	{b[k]="0.0000";};
				if (b[k].trim().equals("inf")) 	{b[k]="0.0000";};
				//if (nTotal%1000000==0) {System.out.print(b[k]+"\t");}
			}
			
			//if (nTotal%1000000==0) {System.out.print("\n......\n");}
			//else {break;}
			
			S = Integer.parseInt(b[0].substring(9)); //S
			L = Integer.parseInt(b[1]); //Position
			
			isPolymorphic=0;

			if (b.length==23) 
			{
				Ref 		= b[2] ;                    
				Maj 		= b[3] ;                    
				Min 		= b[4] ;                    
				COV			= Integer.parseInt(b[5]) ;  
				MJ_FREQ 	= Double.parseDouble(b[6] );
				VR_FREQ 	= Double.parseDouble(b[7] );
				ERROR 		= Double.parseDouble(b[8] );
				NULL_ER 	= Double.parseDouble(b[9] );
				NULL_ER2	= Double.parseDouble(b[10]);
				F_STAT 		= Double.parseDouble(b[11]);
				MM_FREQ 	= Double.parseDouble(b[12]);
				Mm_FREQ 	= Double.parseDouble(b[13]);
				mm_FREQ 	= Double.parseDouble(b[14]);
				HETERO 		= Double.parseDouble(b[15]);
				PLR 		= Double.parseDouble(b[16]);
				HWE_LR 		= Double.parseDouble(b[17]);
				GOF 		= Double.parseDouble(b[18]);
				EF_CHRM 	= Double.parseDouble(b[19]);
				IND_INC 	= Double.parseDouble(b[20]);
				IND_CUT 	= Double.parseDouble(b[21]);
				BEST_LL 	= Double.parseDouble(b[22]);
				
				if (MJ_FREQ==0){MJ_FREQ=1.0;}//Major frequency
				
				P  = 1.0-MJ_FREQ; //Minor allele frequency
				pi = 2*P*(1-P); // HWE hetero genotype (Mm) frequency expect /nucleotide diversity
				H = Mm_FREQ; //hetero genotype (Mm) frequency estimate
				
				if (pi>0.0){F=1-H/pi;}//Inbreeding coefficient (Fis)
				else{F=0.0;} 
			
			
				// Test total Major:Minor ratio in heterozygotes
				int IndMaj="ACGT".indexOf(Maj);
				int IndMin="ACGT".indexOf(Min);
				int M=0;
				int N=0;
				HLR=9999.9;
				if(IndMaj>=0&&IndMaj<=3&&IndMin>=0&&IndMin<=3)
				{	
					for(int j=0;j<100;j++)
					{
						if (quarters[j][IndMaj]>1&&quarters[j][IndMin]>1)
						{
							M+=quarters[j][IndMaj];
							N+=quarters[j][IndMin];
						}
					}	
					double m=(M+N)/2;
					HLR = ((M-m)*(M-m)+(N-m)*(N-m))/m;
				}
				
				if(P>0.0) 
				{
					nPolymorphic++;
					if(PLR<FilMapPro.MinPLR)
					{
						nInSigPolymorphic++;
						if(COV<FilMapPro.MinC){nLowCov++;}
						if(COV>FilMapPro.MaxC){nHighCov++;}
						if(COV>=FilMapPro.MinC&&COV<=FilMapPro.MaxC)
						{
							nGoodCov++;
							if(HLR>=FilMapPro.MinHLR)
							{
								nMmBiased++;
								if(F<=-0.33){nF1++;} else {nF2++;}
							}
						}
					}	
					else
					{
						if(COV<FilMapPro.MinC){nLowCovSig++;}
						if(COV>FilMapPro.MaxC){nHighCovSig++;}
						if(COV>=FilMapPro.MinC&&COV<=FilMapPro.MaxC)
						{
							nGoodCovSig++;
							if(HLR>=FilMapPro.MinHLR)
							{
								nMmBiasedSig++;
								if(F<=-0.33){nF3++;} else {nF4++;}
							}
						}
					}
				}								
				if(P>0.0&&PLR>=FilMapPro.MinPLR&&HLR<FilMapPro.MinHLR&&COV>=FilMapPro.MinC&&COV<=FilMapPro.MaxC) 
				{
					isPolymorphic=1;
					nSigPolymorphic++;
				}
				else
				{
					F = 0.0;
					//P		= 0.0;
					//pi	= 0.0;
					//H 	= 0.0;
					//F_STAT= 0.0;
				} 
				Pstr	= String.valueOf(Math.round(P*10000)/10000.0);
				PLRstr	= String.valueOf(Math.round(PLR*10000)/10000.0);
				HLRstr	= String.valueOf(Math.round(HLR*10000)/10000.0);
				if(HLRstr.equals("9999.9")){HLRstr=".";}
				COVstr	= String.valueOf(Math.round(COV*10000)/10000.0);
				pistr	= String.valueOf(Math.round(pi*10000)/10000.0);
				Hstr	= String.valueOf(Math.round(H*10000)/10000.0);
				F_Str	= String.valueOf(Math.round(F_STAT*10000)/10000.0);
				Fisstr	= String.valueOf(Math.round(F*10000)/10000.0);
				group	= String.valueOf(Math.round(P*100)/100.0);
			}
			
			OStr+=S+"\t";
			OStr+=L+"\t";
			OStr+=group+"\t";			
			OStr+=Ref+"\t";
			OStr+=Maj+"\t";
			OStr+=Min+"\t";
			
			OStr+=Pstr+"\t";
			OStr+=PLRstr+"\t";
			OStr+=HLRstr+"\t";
			OStr+=COVstr+"\t";
			OStr+=pistr+"\t";
			OStr+=Hstr+"\t";
			OStr+=F_Str+"\t";
			OStr+=Fisstr+"\n";
			
			OStr=OStr.replaceAll("0.0\t", ".\t");
			
			bwfAll.write(OStr);
			
			if (isPolymorphic>0)
			{
				bwfPolymorphic.write(OStr);	
			}
		}
	} //end while
	
	bwfAll.close();
	bwfPolymorphic.close();
	
	System.out.print("Results were saved in files:\n");
	System.out.print(fAll+"\n");
	System.out.print(fPolymorphic+"\n");
	//System.out.print(fDimorphic+"\n");
	
	String fOut = fFileName+fFilter+"out.txt";
	BufferedWriter bwfOut = new BufferedWriter(new OutputStreamWriter( new BufferedOutputStream(new FileOutputStream(new File(fOut))),"utf-8"),10*1024); // Writing file using 1M buffer 
	
	bwfOut.write(fPolymorphic+"\n");
	bwfOut.write("Total sites: "+nTotal+"\n");
	bwfOut.write("Polymorphic (P>0): "+nPolymorphic+"\n");
	bwfOut.write("F>-0.33: "+nF1+"\n");
	bwfOut.write("F<=-0.33: "+nF2+"\n");
	bwfOut.write("Significant: "+nSigPolymorphic+"\n");
	bwfOut.write("Insignificant: "+nInSigPolymorphic+"\n");
	bwfOut.write("Cov<"+FilMapPro.MinC+"&significant: "+nLowCovSig+"\n");
	bwfOut.write("Cov>"+FilMapPro.MaxC+"&significant: "+nHighCovSig+"\n");
	bwfOut.write("Cov<"+FilMapPro.MinC+"&insignificant: "+nLowCov+"\n");
	bwfOut.write("Cov>"+FilMapPro.MaxC+"&insignificant: "+nHighCov+"\n");
	bwfOut.write("Cov="+FilMapPro.MinC+"-"+FilMapPro.MaxC+"&significant: "+nGoodCovSig+"\n");
	bwfOut.write("Cov="+FilMapPro.MinC+"-"+FilMapPro.MaxC+"&insignificant: "+nGoodCov+"\n");
	bwfOut.write("M/m biased&significant: "+nMmBiasedSig+"\n");	
	bwfOut.write("M/m biased&insignificant: "+nMmBiased+"\n");	
	bwfOut.write("F>-0.33: "+nF3+"\n");
	bwfOut.write("F<=-0.33: "+nF4+"\n");
	bwfOut.close();
}
catch(Exception e)
	{
		System.out.println("\nThis program is to FilMapPro\n"); 
		System.out.println("\nUsage: Java -cp ./ FilMapPro <Error> <FilMapPro.MinC> <FilMapPro.MaxC> <FilMapPro.WD> <FilMapPro.MapFile> <FilMapPro.ProFile>\n"); 
		System.out.println(e);
		e.printStackTrace();		
	}
}
public static int CheckInputArgs(String argstr)
{
	int e1=argstr.indexOf("-e"); 
	int E1=argstr.indexOf("-E"); 
	int c1=argstr.indexOf("-c"); 
	int C1=argstr.indexOf("-C"); 
	int d1=argstr.indexOf("-d"); 
	int m1=argstr.indexOf("-m"); 
	int p1=argstr.indexOf("-p"); 
	
	int e2=argstr.indexOf(" ", e1);
	int E2=argstr.indexOf(" ", E1);
	int c2=argstr.indexOf(" ", c1);
	int C2=argstr.indexOf(" ", C1);
	int d2=argstr.indexOf(" ", d1);
	int m2=argstr.indexOf(" ", m1);
	int p2=argstr.indexOf(" ", p1);
	
	int e3=argstr.indexOf(" ", e2+1);
	int E3=argstr.indexOf(" ", E2+1);
	int c3=argstr.indexOf(" ", c2+1);
	int C3=argstr.indexOf(" ", C2+1);
	int d3=argstr.indexOf(" ", d2+1);
	int m3=argstr.indexOf(" ", m2+1);
	int p3=argstr.indexOf(" ", p2+1);
	
	
	int InputErrors=0;
	
	//System.out.print("-e:"+e1+" "+e2+" "+e3+"\n");
	if (e1<0||e2<0||e3<0) 
	{
		System.out.print("Please input the error rate for polymorphic likelyhood ratio test: -e 0.05 or -e 0.01.\n");
		InputErrors++;
	}
	//System.out.print("-E:"+E1+" "+E2+" "+E3+"\n");
	if (E1<0||E2<0||E3<0) 
	{
		System.out.print("Please input the error rate for heterozygotes M:m ratio chi-square test: -E 0.05 or -E 0.01.\n");
		InputErrors++;
	} 
	
	//System.out.print("-c:"+c1+" "+c2+" "+c3+"\n");
	if (c1<0||c2<0||c3<0) 
	{
		System.out.print("Please input the minimum Cov for polymorphic , for example: -c 300.\n");
		InputErrors++;
	}
	
	//System.out.print("-C:"+C1+" "+C2+" "+C3+"\n");
	if (C1<0||C2<0||C3<0) 
	{
		System.out.print("Please input the maximum Cov for polymorphic , for example: -C 3000\n");
		InputErrors++;
	}
	
	//System.out.print("-d:"+d1+" "+d2+" "+d3+"\n");
	if (d1<0||d2<0||d3<0) 
	{
		System.out.print("Please input the working directory, for example: -d ~/mydata/.\n");
		InputErrors++;
	}
	
	//System.out.print("-m:"+m1+" "+m2+" "+m3+"\n");
	if (m1<0||m2<0||m3<0) 
	{
		System.out.print("Please input the .clean.map file, for example: PA.clean.map.map.\n");
		InputErrors++;
	}
	
	//System.out.print("-p:"+p1+" "+p2+" "+p3+"\n");
	if (p1<0||p2<0||p3<0) 
	{
		System.out.print("Please input the .clean.pro file, for example: PA.clean.pro\n");
		InputErrors++;
	}
	
	if(InputErrors>=1) {	System.exit(1);	}
	
	FilMapPro.Error1 = argstr.substring(e2,e3).trim(); //Error rate
	FilMapPro.Error2 = argstr.substring(E2,E3).trim(); //Error rate
	FilMapPro.MinPLR = 0; //Min likelyhood polymorphic
	FilMapPro.MinHLR = 0; //Min chi-square of major:minor ratio 
	
	//System.out.print("Error rate for polymorphic likelyhood test: "+FilMapPro.Error1+"\n");
	
	if (FilMapPro.Error1.indexOf("0.05")>=0)
	{
		FilMapPro.MinPLR = 5.991; 
	}
	else
	{
		if (FilMapPro.Error1.indexOf("0.01")>=0)
		{
			FilMapPro.MinPLR = 9.21; 
		}
		else
		{
			System.out.print("The error rate must be either 0.05 or 0.01.\n");
			InputErrors++;
		}
	}
	//System.out.print("Polymorphic likelyhood ratio >="+FilMapPro.MinPLR+"\n ");

	//System.out.print("Error rate for heterozygotes M:m ratio test:"+FilMapPro.Error2+"\n");
	if (FilMapPro.Error2.indexOf("0.05")>=0)
	{
		FilMapPro.MinHLR = 3.841; 
	}
	else
	{
		if (FilMapPro.Error2.indexOf("0.01")>=0)
		{
			FilMapPro.MinHLR = 6.64; 
		}
		else
		{
			System.out.print("The error rate must be either 0.05 or 0.01.\n");
			InputErrors++;
		}
	}
	
 	//System.out.print("Chi-square<"+FilMapPro.MinHLR+"\n ");

	String Cov1 = argstr.substring(c2,c3).trim(); //Error rate
	String Cov2 = argstr.substring(C2,C3).trim(); //Error rate

	//System.out.print("the Cov for polymorphic  between:"+Cov1+" - "+Cov2+"\n ");
	
	FilMapPro.MinC = Integer.parseInt(Cov1); //Min Cov
	FilMapPro.MaxC = Integer.parseInt(Cov2); //Max Cov

	if(FilMapPro.MinC<0)
	{
		System.out.println("The minimum Cov (-c) must greater than 0:\n");
		InputErrors++;
	}
	if(FilMapPro.MaxC<0)
	{
		System.out.println("The Maximum Cov (-C) must greater than 0:\n");
		InputErrors++;
	}
	if(FilMapPro.MinC>=FilMapPro.MaxC)
	{
		System.out.println("The Maximum Cov (-C) must greater than minimum Cov (-c):\n");
		InputErrors++;
	}
	
	FilMapPro.WD = argstr.substring(d2,d3).trim();
	int L0=FilMapPro.WD.length();
	if (FilMapPro.WD.substring(L0).equals("/")){FilMapPro.WD=FilMapPro.WD.substring(0,L0-1);}
	
	System.out.print("Working directory:"+FilMapPro.WD+"\n ");
		
	FilMapPro.MapFile = FilMapPro.WD+"/"+argstr.substring(m2,m3).trim();	
	FilMapPro.ProFile = FilMapPro.WD+"/"+argstr.substring(p2,p3).trim();
	
	int i1 = FilMapPro.MapFile.toLowerCase().indexOf(".clean.map.map");	
	int i2 = FilMapPro.ProFile.toLowerCase().indexOf(".clean.pro"); 	                       			
	if(i1<0)
	{
		System.out.println(FilMapPro.MapFile+"<--The map must be a .clean.map.map file:\n");
		InputErrors++;
	}
	
	if(i2<0)
	{
		System.out.println(FilMapPro.ProFile+"<--The pro must be a .clean.pro file:\n");
		InputErrors++;
	}
	
	File mfile = new File(FilMapPro.MapFile);	
	File pfile = new File(FilMapPro.ProFile);	
	
	if(!mfile.exists())
	{
		System.out.println(FilMapPro.MapFile+"<--The .map file is not found!\n");
		InputErrors++;
	}
	
	if(!pfile.exists())
	{
		System.out.println(FilMapPro.ProFile+"<--The .pro file is not found!\n");
		InputErrors++;
	}
	
	String f1=FilMapPro.MapFile.substring(0,i1);
	String f2=FilMapPro.MapFile.substring(0,i1);

	if(!f1.equals(f2))
	{
		System.out.println("The .map file does not match the .pro file!\n");
		InputErrors++;
	}
		
	return InputErrors;
	
}
}
/*
======================================================================
FilMapPro

Usage: FilMapPro using Gene Frequency Data and gene annotation file:
 
java -cp ./ FilMapPro <Error> <FilMapPro.MinC> <FilMapPro.MaxC> <FilMapPro.WD> <FilMapPro.MapFile> <FilMapPro.ProFile>
=====================================================================
Written by: 
Xiaolong Wang @ Ocean University of China 
email: xiaolong@ouc.edu.cn
website: http://www.DNAplusPro.com
=====================================================================
In hope useful in genomics and bioinformatics studies.
This software is released under GNU/GPL license
Copyright (c) 2018
1. Lynch Lab, CME, Biodesign, Arizona State University
2. Lab of Molecular and Computational Biology, Ocean University of China

You may use it or change it as you wish. 
We will be glad to know if you find it is useful. 
=====================================================================
*/
