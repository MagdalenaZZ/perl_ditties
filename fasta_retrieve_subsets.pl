#!/usr/bin/perl -w

use strict;




my $largest = 0;
my $contig = '';


if (@ARGV < 2) {
	print "Usage: fasta_retrieve_subsets.pl fasta list \n\n" ;

    print " mz3 script for retriveing fasta-files if their headers are in a list \n\n";

	exit ;
}

my $filenameA = shift @ARGV;
my $contig_name = shift @ARGV;
my %reads = () ;

open (IN, "$contig_name") or die "oops!\n" ;
open (OUT, ">$contig_name.in_list") or die "oops!\n" ;
open (OUT2, ">$contig_name.not_in_list") or die "oops!\n" ;


while (<IN>) {
	chomp ;
	my @line = split /\s+/ , $_ ;
	$reads{$line[0]}++ ;
    # print "Line:$line[0]:\n";
}
close(IN);

open (IN, "$filenameA") or die "oops2!\n" ;

my $isin=0;
while (<IN>) {

    # print "$_" ;
    # this is the header
        if (/^>(\S+)/) {

	my $seq_name = $1;
	 $seq_name=~s/>//;
	 #my $seq = <IN> ;
	#chomp($seq) ;
#	print "SEQname:$seq_name:\n";	
		if ($reads{$seq_name} ) {
			print OUT ">$seq_name\n" ;
			#print OUT "$seq\n" ;
			$isin=1;
		}
    		else {
			print OUT2 ">$seq_name\n" ;
			#print OUT2 "$seq\n" ;
			$isin=0;

    		}
    	}
	# this is the sequence
	else {
	
	    if ($_=~/\w+/) {
	    	if ($isin=~/1/) {
			print OUT "$_" ;
		}
		else {
		    print OUT2 "$_";
		}
	    }
	}


   
	
    
    #last;


}

close (OUT);
close (OUT2);

#print "\#\#the largest length is: $contig with $largest bp \n" ;
