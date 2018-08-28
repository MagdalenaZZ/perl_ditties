#!/usr/bin/perl -w

use strict;

unless (@ARGV == 2) {
        &USAGE;
}


sub USAGE {

    die '


Usage: split_me.pl   <no of lines> file


Takes a file and splits it into several files 


' . "\n";
}


my $no = shift;
my $in = shift;

open (IN, "<$in")|| die;


my %h;
#my $last_file = "0";
my $i=0;
my $x = 1;

while (<IN>) {
    chomp;
    #my @arr = split(/\t/, $_);
    my $file = "$in.$x";
    open (OUT, ">>$file")|| die ' ';
# if index is okay
    if ($i < $no) {
        #print "IF $file\n";
        print OUT "$_\n";
        $i++;
    }
# time for new file
    else  {
        #print "ELSE $file\n";
        print OUT "$_\n";
        close (OUT);
        #open  (OUT, ">>$file.txt")|| die;
        $i=0;
        $x++;
    }

    
}


close (OUT);
close (IN);

exit;

