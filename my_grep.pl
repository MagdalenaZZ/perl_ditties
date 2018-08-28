#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use Getopt::Long;
use Scalar::Util;

# checking input values

my %opts;

unless (@ARGV > 2) {
        &USAGE;
}

getopts('hi:i:f:v:w:o:', \%opts);

&USAGE if $opts{h};


sub USAGE {

die '


 mz3 script for retriveing stuff just like grep does, but faster.

Usage: my_grep.pl -i file -f list -o output  -v yes -w yes
	-i: input
    -f: the list with things you want to grep
        The following flags are just as in grep

	-v: grep those not in the file	
	-w: grep only on words    
    
    

    '

}

my @in;
my @list;

# make sure there is input

if ($opts{i}) {
	VALIDATEI($opts{i});
} else {
	print "Please give me an input file\n";
	&USAGE;
}

# make sure there is a file

if ($opts{f}) {
	VALIDATEF($opts{f});
} else {
	print "Please give me a file to search\n";
	&USAGE;
}

# make sure there is output

if ($opts{o}) {
	VALIDATEO($opts{o});
} else {
	print "Please give me an output file\n";
	&USAGE;
}



#print "IN: $in[1]\n";

#print "LIST: $list[1]\n";

my $v = 0;
my $w = 0;

if ($opts{v}) {
    $v = 1;	
} 

if ($opts{w}) {
    $w = 1;		
} 


# loop through the list, and make a hash

my %hash;

foreach my $elem (@list) {

chomp $elem;
    
    $hash{$elem} = 1;

}



# loop through the infile and pick what you want

my @hits;
my %missing;
my @miss;
my %hit;

foreach my $line (@in) {
chomp $line;

    if ($w=~/1/) {

        foreach my $key (keys %hash) {

            if ( $line =~/\b$key\b/ ) {
                push (@hits, $line);
                $hit{$line} = 1;
            }
            else {
#                $missing{$line} = 1;
            }

        }

    }

    else {

        foreach my $key (keys %hash) {

            if ( $line =~/$key/ ) {
                push (@hits, $line);
                $hit{$line} = 1;
            }
            else {
#                $missing{$line} = 1;
            }

        }
        
    }



}


foreach my $line (@in) {
    chomp $line;

    if (exists $hit{$line} ) {
        # hit
    }
    else {
        push (@miss, $line);
        #print "Miss $v $line\n";
    }
}


# print output


    if ($v=~/1/) {
        foreach my $elem (@miss) {
            print OUT "$elem\n";
        }
    }

    else {
        foreach my $elem (@hits) {
            print OUT "$elem\n";
        }

    }






	close (OUT);


###### SUBROUTINES ###########################


sub VALIDATEI {
# sub validate checks that there is an inputfile, and reads it

	my $name = shift;
	open (IN, "<$name") || die "I can't open $name\n";
	print "Infile: $name\n";
	@in = <IN>;
	close (IN);

}


sub VALIDATEO {
# sub validate checks that there is an outputfile, and reads it
    
	my $out = shift;
	print "Output is $out\n";
    open (OUT, ">$out") || die "I can't open $out\n";
    
}

sub VALIDATEF {
# sub validate checks that there is an inputfile, and reads it

	my $name = shift;
	print "List is $name\n";	
	open (IN2, "<$name") || die "I can't open $name\n";
	@list = <IN2>;
	close (IN2);

}


exit;



