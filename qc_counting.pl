#!/usr/bin/perl -w

use strict;
use Cwd;

unless (@ARGV > 1 ) {
        &USAGE;
}


sub USAGE {

    die '$ARGV[0]


Usage: qc_counting.pl featureCount.output


This script takes file(s) and sums up the read counts


' . "\n";

}


open (OUT, ">$ARGV[0].count") || die "I can't open $ARGV[0].count\n";


# Get the files right 

my %ct;

# print "@ARGV\n\n";
#__END__

foreach my $in (@ARGV) {
	open (IN, "<$in") || die "I can't open $in\n";
	print "Opening $in\n";
	
	while (<IN>) {
		chomp;
		my @a=split(/\s+/,$_);
		#print "A @a\n";

	# Remove headers
		if ($_=~/^#/) {
			#print OUT "Gene\t$in\n";
			#print "Header $_\n";
		}	
		elsif ($_=~/^Geneid/) {
			#print "Header $_\n";
		}
	# adjust for PE or SE
		elsif (($in=~/countp/ or $in=~/htp/) and scalar(@a)>6 ) {
			# PE
			# print "File $in is PE\n\n";
			#my $reads = $a[6];
			#print "PE $a[6]\n";
			if (exists $ct{$a[0]}) {				
				#print "pExists $a[6]\n";
				if ($ct{$a[0]}==0) {
					$ct{$a[0]}=$a[6];
				}
				else {
					$ct{$a[0]}+=$a[6];
				}
			}
			else {
				$ct{$a[0]}=$a[6];
				#print "pNot $a[6]\n";
				#print "pNot $a[0]\t$a[6]\n";
			}
		}
#		elsif ($in=~/\w+/ and scalar(@a)>6) {
		elsif (($in=~/counts/ or $in=~/hts/) and scalar(@a)>6) {
			# SE			
			#print "SE $a[6]\n";
			if (exists $ct{$a[0]}) {				
				#print "sExists $a[0]\n";
				if ($ct{$a[0]}==0) {
					$ct{$a[0]}=$a[6];
				}
				else {
#					#print "$a[0]\t$a[6]\n";
					$ct{$a[0]}+=$a[6];
				}
			}
			else {
				$ct{$a[0]}=$a[6];
				#print "sNot $a[6] @a\n";
			}	
		}
		elsif (scalar(@a)==6) {
			#print "Missing value @a\n";
			#print scalar(@a) ."\n";
		}
		else {
			print "Please specify with the file-name if your reads are SE - counts or PE - countp\n\n";	

		}
	
	}

	close (IN);

}

foreach my $key (sort keys %ct) {
	print OUT "$key\t$ct{$key}\n";
}

exit;




