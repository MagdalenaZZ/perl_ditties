#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV == 1 or @ARGV == 2 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: qc_pipeline.pl file.fastq (file2.fastq)


This pipeline makes a shell script which it submits as a job.
It subsamples 1.000.000 reads from the sample and

-Calculates length
-Does fastqc

If two files are given they are assumed to be PE reads

' . "\n";

}


my $cwd = cwd();
my $masterspace="/users/k1470436/scratch/REFERENCES";

#print OUT "Hi2\n";

# If only one file
my $in1=shift;
my @inh1 = split(/\//, $in1);
my $inh1 = $inh1[-1];
my @start1 = split(/_/, $inh1[-1]);
my $prefix1 = $start1[0] . "_" . $start1[1];
print "\n$in1 $inh1 $prefix1\n";

# if two files
my $prefix2=0;
my $in2=0;
my $inh2=0;
my @start2;

if (@ARGV==1) {
	$in2=shift;
	my @inh2 = split(/\//, $in2);
	$inh2 = $inh2[-1];
	@start2 = split(/_/, $inh2[-1]);
	$prefix2 = $start2[0] . "_" . $start2[1];
	print "\n$in2 $inh2 $prefix2\n";
}


#__END__



open (OUT, ">$prefix1.F.qc.sh2") || die "I can't open $prefix1.F.qc.sh2\n";
open (OUT1, ">$prefix1.F.qc.sh1") || die "I can't open $prefix1.F.qc.sh1\n";

#print "Made file $prefix1.F.qc.sh1 and $prefix1.F.qc.sh2 \n\n ";


# Make links
print OUT1 "# Jobs for making links and subsampling 1M reads\n\n";
print OUT1 "ln -s $in1 $prefix1.F.qc.fq.gz\n";

# Make a job for subsampling 1 million PE reads
#system "qsub  -q short.q -l h_vmem=1G -pe mpislots 1 -b y  -V -cwd  -N seqtksub \"/users/k1470436/bin/seqtk/seqtk sample -s1000 $in 1000000 > $in.sub1000000.fq\"";
print OUT1 "seqtk sample -s1000  $prefix1.F.qc.fq.gz 1000000 > $prefix1.F.sub1000000.fq";
print OUT1 "\n";

# Do initial read length histogram
print OUT "# Jobs for getting read length, running FastQC, parsing the output and then tidying up\n";
print OUT "head  -100 $prefix1.F.sub1000000.fq | awk '{if(NR%4==2) print OUT length}' | textHistogram -maxBinCount=350 stdin > $prefix1.F.len";
print OUT "\n";
# gzip

print OUT "gzip -f -r $prefix1.F.sub1000000.fq";
print OUT "\n";
# Do fastqc on them
my $fol = "$prefix1.F" . ".FQC";
print OUT "mkdir $fol";
print OUT "\n";
print OUT "fastqc --extract --o $fol   $prefix1.F.sub1000000.fq.gz";
print OUT "\n";
#print OUT "echo \"Read the full FastQC report:\"\n";
#print OUT  "echo \"firefox $fol/$prefix1.F.sub1000000.fq_fastqc.html &\" > $prefix1.F.docu\n";
#print OUT "\n";
#print OUT "cat $fol/$prefix1.F.sub1000000.fq_fastqc/fastqc_data.txt | grep '>>' | grep -v END_MODULE > $prefix1.F.FQC.txt\n";
print OUT "perl /users/k1470436/bin/perl/fastqc_parser.pl $prefix1.F $fol/$prefix1.F.sub1000000.fq_fastqc/fastqc_data.txt\n";
print OUT "\n";




# clean up after fastqc
print OUT "rm -f  $fol/$prefix1.F.sub1000000.fq_fastqc/fastqc.fo\n";
print OUT "rm -f  $fol/$prefix1.F.sub1000000.fq_fastqc/fastqc_report.html\n";
print OUT "rm -fr  $fol/$prefix1.F.sub1000000.fq_fastqc/Icons/\n";
print OUT "rm -fr  $fol/$prefix1.F.sub1000000.fq_fastqc/Images/\n";
print OUT "rm -f  $fol/$prefix1.F.sub1000000.fq_fastqc.zip\n";
print OUT "gzip -f -r $fol\n";
print OUT "mv $fol/*/* $fol\n";
print OUT "rm -fr $fol/$prefix1.F.sub1000000.fq_fastqc/\n";


# if two files
#my $in1;
#my $in2;
#$in1=$in;
#my $inh1=$inh;
#my $inh2;

if ($prefix2!~/^0$/) {

#my $in=shift;
#my @inh = split(/\//, $in);
#$inh=$inh[-1];
#$in2 = $in;
#$inh2 = $inh;



open (OUT, ">$prefix2.R.qc.sh2") || die "I can't open $prefix2.R.qc.sh2\n";

# Make a job for subsampling 1 million PE reads
#system "qsub  -q short.q -l h_vmem=1G -pe mpislots 1 -b y  -V -cwd  -N seqtksub \"/users/k1470436/bin/seqtk/seqtk sample -s1000 $in 1000000 > $in.sub1000000.fq\"";

print OUT1 "ln -s $in2 $prefix2.R.qc.fq.gz\n";
print OUT1 "seqtk sample -s1000 $prefix2.R.qc.fq.gz 1000000 > $prefix2.R.sub1000000.fq\n";
print OUT1 "\n";

# Do initial read length histogram
print OUT "# Jobs for getting read length, running FastQC, parsing the output and then tidying up\n";
print OUT "head -100  $prefix2.R.sub1000000.fq | awk '{if(NR%4==2) print OUT length}' | textHistogram -maxBinCount=350 stdin > $prefix2.R.len\n";
print OUT "\n";
# gzip

print OUT "gzip -f -r $prefix2.R.sub1000000.fq\n";
print OUT "\n";


# Do fastqc on them
my $fol = "$prefix2.R" . ".FQC";
print OUT "mkdir $fol";
print OUT "\n";
print OUT "fastqc --extract --o $fol   $prefix2.R.sub1000000.fq.gz\n";
print OUT "\n";
#print OUT "echo \"Read the full FastQC report:\"\n";
#print OUT  "echo \"firefox $fol/$prefix2.R.sub1000000.fq_fastqc.html &\" > $prefix2.R.docu\n";
#print OUT "\n";
#print OUT "cat $fol/$prefix2.R.sub1000000.fq_fastqc/fastqc_data.txt | grep '>>' | grep -v END_MODULE > $prefix2.R.FQC.txt\n";
print OUT "perl /users/k1470436/bin/perl/fastqc_parser.pl $prefix2.R $fol/$prefix2.R.sub1000000.fq_fastqc/fastqc_data.txt\n";
print OUT "\n";

#print OUT "Hi\n";

# clean up after fastqc
print OUT "rm -f  $fol/$prefix2.R.sub1000000.fq_fastqc/fastqc.fo\test_2.fastq.gzn";
print OUT "rm -f  $fol/$prefix2.R.sub1000000.fq_fastqc/fastqc_report.html\n";
print OUT "rm -fr  $fol/$prefix2.R.sub1000000.fq_fastqc/Icons/\n";
print OUT "rm -fr  $fol/$prefix2.R.sub1000000.fq_fastqc/Images/\n";
print OUT "rm -f  $fol/$prefix2.R.sub1000000.fq_fastqc.zip\n";
print OUT "gzip -f -r $fol\n";
print OUT "mv $fol/*/* $fol\n";
print OUT "rm -fr $fol/$prefix2.R.sub1000000.fq_fastqc/\n";


# Do overlap merging
print OUT "\n# Jobs for doing overlaps with FLASH software\n";
print OUT "flash --max-overlap 120 -o $prefix1 -t 1  $prefix1.F.sub1000000.fq.gz $prefix2.R.sub1000000.fq.gz 2>&1 | tee $prefix1.flash.log\n";


}
else {
	$in2 ="SINGLE";
}


# Now do mapping
# Map those reads to human, mouse and fusion proteins

print OUT "\n# Mapping with Bowtie2\n";

if ($in2=~/SINGLE/) {
print OUT "bowtie2  -p 1 --un-gz $prefix1.un.gz -x $masterspace/MASTER.fa -U $prefix1.F.sub1000000.fq.gz -S $inh1.sam \n";
print OUT "samtools view -q 30 -Sb $inh1.sam > $inh1.bam\n";
print OUT "rm -f $inh1.sam\n";
}

else {
# mapping unstranded on purpose so the orientation can be assessed
print OUT "bowtie2  -p 1 --un-conc-gz $prefix1.unc.gz -x $masterspace/MASTER.fa -1 $prefix1.F.sub1000000.fq.gz -2 $prefix2.R.sub1000000.fq.gz -S $prefix1.sam\n";
print OUT "samtools view -q 30 -Sb $prefix1.sam > $prefix1.bam\n";
print OUT "rm -f $prefix1.sam\n";
}


print OUT "\n# Get read orientations\n";
# Assess read orientation
print OUT "source activate py2.7\n";
print OUT "python /users/k1470436/bin/RSeQC-2.6.3/scripts/infer_experiment.py -i  $prefix1.bam -r ~/scratch/REFERENCES/MASTER.gene.bed > $prefix1.ie\n";
print OUT "source deactivate\n";

print OUT "\n# Check which species it is\n";
# Count up where they map
print OUT "samtools view $prefix1.bam | cut -f3 | awk -F'_' '{print \$1}' | sort | uniq -c | sort -nr | awk '{print \$1\"\\t\"\$2}' > $prefix1.species\n";
#print OUT "samtools view $in1.bam | cut -f3 | awk -F'_' '{print \$1}' | sort | uniq -c | sort -nr | awk '{print \$1\"\\t\"\$2}' > $in1.species\n";

print OUT "\n# Check if it is ChIP-Seq or RNA-Seq\n";
# Do a featurecount on genomic and intergenic regions
print OUT "featureCounts -s 0 --largestOverlap --minOverlap 10 --primary -C  -a $masterspace/MASTER.complete.gff.fc.ref  -o $prefix1.fc $prefix1.bam \n"; 
print OUT "cat $prefix1.fc | cut -f1,6,7 | grep -v featureCounts | grep -v Geneid | sort -k3,3nr > $prefix1.fc.res\n";

# Picard metrics count insert size and more
#print OUT "java -Xmx2g -jar /users/k1470436/bin/picard.jar CollectAlignmentSummaryMetrics INPUT=$in1.sort.bam REFERENCE_SEQUENCE=/isilon_home/mzarowieckibrc/scratch/REFERENCES/MASTER.fa OUTPUT=$in.sort.PASM\n";

print OUT "\n# Get further metrics with Picard\n";
print OUT "/users/k1470436/bin/jdk1.8.0_66/bin/java -cp \"/users/k1470436/bin/picard/dist/htsjdk_lib_dir/*.jar;/users/k1470436/bin/picard/htsjdk/dist/*.jar\" -Xmx7g  -XX:ParallelGCThreads=1 -jar /users/k1470436/bin/picard.jar SortSam SORT_ORDER=coordinate INPUT=$prefix1.bam OUTPUT=$prefix1.sort.bam\n";
print OUT "/users/k1470436/bin/jdk1.8.0_66/bin/java -cp \"/users/k1470436/bin/picard/dist/htsjdk_lib_dir/*.jar;/users/k1470436/bin/picard/htsjdk/dist/*.jar\" -Xmx7g  -XX:ParallelGCThreads=1 -jar /users/k1470436/bin/picard.jar CollectMultipleMetrics INPUT=$prefix1.sort.bam REFERENCE_SEQUENCE=$masterspace/MASTER.fa OUTPUT=$cwd/$prefix1.sort.PMM PROGRAM=CollectGcBiasMetrics\n";

print OUT "samtools flagstat $prefix1.sort.bam > $prefix1.flagstat\n";

print OUT "/users/k1470436/bin/jdk1.8.0_66/bin/java -cp \"/users/k1470436/bin/picard/dist/htsjdk_lib_dir/*.jar;/users/k1470436/bin/picard/htsjdk/dist/*.jar\" -Xmx7g  -XX:ParallelGCThreads=1 -jar /users/k1470436/bin/picard.jar CollectRnaSeqMetrics INPUT=$prefix1.sort.bam REFERENCE_SEQUENCE=$masterspace/MASTER.fa OUTPUT=$cwd/$prefix1.sort.PMM RIBOSOMAL_INTERVALS=Picard.ribo.intervals STRAND_SPECIFICITY=FIRST_READ_TRANSCRIPTION_STRAND REF_FLAT=Picard.ref.flat MINIMUM_LENGTH=50 CHART=$prefix1.RnaSeqMetrics.pdf\n";


# Do full read length histogram

print "$prefix2\n\n";
if ($prefix2=~/^0$/) {
print  "qsub -l h_vmem=5G -b y  -V -cwd  -N qc1$prefix1 bash $prefix1.F.qc.sh1\n";
print  "qsub -l h_vmem=5G -b y  -V -cwd  -N qc2$prefix1 bash $prefix1.F.qc.sh2\n";

print "SE\n";
}
else {
# submit jobs
print  "qsub -l h_vmem=5G -b y  -V -cwd  -N qc1$prefix1 bash $prefix1.F.qc.sh1\n";
print  "qsub -l h_vmem=5G -b y  -V -cwd  -N qc2$prefix1 bash $prefix1.F.qc.sh2\n";
print  "qsub -l h_vmem=15G -b y  -V -cwd  -N qc3$prefix2 bash $prefix2.R.qc.sh2\n";

#print "PE\n";
}


print OUT "gzip $prefix1.notCombined_1.fastq\n";
print OUT "gzip $prefix2.notCombined_2.fastq\n";
print OUT "gzip $prefix1.extendedFrags.fastq\n";


# Make a summary-file of all data


print OUT "perl /users/k1470436/bin/perl/species.pl $prefix1.species > $prefix1.spec\n";
print OUT "perl /users/k1470436/bin/perl/qc_premapping.pl $in1 $in2\n";


# cleanup

print OUT "mkdir $prefix1.QC\n";
print OUT "mkdir $prefix1.QC/old\n";
print OUT "mv $start1[0]\*.F.qc.fq.gz $prefix1.QC\n";
print OUT "mv $start2[0]\*.R.qc.fq.gz $prefix1.QC\n";
print OUT "mv $prefix1\*PMM* $prefix1.QC\n";
print OUT "mv $prefix1\*spec* $prefix1.QC\n";
print OUT "mv $prefix1\*sort.bam $prefix1.QC\n";
print OUT "mv $prefix1\*ie $prefix1.QC\n";
print OUT "mv $start1[0]\*len $prefix1.QC\n";
print OUT "mv $start1[0]\*parsed $prefix1.QC\n";
print OUT "mv $start2[0]\*.R.FQC $prefix1.QC\n";
print OUT "mv $start1[0]\*.F.FQC $prefix1.QC\n";
print OUT "mv $prefix1.flagstat $prefix1.QC\n";
print OUT "mv $prefix1.fc.summary $prefix1.QC\n";
print OUT "mv $prefix1.fc.res $prefix1.QC\n";
print OUT "mv $prefix1.flash.log $prefix1.QC\n";
print OUT "rm -f  $prefix1\*.bam\n";
print OUT "mv $prefix1\*extendedFrags.fastq.gz $prefix1.QC/old\n";
print OUT "mv $prefix1\*notCombined_1.fastq.gz $prefix1.QC/old\n";
print OUT "mv $prefix2\*notCombined_2.fastq.gz $prefix1.QC/old\n";
#print OUT "mv $start1[0]\*notCombined_2.fastq.gz $prefix1.QC/old\n";
print OUT "mv $prefix2\*.R.sub1000000.fq.gz $prefix1.QC/old\n";
print OUT "mv $prefix1\*.F.sub1000000.fq.gz $prefix1.QC/old\n";
print OUT "mv $prefix1\*unc.1.gz $prefix1.QC/old\n";
print OUT "mv $prefix1\*unc.2.gz $prefix1.QC/old\n";
print OUT "mv $prefix1\*hist $prefix1.QC/old\n";
print OUT "gzip $prefix1.QC/*.*\n";
print OUT "gunzip $prefix1.QC/*.bam\n";
print OUT "gzip $prefix1.QC/old/*.*\n";
print OUT "rm -f $prefix1\*histogram\n";
print OUT "rm -f $prefix1\*fc\n";





