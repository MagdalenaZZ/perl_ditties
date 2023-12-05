#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: GEO_make_pheno.pl GSE90689_series_matrix.txt.gz.sample.txt

Takes a GEO parsed file GSE90689_series_matrix.txt.gz.sample.txt and makes pheno-files from it


'
}


my $in = shift;


#	my $out = $prefix . ".GEOsummaries.txt";

	open (IN, "<$in") || die "I can't open $in\n";


#open (OUT, ">$out") || die "I can't open $out\n";
#my %res;
	
my @prefix = split(/\_/,$in);

	
my @header;
my %all;

while (<IN>) {
chomp;
	# get the header
	if ($_=~/^ID\t/) {
		@header=split(/\t/,$_);
	}
	else {
		my @a = split(/\t/,$_);
		my $i=0;
		foreach my $elem (@a) {
			$all{$header[$i]}{$elem}=1;
			$i++;
		}
	}


}	

my $i = 0;

foreach my $ele (@header) {

	if (exists $all{$ele}) {
	
		#print "$ele\t$all{$ele}\n";

		open (OUT, ">$prefix[0].$ele.$i.pheno") || die "I can't open $prefix[0].$ele.$i.pheno\n";

		my $j = 1;

		foreach my $key (keys $all{$ele} ) {
			print OUT "\"$j\"\t\"$key\"\n";
			$j++;
		}

		close (OUT);
	}
$i++;
}








