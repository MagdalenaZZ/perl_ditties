#!/usr/local/bin/perl -w


use strict;

unless (@ARGV == 3) {
        &USAGE;
}




sub USAGE {

die '
Usage:

perl ~filter_fasta.pl    fasta   minimum-length  maximum-length

script for filtering fasta sequences by length

'
}

my $fasta = shift;
my $min = shift;
my $max = shift;

# read in the fasta file

open (IN, "<$fasta") || die "I can't open $fasta\n";
open (OUT, ">$fasta.filter_$min\_$max") || die "I can't open $fasta.caps\n";

my @fasta = <IN>;

# parse through the fasta and test

my $header;

foreach my $line (@fasta) {
chomp $line;

        if ($line =~ m/^>/) {
                $header = $line;
        }
        else {

         my $len = length($line);
# if it is too long
## ignore
        if ( $len > $max) {
        }
# elsif it is too short
## ignore
        elsif ($len < $min) {
        }
# else
        else {
        print OUT "$header\n$line\n";
        }
        }

}


close (OUT);

exit;

