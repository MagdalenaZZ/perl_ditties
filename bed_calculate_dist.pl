#!/usr/bin/perl -w
use strict;
use Data::Dumper;

unless (@ARGV >=1) {
        &USAGE;
}


sub USAGE {

die 'Usage: 

Usage: bed_calculate_dist.pl <input.bed> 

mz script for taking a bed-file and calculating the distance to next feature

'
}

my $gff = shift;

open (GFF, "<$gff") || die "I can't open $gff\n";
my @gff = <GFF>;
close (GFF);

open (OUT1, ">$gff.dist") || die "I can't open $gff.dist\n";

my $first= shift(@gff);
my @first= split(/\s+/, $first);

#print "$first[2]\n";

my $start=0;
my $chr=0;

foreach my $line (@gff) {
	chomp $line;
	my @arr =split(/\s+/, $line);

	if ( $arr[0]!~/$chr/) {
		#my $first= shift(@gff);
		#my @first= split(/\s+/, $first);
		#print "$first[2]\n";
		$start=$arr[2];
		$chr=$arr[0];
		print OUT1 "#New chromosome $chr \n";
	}
	else {
		my $dist = $arr[1]- $start;
		print OUT1 "$chr\t$start\t$arr[1]\t$arr[2]\t$dist\n";
		$start= $arr[2];
	}
}

close (OUT1);

exit;


