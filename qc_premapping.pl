#!/usr/bin/perl -w

use strict;
use Cwd;
use Carp;

unless (@ARGV > 0 ) {
        &USAGE;
}


sub USAGE {

    die '


perl ~/bin/perl/qc_premapping.pl   <1.fastq.gz> (2.fastq.gz)
 

This pipeline collects the results for the qc_pipeline.pl and makes it into a suggested mapping

It also gathers statistics 



Usage: qc#_mapping.pl trim-start mate-dist  <reference genome> gff file.fastq (file2.fastq) 

' . "\n";

}


# Figure out which files to run on


# If only one file
my $in1=shift;
my @inh1 = split(/\//, $in1);
my $inh1 = $inh1[-1];
my @start1 = split(/_/, $inh1[-1]);
my $prefix1 = $start1[0] . "_" . $start1[1];
#print "\n$in1 $inh1 $prefix1\n";

# if two files
my $prefix2=0;
my $in2=0;
my $inh2=0;

if (@ARGV==1) {
	$in2=shift;
	my @inh2 = split(/\//, $in2);
	$inh2 = $inh2[-1];
	my @start2 = split(/_/, $inh2[-1]);
	$prefix2 = $start2[0] . "_" . $start2[1];
	#print "\n$in2 $inh2 $prefix2\n";
}


if ($in2=~/^0$/) {
	print "Data is SE\n";
}
else {
	print "Data is PE\n";
}

open (O, ">$prefix1.diagnosis") || carp "I can't open $prefix1.diagnosis\n";

## Check reference genome and GFF

# check species

#print "ls $prefix\_1.fastq.gz.species\n";
 
open (SP, "<$prefix1.spec") || carp "I can't open $prefix1.spec\n";

#my $genome="/users/k1470436/scratch/REFERENCES/";
my $genome="/mnt/scratch/DCT/BIOINFCO/mzarowiecki/REFERENCES/";


#print "Genome\t~/scratch/REFERENCES/";

foreach my $line (<SP> ) {
	chomp $line;
	#print "$line\n";
	my @arr=split(/\t/,$line);
	#print "$arr[2]" .".";
	chomp $arr[2];
	$genome = $genome .  "$arr[2]" . "." ;
}

my($species,$virus,$gene)=split(/\./, $genome);
my @spec = split(/\//, $species);
#print "fa\n";
#$genome=$genome . "fa";

unless (defined $gene) {
	$gene=" ";
}

#print "\n$genome\n\n";

# Check if that genome exists

unless (-f $genome) {
	print "\nYour desired genome does not exist, this is a suggestion:\nperl ~/bin/perl/make_qc_MASTER.pl $spec[5] $virus $gene\n\n\n";
}


## Check chomping

#print "perl  ~/bin/perl/fastqc_parser.pl $prefix\_1 $prefix\_1.fastq.gz.FQC/fastqc_data.txt.gz\n";
#print "perl  ~/bin/perl/fastqc_parser.pl $prefix\_2 $prefix\_2.fastq.gz.FQC/fastqc_data.txt.gz\n";
#print "$prefix1.F.parsed";
#print "$prefix1.F.parsed";
my $parse1 = `cat $prefix1.F.parsed | cut -f2 `;
my $parse2 = `cat $prefix2.R.parsed | cut -f2 `;
chomp $parse1;
chomp $parse2;
#print "TH\n$parse1\n$parse2\n\n";


#__END__

## Check matedist 


my @ins = `cat $prefix1.sort.PMM.insert_size_metrics | grep -A 1 MEAN_INSERT_SIZE | cut -f1,2,5,6,8`;


#print "@ins\n";

my ($meins,$mestd,$mins,$mstd,$ori2)= split(/\t/, $ins[1]);

#print "Median ins $meins\n";
#print "Median std $mestd\n";
#print "Mean ins $mins\n";
#print "Mean std $mstd\n";
#print "ORI $ori\n";

## Check read orientation

my $ori=0;

my @rexp;

open (IE, "<$prefix1.ie") || die "I can't open $prefix1.ie\n";
foreach my $line (<IE>) {
	if ($line =~/explained/) {
		chomp $line;
		my @a=split(/:/, $line);
		#print "$line     $a[1]\n";
		push(@rexp, $a[1]);
	}
}

my $libt="UNKNOWN";

#print "\nSort orientation\n";
# unstranded paired
if ($rexp[0]=~/0.4/ and $rexp[1]=~/0.4/) {
	#print "$rexp[0] $rexp[1] fr-unstranded\n";
	$libt="fr-unstranded";
}
# unstranded single

# stranded single

# stranded paired secondstrand
elsif ($rexp[0]=~/0\.9/ ) {
	#print "$rexp[0] $rexp[1] fr-secondstrand\n";
	$libt="fr-secondstrand";
}
# stranded paired firststrand
elsif ($rexp[1]=~/0\.9/ ) {
	#print "$rexp[0] $rexp[1] fr-firststrand\n";
	$libt="fr-firststrand";
}
# else
else {
	print "ELSE $rexp[0] $rexp[1]\n";
}


#print "\n\n";

#print "perl /users/k1470436/bin/perl/qc_mapping.pl trim-start1  (trim-start2 mate-dist mate-dev) library-type  <reference genome> gff file.fastq (file2.fastq)\n";
print "perl ~/bin/perl/qc_mapping.pl $parse1  $parse2 $meins $mestd  $libt $genome" ."fa $genome" ."gff.fc.ref $in1 $in2\n\n";

print O "Prefix\tTrim-start1\tTrim-start2\tmate-dist\tmate-dev\tlibrary-type\tgenome".".fa\n";
print O "$prefix1\t$parse1\t$parse2\t$meins\t$mestd\t$libt\t$genome\ fa\t$genome\ gff.fc.ref\t$in1\t$in2\n";
# --library-type  (fr-unstranded, fr-firststrand, fr-secondstrand)


__END__




