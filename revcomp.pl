#!/usr/bin/perl
use strict;
use warnings;
     



my $in = shift;


#use My::RevComp qw(revcompl);
use My::RevComp;  #qw(revcompl);    

open (FAS, "<$in") || die "cant find file $in\n";
#open (FAS, "<$in") || die "cant find file $in\n";



while (<FAS>) {

    if ($_ =~/^>/) {
        print "$_";
    }
    else {
        chomp $_;
        #print "Seq $_\n";
        my $seq = My::RevComp::revcompl($_);
        print "$seq\n";

    }
}

