#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: annotation2FileMaker.pl file

Takes a variant annotation call, and converts it to a FileMaker input file

Example:



'
}


my $in=shift;

open (IN, "<$in") || die "I can't open $in\n";
open (OUT, ">$in.txt") || die "I can't open $in.txt\n";


my @res;
#my @arr2;
my $i=0;
my $j=0;
my $res='';

while (<IN>) {

	my @arr = split(/\t/,$_);

	foreach my $line (@arr) {
		
		if ($line=~/^GENE/) {
			
		}
		elsif ($line=~/^CAVEAT/) {
			print "$line";
			$i++;
		}
		elsif ($i==0 ) {
		}

		elsif ($i<3) {
			print "$line\n";
			$i++;
		}

		else {
			

			if ($j<8) {
				$res= $res . "$line\t";
				$j++;

			}
			else {
				$res= $res . "\n";
				$j=0;
				if ($res=~/No Variant Detected/){
					#print "novar $res";
					$res='';
				}
				else {
					print OUT $res;
					$res='';
				}
			}

		}
	}


}

print "\n\n\n";






exit;

