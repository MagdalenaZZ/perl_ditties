#!/usr/bin/perl -w

use strict;
use Math::Round;

unless (@ARGV == 1 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage:


' . "\n";

}

my $in=shift;

open (IN, "<$in") || die "I can't open $in\n";

my @in = <IN>;

my $m=0;
my $h=0;
my $virus = 0;
my $viruss = 0;
my $hyb = 0;
my $hybs =0;

foreach my $ele (@in) {
	chomp $ele;
	#print "$ele\n";
	my @a=split(/\t/, $ele);

	if ($ele=~/MM/) {
		$m = $a[0];
		#print "MM :$m:\n";
	}
	elsif ($ele =~/HS/) {
		$h = $a[0];
		#print "HS :$h:\n";
	}
	elsif ($ele=~/pMSCV/) {
		my @vir =split(/\s+/,$ele);

		if ($vir[0] > $virus) {
			$virus= $vir[0];
			$viruss=$vir[1];
			#print "Max $virus $viruss\n";
		}
	}
	elsif ($ele =~/\*/) {
	}	
	else {
		my @vi =split(/\s+/,$ele);

		if ($vi[0] > $hyb) {
			$hyb= $vi[0];
			$hybs=$vi[1];
			#print "Max $virus $viruss\n";
		}		
	}

	
}

my $q;

if ($m==0 and $h==0) {
	print "\nThe species file was not successfully made\n\n";
}

elsif ($m > $h) {
	$q=nearest(.01, $h/$m);
	print "$in\tSPECIES\tMus\t$m\t$h\t$q\n";
}
else {
	$q=nearest(.01, $m/$h);
	print "$in\tSPECIES\tHuman\t$h\t$m\t$q\n";
}

if ($virus>10) {
	print "$in\tVIRUS\t$viruss\n";
	print "$in\tHYBRID\t$hybs\n";
}

exit;
