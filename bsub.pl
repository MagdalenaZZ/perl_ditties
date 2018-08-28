#!/usr/bin/perl -w #
#

use strict;


unless (@ARGV > 1 ) {
        &USAGE;
}


sub USAGE {

    die '


Usage: bsub.pl USER PREFIX cores "job"




' . "\n";

}

#my @ARGV;
my $user = $ARGV[0];
my $prefix = $ARGV[1];
my $cores = $ARGV[2];
my $job = $ARGV[-1];
my $add = join(" ", splice(@ARGV,3,-1) );
#print "ADD:$add:\n";
#
if ($user=~/ME/) {
	$user="DDSBALAAE";
}

print "bsub -P $user -J $prefix -e $prefix.e -o $prefix.o -n $cores $add \"$job\"\n";

#`bsub -P $user -J $prefix -e $prefix.e -o $prefix.o -n $cores $add \"$job\"`;










