#!/usr/local/bin/perl -w

use strict;




unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die 'Usage: foreach.pl  "command"  *files 

Example:

perl ~/bin/perl/foreach.pl  "zcat X | head > X.out"    *b2B.o.out


Write a command-line within " ", and substitute all instances of a file with X

Then give an expression covering the files you want to apply that command on
Your commands will be printed to output




~/bin/bam2fastq-1.1.0/bam2fastq --no-unaligned



'
}


my $command = shift;

#print "$command\n";


my @files = @ARGV;

#print "@files\n";


foreach my $file (@files) {
    my $command1 = $command;
    $command1 =~s/X/$file/g;
    print  "$command1\n";

}




