#!/usr/local/bin/perl -w
# mz3 script 


use strict;
use File::Slurp;
use Cwd;
use Data::Dumper;

unless (@ARGV == 1 ) {
        &USAGE;
 }

 sub USAGE {

die 'Usage: fasta_N_position.pl file.fasta

Takes a fasta file and make a BED file indicating sections of Ns




'
}

my $prefix = shift;

open (IN, "<$prefix") || die;
open (OUT, ">$prefix.Npos.bed") || die;

    my $N_tot = 0 ;

my $head;
my $seq;
my $pos=0;

while (<IN>) {
    chomp;
    	if ($_=~/^>/) {
		$_=~s/\>//;
		$head=$_;
		$pos=0;
    	}
	else {
		my @chars = split("", $_);
		foreach my $cha (@chars) {
			if ($cha=~/N/) {
				print OUT "$head\t$pos\t$pos\t$cha\n";
			}
			else {
		    #print "NO N $head\t$pos\t$pos\t$cha\n";			
			}
		$pos++;
	}

	}
}

close(OUT);


exit;


