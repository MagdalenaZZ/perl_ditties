#!/usr/local/bin/perl -w

use strict;
use Statistics::Basic qw(:all);


unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die 'Usage: table_sum_up.pl merged.tab


Sums up column and row values from a matrix 

Warning: column and row names mush be unique for it to work properly!!! 


'
}



my $data = shift;

open(DATA, "<$data") or die "Cant find file $data\n  $!";

chomp(my $head = <DATA>);

#print "$head\n";

my @arr1 = split(/\t/,$head);
my $col = scalar(@arr1);


my %rowsum;
my %colsum;

# Create columns
foreach my $elem (@arr1) {
	$colsum{$elem}=0;
}


my $i = 1;

while (<DATA>) {
chomp;
	my @arr = split(/\t/,$_);
	my $head=shift(@arr);
	
	my $max=0;
	my $min=9999999999999;
	my $mean=mean(@arr);
	my $v1= $mean->query_vector;
	my $variance = variance( $v1 );

		#print "$head\n";
	    #print "@arr\n";
    foreach my $elem (@arr) {


	    if ($elem>$max) { $max=$elem};
	    if ($elem<$min) { $min=$elem};

	    # Add to rows
            if (exists $rowsum{$head} ) {
			$rowsum{$head}+=$elem;
		}
		else {
			$rowsum{$head} =$elem;
		}
	    # Add to columns
		$colsum{$arr1[$i]}+=$elem;
		$i++;
        }

	# Add max and min to row
	$rowsum{$head} = $rowsum{$head} . "\t$min\t$max\t$mean\t$variance";

	$i=1;
	
}







close DATA;


open(OUTR, ">$data.rowsum") or die "Cant find file $data.rowsum\n  $!";
open(OUTC, ">$data.colsum") or die "Cant find file $data.colsum\n  $!";

print OUTR "ID\tsum\tmin\tmax\tmean\tvar\n";
print OUTC "ID\tsum\n";

foreach my $el (sort keys %rowsum) {
            print OUTR "$el $rowsum{$el}\n";
    }


foreach my $el (sort keys %colsum) {
            print OUTC "$el $colsum{$el}\n";
    }


close(OUTC);
close(OUTR);


exit;



