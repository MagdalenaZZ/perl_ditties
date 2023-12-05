#!/usr/bin/perl -w

use strict;

unless (@ARGV == 2) {
        &USAGE;
}


sub USAGE {

    die '


Usage: split_me.pl   <no of characters> file


Takes a file and splits it into severa files based on the first X characters


' . "\n";
}


my $no = shift;
my $in = shift;

open (IN, "<$in")|| die;


my %h;
my $last_file = "0";

while (<IN>) {
    chomp;
    my @arr = split(/\t/, $_);
    my $file = substr($arr[0],0,$no);

    if ($file=~/$last_file/ and $last_file=~/$file/  ) {
        #print "IF $file\n";
        print OUT "$_\n";
    }

    else  {
        #print "ELSE $file\n";
        close (OUT);
        open  (OUT, ">>$file.$no.$in.txt")|| die;
        print OUT "$_\n";
    }

    $last_file=$file;
}


close (OUT);
close (IN);

exit;

