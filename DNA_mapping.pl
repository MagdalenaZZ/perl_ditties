#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV > 5 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: DNA_mapping.pl mapper trim-start1 trim-start2  <reference genome> gff file.fastq (file2.fastq)


This pipeline makes a shell script which it submits as a job.
It gathers statistics and does a DNA mapping to genome

If two files are given they are assumed to be PE reads



' . "\n";

}

#Library type;  
#--fr/--rf/--ff: -1, -2 mates align fw/rev, rev/fw, fw/fw (default: --fr)


# Get the files right 

my $cwd = cwd();
my $mapper=shift; 
my $ts1=shift; 
my $ts2=shift;
#my $matedist=shift;
# my $matedev=shift;
#my $lib = shift; # --library-type  (fr-unstranded, fr-firststrand, fr-secondstrand)
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
print OUT "ln -s $trimout/$prefix.R\_unpaired_2.fq.gz\n";
print OUT "ln -s $trimout/$prefix.F\_val_1.fq.gz\n";
print OUT "ln -s $trimout/$prefix.R\_val_2.fq.gz\n";
# Do overlaps
#print OUT "flash -m 5 -M 140 -O -o $prefix.OVL -z -t 1 $trimout/$prefix.F\_val_1.fq.gz $trimout/$prefix.R\_val_2.fq.gz\n\n";



}

#print OUT "[ -f  $trimout/$prefix.F\_val_1.fq.gz ] || exit 1\n\n";

#print OUT "rm -f $prefix*outie  $prefix*innie \n\n";





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

# not yet implemented	


}

else {

	if ($mapper=~/bowtie2/) {


# Do single jobs for unmapped

	#print OUT "bowtie --best -m 50 -p 8 $ref $prefix.OVL.extendedFrags.fastq.gz,$prefix.F\_unpaired_1.fq.gz,$prefix.R\_unpaired_2.fq.gz $prefix.TH2s.sam\n";
	print OUT "date\n";

	print OUT "bowtie2  -p 8 --un-gz $prefix.un.SE.gz -x $ref -U $prefix.F\_unpaired_1.fq.gz,$prefix.R\_unpaired_2.fq.gz -S $prefix.TH2s.sam\n";
	#print OUT "bowtie2  -p 8 --un-gz $prefix.un.SE.gz -x $ref -U $prefix.OVL.extendedFrags.fastq.gz,$prefix\_unpaired_1.fq.gz,$prefix\_unpaired_2.fq.gz -S $prefix.TH2s.sam\n";
#	print OUT "tophat2 --library-type $lib -p 8 -i 30 -o $prefix.TH2s $ref $prefix.OVL.extendedFrags.fastq.gz,$prefix.F\_unpaired_1.fq.gz,$prefix.R\_unpaired_2.fq.gz  \n";
	print OUT "samtools view -Sb $prefix.TH2s.sam > $prefix.TH2s.bam\n";
	print OUT "rm -f $prefix.TH2s.sam\n";

# Do paired for mapped
	print OUT "bowtie2  -p 8 --fr --un-gz $prefix.un.PE.gz -x $ref -1 $prefix.F\_val_1.fq.gz -2 $prefix.R\_val_2.fq.gz -S $prefix.TH2p.sam\n";
	#print OUT "bowtie2  -p 8 --fr --un-gz $prefix.un.PE.gz -x $ref -1 $prefix.OVL.notCombined_1.fastq.gz -2 $prefix.OVL.notCombined_2.fastq.gz -S $prefix.TH2p.sam\n";
	#print OUT "bowtie --best -X 3000 --fr -m 50 -p 8 $ref -1 $prefix.OVL.notCombined_1.fastq.gz -2 $prefix.OVL.notCombined_2.fastq.gz $prefix.TH2p.sam\n";
	print OUT "date\n";
	print OUT "samtools view -Sb $prefix.TH2p.sam > $prefix.TH2p.bam\n";
	print OUT "rm -f $prefix.TH2p.sam\n";
	#print OUT "ln -s $prefix.TH2p/accepted_hits.bam $prefix.TH2p.bam\n";
	}
	elsif ($mapper=~/bowtie/) {
	}
	elsif ($mapper=~/bwa/) {
	
		# bwa with -t <8 threads> 
			
		print "bwa mem -t 8 -T 0  $ref $prefix.F\_val_1.fq.gz $prefix.R\_val_2.fq.gz > $prefix.bwa.sam\n";	
		print "samtools view -Sb $prefix.bwa.sam > $prefix.bwa.bam\n";	
		print "rm -f $prefix.bwa.sam\n";

	}
	elsif ($mapper=~/meme/) {
	}
	else {
	
		print "\nValid names for mapper is bowtie, bowtie2, meme, bwa, you said: $mapper\n\n";
	}

}


# test if mapped file exists or die
print OUT "[ -f  $prefix.TH2s.bam ] || exit 1\n\n";




#print OUT "ln -s $prefix.TH2s/accepted_hits.bam $prefix.TH2s.bam\n\n";

print OUT "date\n";
print OUT "echo \"Mapping finished\"\n\n";
print OUT "date\n";


# Do filtering

print "module add java/sun8/1.8.0u66; module add picard-tools/2.8.1; \n";
# picard
# MarkDuplicates
 print "INPUT=X.sorted.bam OUTPUT=X.paired.bam.sorted.rmdup.bam_tmp.bam METRICS_FILE=$gpcf/analysis/WES/I084_006_1M1_D1/alignment/X_paired.bam.sorted.rmdup_metrics.txt REMOVE_DUPLICATES=false ASSUME_SORTED=true TMP_DIR=$TMPDIR VALIDATION_STRINGENCY=SILENT COMPRESSION_LEVEL=0 PROGRAM_RECORD_ID=MarkDuplicates PROGRAM_GROUP_NAME=MarkDuplicates MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000 MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=8000 SORTING_COLLECTION_SIZE_RATIO=0.25 READ_NAME_REGEX=[a-zA-Z0-9]+:[0-9]:([0-9]+):([0-9]+):([0-9]+).* OPTICAL_DUPLICATE_PIXEL_DISTANCE=100 VERBOSITY=INFO QUIET=false MAX_RECORDS_IN_RAM=500000 CREATE_INDEX=false CREATE_MD5_FILE=false\n\n";




print OUT "echo \"Do read counts\"\n\n";
print OUT "source deactivate\n";



# Filter reads for quality and # Do read counts
if ($in2=~/SINGLE/) {
	print OUT "samtools view -h -q30 -b -o $prefix.TH2s.Q30.bam $prefix.TH2s.bam \n";
}
else {

	print OUT "samtools view -h -q30 -b -o $prefix.TH2s.Q30.bam $prefix.TH2s.bam \n";
	print OUT "samtools view -h -q30 -b -o $prefix.TH2p.Q30.bam $prefix.TH2p.bam \n\n";
	#print OUT "samtools sort -n $prefix.TH2p.Q30.bam $prefix.TH2p.Q30.n\n";
}

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
#print OUT "mv $prefix.countp.count $prefix\n";
#print OUT "mv $prefix.OVL.hist $prefix/nonessential\n";
#print OUT "mv $prefix.OVL.histogram $prefix/nonessential\n";

#print OUT "mv $prefix.OVL.notCombined_1.fastq.gz $prefix/nonessential\n";
#print OUT "mv $prefix.OVL.notCombined_2.fastq.gz $prefix/nonessential\n";
#print OUT "mv $prefix.OVL.extendedFrags.fastq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TRIM/$prefix.F\_unpaired_1.fq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TRIM/$prefix.R\_unpaired_2.fq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TRIM/$prefix.F\_val_1.fq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TRIM/$prefix.R\_val_2.fq.gz $prefix/nonessential\n";
print OUT "rm -f $prefix.F\_unpaired_1.fq.gz\n";
print OUT "rm -f $prefix.R\_unpaired_2.fq.gz\n";
print OUT "rm -f $prefix.F\_val_1.fq.gz\n";
print OUT "rm -f $prefix.R\_val_2.fq.gz\n";
print OUT "mv $prefix.TH2p.Q30_1.fq.gz $prefix/nonessential\n";
print OUT "mv $prefix.TH2p.Q30_2.fq.gz $prefix/nonessential\n"; 
print OUT "mv $prefix.TH2s.Q30.fq.gz $prefix/nonessential\n";

print OUT "mv $prefix.TH2s.Q30.bam $prefix/nonessential\n";
print OUT "mv $prefix.TH2p.Q30.bam $prefix/nonessential\n";
#print OUT "rm -f $prefix.TH2p.Q30.n.bam\n";
print OUT "mv $prefix.TH2p.bam $prefix/nonessential/\n";
print OUT "mv $prefix.TH2s.bam $prefix/nonessential/\n";
print OUT "mv $prefix\_1.fastq.gz $prefix/nonessential/\n";
print OUT "mv $prefix\_2.fastq.gz $prefix/nonessential/\n";
print OUT "mv $prefix.un.PE.gz $prefix/nonessential/\n";
print OUT "mv $prefix.un.SE.gz $prefix/nonessential/\n";
#print OUT "mv $prefix.TH2s/unmapped.bam $prefix/nonessential/$prefix.TH2s.unmapped.bam\n";
#print OUT "mv $prefix.TH2p/unmapped.bam $prefix/nonessential/$prefix.TH2p.unmapped.bam\n";
#print OUT "mv $prefix.TH2s/align_summary.txt $prefix/nonessential/$prefix.TH2s.align_summary.txt\n";
#print OUT "mv $prefix.TH2p/align_summary.txt $prefix/nonessential/$prefix.TH2p.align_summary.txt\n";

#print OUT "rm -fr $prefix.TRIM\n";
#print OUT "rm -f $prefix.*.summary\n";
print OUT "rm -f $prefix.F.fq.gz $prefix.R.fq.gz\n";
#print OUT "rm -f $prefix.TH2s.bam $prefix.TH2p.bam\n";
#print OUT "mv $prefix.counts $prefix/nonessential\n";
#print OUT "mv $prefix.countp $prefix/nonessential\n";

print OUT "mv  $prefix.TH2p.Q30.FQC/*.html $prefix/nonessential\n";
print OUT "mv  $prefix.TH2s.Q30.FQC/*.html $prefix/nonessential\n";
print OUT "mv  $prefix.TH2p.Q30.FQC/$prefix.TH2p.Q30_2.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.p2.fastqc_data.txt\n";
print OUT "mv  $prefix.TH2p.Q30.FQC/$prefix.TH2p.Q30_1.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.p1.fastqc_data.txt\n";
print OUT "mv  $prefix.TH2s.Q30.FQC/$prefix.TH2s.Q30.fq_fastqc/fastqc_data.txt $prefix/nonessential/$prefix.s.fastqc_data.txt\n";
print OUT "rm -fr $prefix.TH2p.Q30.FQC  $prefix.TH2s.Q30.FQC\n";
print OUT "gzip $prefix/nonessential/*.txt\n";
print OUT "gzip $prefix/nonessential/*.hist*\n";
#print OUT "gzip $prefix/nonessential/*.count?\n";
print OUT "gzip $prefix/nonessential/*.html\n";

print "Submit job with:\n\nqsub  -l h_vmem=10G -pe mpislots 8 -b y  -V -cwd  -N $prefix bash $prefix.mapping.sh \n\n";

print OUT "date\n";
print OUT "echo \"Finished no errors\"\n\n";






exit;




