#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV == 5 or @ARGV == 9 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: qc_mapping.pl trim-start1  (trim-start2 mate-dist mate-dev) library-type  <reference genome> gff file.fastq (file2.fastq)


This pipeline makes a shell script which it submits as a job.
It gathers statistics and does a Tophat2 mapping to genome

If two files are given they are assumed to be PE reads

' . "\n";

}

# Get the files right 

my $cwd = cwd();
my $ts1=shift; 
my $ts2=shift;
my $matedist=shift;
 my $matedev=shift;
my $lib = shift; # --library-type  (fr-unstranded, fr-firststrand, fr-secondstrand)
my $ref=shift;
my $gff = shift;
my $in=shift; 


if ($ts1<1) {
	$ts1=1;
}
if ($ts2<1) {
	$ts2=1;
}


# if two files
my $in1;
my $in2;
$in1=$in;

if (@ARGV==0) {
	$in2 = "SINGLE";
	print "Single infile\n$in\n\n";
}
else {
	$in1 = $in;
	$in2 = shift;
	print "Two infiles\n$in1\n$in2\n\n";
}

my $prefix = $in;
my @arr1= split(/\//, $prefix);
my @arr= split(/_/, $arr1[-1]);
$prefix="$arr[0]" . "_" . "$arr[1]";
#$prefix="$arr[0]";
#my $prefix2 = $in2;
$prefix=~s/.fastq.gz//;


open (OUT, ">$prefix.mapping.sh") || die "I can't open $in.mapping.sh\n";

print OUT "ln -s $in1 $prefix.F.fq.gz\n";
print OUT "ln -s $in2 $prefix.R.fq.gz\n\n";
## Now get the required info for mapping


# do appropriate trimming

# trim adapter7_Het.TRIM
# trim first 4 bases

my $trimout = $cwd . "/" . "$prefix" . ".TRIM";
if (-e $trimout) {
	print "Folder $trimout already exists!\n\n";
}
else {
	print OUT "mkdir $trimout\n\n";
}
#system "touch $in\_trimming_report.txt";

if ($in2=~/SINGLE/) {
	print OUT "trim_galore -q 25 --stringency 3 --illumina --gzip -o $trimout --clip_R1 $ts1 $prefix.F.fq.gz\n\n"; 
	print OUT "date\n";
}


else {
print OUT "trim_galore --paired -q 25 --stringency 3 --illumina --gzip --retain_unpaired -o $trimout --clip_R1 $ts1 --clip_R2 $ts2 $prefix.F.fq.gz $prefix.R.fq.gz\n\n"; 
print OUT "date\n";
print OUT "ln -s $trimout/$prefix.F\_unpaired_1.fq.gz\n";
print OUT "ln -s $trimout/$prefix.R\_unpaired_2.fq.gz\n\n";

# Do overlaps
print OUT "flash -m 5 -M 140 -O -o $prefix.OVL -z -t 1 $trimout/$prefix.F\_val_1.fq.gz $trimout/$prefix.R\_val_2.fq.gz\n\n";



}

print OUT "[ -f  $trimout/$prefix.F\_val_1.fq.gz ] || exit 1\n\n";

print OUT "rm -f $prefix*outie  $prefix*innie \n\n";





# which genome

print OUT "echo \"# Check reference\"\n";

if (-s "$ref") {
	print OUT "echo \"Reference exists\"\n";
}
else {
	print OUT "echo \"Reference $ref does not exist\"\n";
	die "Reference $ref does not exist\n";
}
if (-s "$ref.fai") {
	print OUT "#Fasta index exists\n\n";
}

# check if there is an index - or do it
else {
	print OUT "samtools faidx $ref\n";
	print OUT "bowtie2-build $ref $ref\n\n";
}


my $fol = $cwd ."/"."$prefix". ".TH2";

## Now do mapping
## Map those reads to human, mouse and fusion proteins

# Make genome
print OUT "date\n";
print OUT "echo \"Start mapping\"\n\n";

print OUT "source activate py2.7\n";

# Make mapping job 
if ($in2=~/SINGLE/) {
#	print OUT "bowtie2  -p 1 --un-gz $prefix.un.gz -x $ref -U $prefix. \n";
	print OUT "tophat2 --library-type $lib -p 20 --un-gz $prefix.un.gz -i 30 -o  $prefix.TH2s $ref $prefix.NNNNN\n";
	print OUT "date\n";
#print OUT "samtools view -Sb $in1.sam > $in1.bam\n";
#print OUT "rm -f $in1.sam\n";


}

else {

# Do single jobs for unmapped
#	print OUT "bowtie2  -p 1 --un-gz $prefix.un.gz -x $ref -U $prefix.OVL.extendedFrags.fastq.gz,$prefix\_unpaired_1.fq.gz,$prefix\_unpaired_2.fq.gz -S $in1.sam \n";
	print OUT "tophat2 --library-type $lib -p 20 -i 30 -o $prefix.TH2s $ref $prefix.OVL.extendedFrags.fastq.gz,$prefix.F\_unpaired_1.fq.gz,$prefix.R\_unpaired_2.fq.gz  \n";
	print OUT "date\n";
#	print OUT "samtools view -Sb $in1.sam > $in1.bam\n";
#	print OUT "rm -f $in1.sam\n";

# Do paired for mapped
#	print OUT "bowtie2  -p 1 --fr --un-conc-gz $prefix.unc.gz  -x $ref -1 $prefix.OVL.notCombined_1.fastq.gz -2 $prefix.OVL.notCombined_2.fastq.gz -S $prefix.sam\n";
	print OUT "tophat2 --library-type $lib -p 20 -r $matedist --mate-std-dev $matedev -i 30 -o $prefix.TH2p $ref $prefix.OVL.notCombined_1.fastq.gz $prefix.OVL.notCombined_2.fastq.gz \n";
	print OUT "date\n";
#	print OUT "samtools view -Sb $prefix.sam > $prefix.bam\n";
#	print OUT "rm -f $prefix.sam\n";
	print OUT "ln -s $prefix.TH2p/accepted_hits.bam $prefix.TH2p.bam\n";
}

print OUT "[ -f  $prefix.TH2s/accepted_hits.bam ] || exit 1\n\n";


print OUT "ln -s $prefix.TH2s/accepted_hits.bam $prefix.TH2s.bam\n\n";

print OUT "date\n";
print OUT "echo \"Mapping finished\"\n\n";
print OUT "date\n";


print OUT "echo \"Do read counts\"\n\n";

print OUT "source deactivate\n";

my $fcori = 0;
if ($lib=~/fr-secondstrand/) { #  (fr-unstranded, fr-firststrand, fr-secondstrand)
	$fcori = 1;
}
elsif ($lib=~/fr-firststrand/) {
	$fcori = 2;
}
else {
}


# Filter reads for quality and # Do read counts
if ($in2=~/SINGLE/) {
	print OUT "samtools view -h -q30 -b -o $prefix.TH2s.Q30.bam $prefix.TH2s.bam \n";
	print OUT "featureCounts -s $fcori --largestOverlap --minOverlap 10 --primary -C  -a $gff  -o $prefix.counts $prefix.TH2s.Q30.bam\n\n";
}

else {

	print OUT "samtools view -h -q30 -b -o $prefix.TH2s.Q30.bam $prefix.TH2s.bam \n";
	print OUT "samtools view -h -q30 -b -o $prefix.TH2p.Q30.bam $prefix.TH2p.bam \n\n";
	#print OUT "samtools sort -n $prefix.TH2p.Q30.bam $prefix.TH2p.Q30.n\n";
	print OUT "featureCounts -s $fcori --largestOverlap --minOverlap 10 --primary -C  -a $gff  -o $prefix.counts $prefix.TH2s.Q30.bam\n";
	print OUT "featureCounts -s $fcori --largestOverlap --minOverlap 10 --primary -C -p -a $gff  -o $prefix.countp $prefix.TH2p.Q30.bam\n\n";
}

print OUT "[ -f  $prefix.counts ] || exit 1\n\n";

# Merge read counts


print OUT "perl ~/bin/perl/qc_counting.pl $prefix.countp $prefix.counts\n";


############################################

# Check quality of mapped reads Q30
 

#print OUT "source activate py2.7\n";
#print OUT "python /users/k1470436/bin/RSeQC-2.6.3/scripts/bam2fq.py -i  $prefix.TH2p.Q30.bam -o $prefix.TH2p.Q30\n";
#print OUT "source deactivate\n";
print OUT "bedtools bamtofastq -i $prefix.TH2p.Q30.bam -fq $prefix.TH2p.Q30_1.fq -fq2 $prefix.TH2p.Q30_2.fq \n";
print OUT "bedtools bamtofastq -i $prefix.TH2s.Q30.bam -fq $prefix.TH2s.Q30.fq\n";
print OUT "mkdir $prefix.TH2p.Q30.FQC\n";
print OUT "mkdir $prefix.TH2s.Q30.FQC\n";
print OUT "fastqc --extract --o  $prefix.TH2p.Q30.FQC $prefix.TH2p.Q30_1.fq $prefix.TH2p.Q30_2.fq\n";
print OUT "fastqc --extract --o  $prefix.TH2s.Q30.FQC $prefix.TH2s.Q30.fq\n";
print OUT "gzip $prefix.TH2p.Q30_1.fq $prefix.TH2p.Q30_2.fq $prefix.TH2s.Q30.fq\n";

##########################################


# Clean up ###
print OUT "\n## cleanup ##\n\n";
print OUT "mkdir $prefix\n";
print OUT "mkdir $prefix/nonessential\n";
print OUT "mv $prefix.countp.count $prefix\n";
print OUT "mv $prefix.OVL.hist $prefix/nonessential\n";
print OUT "mv $prefix.OVL.histogram $prefix/nonessential\n";

print OUT "mv $prefix.OVL.notCombined_1.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.OVL.notCombined_2.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.OVL.extendedFrags.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.F.unpaired_1.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.R.unpaired_2.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TH2p.Q30_1.fq.gz $prefix/nonessential\n";
print OUT "mv  $prefix.TH2p.Q30_2.fq.gz $prefix/nonessential\n"; 
print OUT "mv $prefix.TH2s.Q30.fq.gz $prefix/nonessential\n";

print OUT "mv $prefix.TH2s.Q30.bam $prefix/nonessential\n";
print OUT "mv $prefix.TH2p.Q30.bam $prefix/nonessential\n";
print OUT "rm -f $prefix.TH2p.Q30.n.bam\n";
print OUT "mv $prefix.TH2s/accepted_hits.bam $prefix/nonessential/$prefix.TH2s.bam\n";
print OUT "mv $prefix.TH2p/accepted_hits.bam $prefix/nonessential/$prefix.TH2p.bam\n";
print OUT "mv $prefix.TH2s/unmapped.bam $prefix/nonessential/$prefix.TH2s.unmapped.bam\n";
print OUT "mv $prefix.TH2p/unmapped.bam $prefix/nonessential/$prefix.TH2p.unmapped.bam\n";
print OUT "mv $prefix.TH2s/align_summary.txt $prefix/nonessential/$prefix.TH2s.align_summary.txt\n";
print OUT "mv $prefix.TH2p/align_summary.txt $prefix/nonessential/$prefix.TH2p.align_summary.txt\n";

print OUT "rm -fr $prefix.TRIM $prefix.TH2s $prefix.TH2p\n";
print OUT "rm -f $prefix.*.summary\n";
print OUT "rm -f $prefix.F.fq.gz $prefix.R.fq.gz\n";
print OUT "rm -f $prefix.TH2s.bam $prefix.TH2p.bam\n";
print OUT "mv $prefix.counts $prefix/nonessential\n";
print OUT "mv $prefix.countp $prefix/nonessential\n";

print OUT "mv  $prefix.TH2p.Q30.FQC/*.html $prefix/nonessential\n";
print OUT "mv  $prefix.TH2s.Q30.FQC/*.html $prefix/nonessential\n";
print OUT "mv  $prefix.TH2p.Q30.FQC/$prefix.TH2p.Q30_2.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.p2.fastqc_data.txt\n";
print OUT "mv  $prefix.TH2p.Q30.FQC/$prefix.TH2p.Q30_1.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.p1.fastqc_data.txt\n";
print OUT "mv  $prefix.TH2s.Q30.FQC/$prefix.TH2s.Q30.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.s.fastqc_data.txt\n";
print OUT "rm -fr $prefix.TH2p.Q30.FQC  $prefix.TH2s.Q30.FQC\n";
print OUT "gzip $prefix/nonessential/*.txt\n";
print OUT "gzip $prefix/nonessential/*.hist*\n";
print OUT "gzip $prefix/nonessential/*.count?\n";
print OUT "gzip $prefix/nonessential/*.html\n";

print "Submit job with:\n\nqsub  -l h_vmem=10G -pe mpislots 20 -b y  -V -cwd  -N $prefix bash $prefix.mapping.sh \n\n";

print OUT "date\n";
print OUT "echo \"Finished no errors\"\n\n";






exit;




