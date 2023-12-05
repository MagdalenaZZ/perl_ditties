#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV == 5 or @ARGV == 6 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: qcb_pipeline.pl trim-start mate-dist gff <reference genome> file.fastq (file2.fastq)


This pipeline makes a shell script which it submits as a job.
It gathers statistics, cleans up the data and does a Bismark mapping to the reference genome

If two files are given they are assumed to be PE reads

' . "\n";

}

# Get the files right

my $cwd = cwd();
my $ts1=shift;
#my $te1= shift;
#my $ts2=shift;
my $matedist=shift;
my $gff = shift;
my $ref=shift;
my $in=shift;

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
my @arr= split(/_/, $prefix);
#$prefix="$arr[0]" . "_" . "$arr[1]";
$prefix="$arr[0]";
#my $prefix2 = $in2;
#$prefix2=~s/.fastq.gz//;


open (OUT, ">$prefix.mapping.sh") || die "I can't open $in.mapping.sh\n";

print OUT "ln -s $in1 $prefix.F.fq.gz\n";
print OUT "ln -s $in2 $prefix.R.fq.gz\n\n";
## Now get the required info for mapping


# do appropriate trimming

# trim adapter
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
print OUT "trim_galore --paired -q 25 --stringency 3 --gzip --retain_unpaired -o $trimout --clip_R1 $ts1 --clip_R2 $ts1 $prefix.F.fq.gz $prefix.R.fq.gz\n\n";
print OUT "date\n";
print OUT "ln -s $trimout/$prefix.F\_unpaired_1.fq.gz\n";
print OUT "ln -s $trimout/$prefix.R\_unpaired_2.fq.gz\n\n";

# Do overlaps
print OUT "flash -m 5 -M 140 -O -o $prefix.OVL -z -t 1 $trimout/$prefix.F\_val_1.fq.gz $trimout/$prefix.R\_val_2.fq.gz\n\n";



}

print OUT "rm -f $prefix*outie  $prefix*innie \n\n";





# which genome

print OUT "echo \"# Check reference\"\n";

if (-d "$ref") {
	print OUT "echo \"Reference exists\"\n";
}
else {
	print OUT "echo \"Reference $ref does not exist Build it using ~/bin/bismark_genome_preparation $ref\"\n";
	die;
}



my $fol = $cwd ."/"."$prefix". ".BS";

## Now do mapping
## Map those reads to human, mouse and fusion proteins

# Make genome
print OUT "date\n";
print OUT "echo \"Start mapping\"\n\n";

# Make mapping job
if ($in2=~/SINGLE/) {
	print OUT "bowtie2  -p 1 --un-gz $prefix.un.gz -x $ref -U $prefix. \n";
	#print OUT "tophat2  -p 8 --un-gz $prefix.un.gz -i 30 -o  $prefix.TH2s $ref $prefix.NNNNN\n";
	print OUT "date\n";
#print OUT "samtools view -Sb $in1.sam > $in1.bam\n";
#print OUT "rm -f $in1.sam\n";


}

else {

# Do paired and single 
	print OUT " bismark -n 1  $ref -1 $prefix.OVL.notCombined_1.fastq.gz -2 $prefix.OVL.notCombined_2.fastq.gz $prefix.OVL.extendedFrags.fastq.gz,$prefix.F\_unpaired_1.fq.gz,$prefix.R\_unpaired_2.fq.gz\n";
#	print OUT "tophat2  -p 8 -i 30 -o $prefix.TH2s $ref $prefix.OVL.extendedFrags.fastq.gz $prefix.F\_unpaired_1.fq.gz $prefix.R\_unpaired_2.fq.gz  \n";
	print OUT "date\n";
#	print OUT "samtools view -Sb $in1.sam > $in1.bam\n";
#	print OUT "rm -f $in1.sam\n";

# Do paired for mapped
#	print OUT "bowtie2  -p 1 --fr --un-conc-gz $prefix.unc.gz  -x $ref -1 $prefix.OVL.notCombined_1.fastq.gz -2 $prefix.OVL.notCombined_2.fastq.gz -S $prefix.sam\n";
#	print OUT "tophat2  -p 8 -r $matedist -i 30 -o $prefix.TH2p $ref $prefix.OVL.notCombined_1.fastq.gz $prefix.OVL.notCombined_2.fastq.gz \n";
#	print OUT "date\n";
#	print OUT "samtools view -Sb $prefix.sam > $prefix.bam\n";
#	print OUT "rm -f $prefix.sam\n";
#	print OUT "ln -s $prefix.TH2p/accepted_hits.bam $prefix.TH2p.bam\n";
}

#print OUT "ln -s $prefix.TH2s/accepted_hits.bam $prefix.TH2s.bam\n\n";
print OUT "date\n";
print OUT "echo \"Mapping finished\"\n\n";
print OUT "date\n";
print OUT "echo \"Do read counts\"\n\n";

=pod
# Filter reads for quality and # Do read counts
if ($in2=~/SINGLE/) {
	print OUT "samtools view -S -h -q30 -b -o $prefix.TH2s.Q30.bam  $in1.sam\n";
	print OUT "featureCounts -s 1 --largestOverlap --minOverlap 10 --primary -C  -a gff  -o $prefix.counts $prefix.TH2s.Q30.bam\n\n";
}

else {

	print OUT "samtools view -h -q30 -bS -o $prefix.TH2s.Q30.bam $in1.sam \n";
	print OUT "samtools view -h -q30 -bS -o $prefix.TH2p.Q30.bam $prefix.sam \n\n";
	print OUT "samtools sort -n $prefix.TH2p.Q30.bam $prefix.TH2p.Q30.n\n";
	print OUT "featureCounts -s 1 --largestOverlap --minOverlap 10 --primary -C  -a $gff  -o $prefix.counts $prefix.TH2s.Q30.n.bam\n";
	print OUT "featureCounts -s 1 --largestOverlap --minOverlap 10 --primary -C -p -a $gff  -o $prefix.countp $prefix.TH2p.Q30.bam\n\n";
}

# Merge read counts


print OUT "perl /isilon_home/mzarowieckibrc/bin/perl/qc_counting.pl $prefix.countp $prefix.counts\n";




=cut


# extract methylated sites
# multicore * 3 equals real number of used cores
print OUT "bismark_methylation_extractor --genome_folder $ref/*.fa --comprehensive --gzip --multicore 4 --include_overlap --ignore 0 --ignore_r2 0 --ignore_3prime 0 --ignore_3prime_r2 0  -p $prefix.OVL.notCombined_1.fastq.gz_bismark_pe.bam -s ####\n";

print OUT "bismark2bedGraph -o $prefix.bedGraph   CpG_context_$prefix.OVL.notCombined_1.fastq.gz_bismark_pe.txt.gz\n";


print "Submit job with:\n\nqsub  -l h_vmem=10G  -pe mpislots 12 -b y  -V -cwd  -N $prefix bash $prefix.mapping.sh \n\n";

print OUT "date\n";

print OUT "echo \"Finished no errors\"\n\n";


print OUT "echo \"The files you need for R-BiSeq are $prefix.bedGraph and $prefix.bismark.cov\"\n\n";


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
print OUT "rm -f $in1.sam  $prefix.sam\n";
print OUT "mv $prefix.counts $prefix/nonessential\n";
print OUT "mv $prefix.countp $prefix/nonessential\n";







exit;

