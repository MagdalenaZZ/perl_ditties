#!/usr/local/bin/perl -w

# 

use strict;
use Hash::Merge;

unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die '


Usage: networker.pl network-file


Takes one file with edges of a network

dom1  <TAB>  dom2
dom1  <TAB>  dom3

Returns a list with network name, size of network, and all nodes in the network



'
}



my $dom1 = shift;

# read all domain architectures into a hash
#
	open (IN, "<$dom1") || die "I can't open $dom1\n";
	my @doms = <IN>;
	close (IN);

    open (OUT, ">$dom1.out") || die "I can't open $dom1.out\n";
    open (OUT2, ">$dom1.info") || die "I can't open $dom1.info\n";

my %net;
my $ind = "00000001";
$net{0}{0}=0;
my %asc;
my %self;

foreach my $lin (@doms) {
    chomp $lin;
    if ($lin =~/\w+/ ) {
            my @arr2 = split(/\t/, $lin);
            $arr2[0]=~s/ //g;
            $arr2[1]=~s/ //g;

# filter self-matchers
            if ( $arr2[0] =~/$arr2[1]/ and $arr2[1] =~/$arr2[0]/  ) {
                $self{$arr2[0]}=1;
            }
            else {
                $asc{$arr2[0]}{$arr2[1]} =1;
                $asc{$arr2[1]}{$arr2[0]} =1;
            }

#            print "LIN: $lin\n";
            my $hit1 = 0;
            my $hit2 = 0;

#### Go through the networks and check if they are there #### 

            foreach my $key ( keys %net ) {
#                print "KEY: $key\n";

                # check if I have to merge a network 
                
                if ( exists $net{$key}{ $arr2[0]} ) {
#                        $net{$key}{$arr2[1]}=1;
#                        print "Exist_0: $key\t$arr2[0]\t$arr2[1]\n";
                        $hit1 = $key;

                }
                elsif ( exists $net{$key}{ $arr2[1]}  ) {
#                        $net{$key}{$arr2[0]}=1;
#                        print "Exist_1: $key\t$arr2[0]\t$arr2[1]\n";
                         $hit2 = $key;
                }
            }

#### act on hit info  #### 

# none of the keys exists in previous networks

            if ( $hit1 =~/^0$/ and $hit2 =~/^0$/ ) {
                    my $new = "$ind" . "_NET";
                    $net{$new}{$arr2[0]}=1;
                    $net{$new}{$arr2[1]}=1;

#                    print "ELSE: $new\t$ind\t$arr2[0]\t$arr2[1]\n";
                    $ind++;
            }

# both of the keys exist in previous networks - have to merge

            elsif ( $hit1 =~/NET/ and $hit2 =~/NET/ ) {
#                print "Both exist\t$hit1\t$hit2\n";

            # First hash                %{$net{$hit1}}
            # Second hash                %{$net{$hit2}}

            # Make new hash and fill it with first
             my $new = "$ind" . "_NET";
             $ind++;

            my $merge = Hash::Merge->new( 'LEFT_PRECEDENT' );
            my %a =  %{$net{$hit1}};
            my %b =  %{$net{$hit2}};

            my %c = %{ $merge->merge( \%a, \%b ) };
            
             %{$net{$new}} = %c;

=pod
             # print original keys
            foreach my $h1 (sort keys %{$net{$hit1}} ) {
                    print "$hit1\t$h1\n";
            }
            foreach my $h2 (sort keys %{$net{$hit2}} ) {
                      print "$hit2\t$h2\n";
            }

             # print resulting keys
             foreach my $h3 (sort keys %{$net{$new}} ) {
                print "$new\t$h3\n";
             }
=cut

            # delete the two old hashes
            %{$net{$hit1}} = (); 
            %{$net{$hit2}} = (); 

            }

# first key exists - add the other to the network

            elsif ( $hit1 =~/NET/ and $hit2 =~/^0$/ ) {
                        $net{$hit1}{$arr2[1]}=1;
#                print "First exist\n";
            }

# last key exists - add the first to the network

            elsif ( $hit1 =~/^0$/ and $hit2 =~/NET/ ) {
                        $net{$hit2}{$arr2[0]}=1;
#                print "Last exist\n";
            }

# weird
            else {
                print "WARN weird $hit1\t$hit2\n";
            }

    }
    else {
#        print "blank $lin\n";
    }

}

# count and export the network


foreach my $elem (sort keys %net) {

    my $count = keys %{$net{$elem}};

    if ($count > 0 and $elem=~/NET/) {
        print OUT "$elem\t$count\t"; 
        foreach my $do ( sort keys  %{$net{$elem}} ) {
            print OUT "$do\t";
        }
        print OUT "\n";
    }

}


# count and export all the associations different nodes have

foreach my $domm ( sort keys %asc) {

        my $ct = keys %{$asc{$domm}};
         print OUT2 "$domm\t$ct\t";
        foreach my $ass ( sort keys %{$asc{$domm}} ) {
            print OUT2 "$ass\t";
        }
        print OUT2 "\n";

}

# print the self-matchers that havent been printed

foreach my $one ( sort keys %self) {
    unless ( exists $asc{$one}) {
        print OUT2 "$one\t0\n";
    }
}



	close (OUT);


