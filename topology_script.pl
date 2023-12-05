#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==2) {
        &USAGE;
}


sub USAGE {

die 'Usage: topology_script.pl file.topology list

Takes a toplogy file and a list with uniprot IDs, and pick out all the edges between the uniprot IDs only
'
}


	my $in = shift;
	my $in2 = shift;
	my $out = $in . "." . $in2 . ".out";

	open (IN, "<$in") || die "I can't open $in\n";

	open (IN2, "<$in2") || die "I can't open $in2\n";
	open (OUT, ">$out") || die "I can't open $out\n";

my %h1;
my %h2;


# read in all the IDs in the list

while (<IN2>) {
	chomp;
	if ($_=~/\w+/) {
		my @a=split(/\s+/,$_);
		$h1{$a[1]}=$a[0];
		#print ":$a[1]:\t$a[0]\n";
	}
}

close (IN2);



# First read in all lines in hash

while (<IN>) {
	chomp;
	my @arr = split(/\t/,$_);
	my $A = '#';
	my $reaction = '#';
	my $direction = '#';
	my $B = '#';
	$arr[1]=~s/\(/\t/;
	$arr[1]=~s/\)/\t/;
	($A,$reaction,$B) = split(/\t/,$arr[1]);
	#print "$arr2[0]:$arr2[1]:$arr2[2]:$arr2[3]\n";
	$reaction=~s/\(//;
	$reaction=~s/\;//;
	$A=~s/\s+//g;
	$B=~s/\s+//g;
	#print ":$A:\t:$B:\t:$reaction:\n";

	if ($A=~/\w+/ and $B=~/\w+/ ) {

		if (exists $h1{$A}) {
			#print "A\t$A\n";
			if (exists $h1{$B}) {
				print OUT "$h1{$A}\t$h1{$B}\t$reaction\n";
			}
		}
	}


}


close (IN);


close(OUT);
