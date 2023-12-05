#!/usr/bin/perl -w
# Munge data
# magdalena.z@icr.ac.uk 28 March 2018

use strict;


unless (@ARGV == 1) {
	print "Usage: split_end.pl infile \n\n" ;

    print " mz3 script for creating a split end file \n\n";

	exit ;
}


my $inf=shift;
my $outf=$inf.".split";


open (IN, "<$inf") || die "I can't open $inf\n";


while(<IN>) {
	chomp;
	my @a= split('\t',$_);
	my @b= split(';',$a[1]);

	foreach my $elem (@b) {
		my @c = split(/\s+/,$elem);
		print "$a[0]\t$elem\n";
	}
}
