#!/usr/bin/perl -w

use strict;
#use Cwd;
use Statistics::Lite qw(:all);

unless (@ARGV > 1 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: fastqc_parser.pl prefix fastqc_data.txt


This script parses the FastQC output file fastqc_data.txt
and delivers a verdict on:

1. Start quality


' . "\n";

}

# Get the files right

#my $cwd = cwd();
my $prefix=shift;
my $in=shift;


$/ = ">>";


open (OUT, ">$prefix.parsed") || die "I can't open $prefix.parsed\n";

if ($in=~/.gz$/) {
	open (IN, "gunzip -c $in |") || die "I can't open pipe to $in\n";
}
else {
	open (IN, "<$in") || die "I can't open $in\n";
}


my @in = <IN>;
my @in2 = "";

#if (@ARGV>0) {
#	open (IN2, "<$in") || die "I can't open $in\n";
#	@in2=<IN2>;
#}

#push(@in, @in2);



#print "@in\n";


# read through the file, catch the Per base sequence content unit


foreach my $elem (@in) {

	#print "ELEM $elem\n";

	if ($elem=~/^Per base sequence content/) {
		#print "$_\n\n";
		$/= "\n";
		my @arr =split(/\n/, $elem);
		my $last="0\t0\t0\t0\t0";
		my $lastvar=0;
		my $current="UNUSUAL";
		my $final= "0";
		foreach my $line (@arr) {
			chomp $line;
			#print "LINE:$elem\n";

			if  ($line!~/Base/ & $line!~/\>/ & $line!~/Per/) {
				#print "LINE:$line\n";
				my @var = split(/\t/, $line);
				my $index = shift(@var);
				my @index=split(/-/, $index);
				$index=$index[0];
				#my $vari = variance(@var);
				#my $max = max(@var);
				#my $min = min(@var);
				my($pos,$G,$A,$T,$C) = split(/\s+/, $line);
				my($lpos,$lG,$lA,$lT,$lC) = split(/\s+/, $last);				
				my $sA = ($A-$lA); 
				my $sC = ($C-$lC);
				my $sG = ($G-$lG);
				my $sT = ($T-$lT);
				my $vars = variance($sA, $sC, $sG, $sT);
				#print "LAST $lA\t$lT\n";
				#print "NOW $A\t$T\t$sA\t$sC\t$sG\t$sT\t$vars\n";

				if ($vars < 10){
					#print "GOOD\t$vars\t$lastvar\t$index\n";

					#$current="Normal $index $min $max";	
					if ($lastvar < 10) {	
						#print "Final $final\n";
						last;		
					}	
					else {
					}

				}
				else {
					#print "UNUSUAL\t$vars\t$lastvar\t$index\n";
					#$current="UNUSUAL $index $min $max";
					$final = $index-1;

				}
				#print "$last\t$current\n";
				$last=$line;
				$lastvar=$vars;
			}
			else {
				my $ex2 = 0;
				#print "Else $line\n";
			}

		}
	print OUT "$prefix\t$final\n";

	}
	else {
	}


}



$/= "\n";





close (IN);
close (OUT);
exit;


