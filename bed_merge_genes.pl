#!/usr/bin/perl -w
use strict;
use Data::Dumper;

unless (@ARGV >=1) {
        &USAGE;
}


sub USAGE {

die 'Usage: 

Usage: gff2featurecount.pl <input.bed> 

mz script for taking a bed-file and merge read counts for each gene

'
}

my $gff = shift;

open (GFF, "<$gff") || die "I can't open $gff\n";
my @gff = <GFF>;
close (GFF);

open (OUT1, ">$gff.mer.bed") || die "I can't open $gff.mer.bed\n";


my $gene = "0";

foreach my $line (@gff) {
	chomp $line;
	my @arr =split(/\s+/, $line);
	print "\n";
}

close (OUT1);

exit;


