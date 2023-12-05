#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV >1 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: make_MASTER.pl <PREFIX> <REF> <optional extras>


This script makes a shell script which it submits as a job.
It gathers the reference genomes, and any extra sequences youd like to add (they have to be gz)
It then does a bowtie2 and faidx index of the concatenated file

REF -  several possible options; (H)uman, (M)ouse, (A)ll and (N)one (just does the extras)

optional extras - any more genes or genomic modifications introduced



' . "\n";

}

# Get the files right 
my $prefix=shift;
my $ref=shift;
my @extras;

if (@ARGV>0) {
	@extras=@ARGV;
}
else {
	push(@extras,"");
}


open (OUT, ">$prefix.makemaster.sh") || die "I can't open $prefix.makemaster.sh\n";

if ($ref=~/^A/) {

	print OUT "zcat @extras ~/scratch/REFERENCES/Human/hg38.MASTER.gz ~/scratch/REFERENCES/Mouse/mm10.MASTER.gz > $prefix.raw\n";
}
elsif ($ref=~/^M/) {
	print OUT "zcat @extras ~/scratch/REFERENCES/Mouse/mm10.MASTER.gz > $prefix.raw\n";
}
elsif ($ref=~/^N/) {
	print OUT "zcat @extras > $prefix.raw\n";
}
elsif ($ref=~/^H/) {
	print OUT "zcat @extras ~/scratch/REFERENCES/Human/hg38.MASTER.gz > $prefix.raw\n";
}
else {
	print "I dont undersand which reference you want, what is this?  $ref\n";
	die;
}


print OUT "perl ~/bin/perl/fasta2multiline.pl 1000 $prefix.raw\n";
print OUT "perl ~/bin/perl/fasta2multiline.pl s $prefix.raw\n";

print OUT "mv $prefix.raw.mul.1000 $prefix.fa\n";
print OUT "bowtie2-build $prefix.fa $prefix.fa\n";
print OUT "ln -s $prefix.fa $prefix.fa.fa\n";
print OUT "samtools faidx $prefix.fa\n";


print "Submit job with:\n\nqsub  -l h_vmem=5G -b y  -V -cwd  -N $prefix bash  $prefix.makemaster.sh\n\n";

exit;






