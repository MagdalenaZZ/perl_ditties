#!/usr/local/bin/perl -w

# 

use strict;

unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die '


Usage: table-maker.pl infile


Takes one file with x-axis categories and genes, and sorts them into categories in a tab-delimited table

cat1   sp1_01 sp3_01
cat2    sp3_2   sp4_5

becomes:
        sp1     sp3     sp4
cat1    sp1_01  sp3_01
cat2            sp3_2   sp4_5


'
}

my $dom1 = shift;

	open (IN, "<$dom1") || die "I can't open $dom1\n";
	my @in = <IN>;
	close (IN);

my @xcate;
my %ycate;

    # figure out what the categories are 

foreach my $line (@in) {
     chomp $line;
     if ($line =~/\w+/) {
         my @arr = split(/\t/, $line);
        @xcate = shift @arr;
        foreach my $elem ( @arr) {
            $elem =~s/ //;
            my @arr2 = split (/_/, $elem);
            if (scalar(@arr2) > 0 ) {
                $ycate{$arr2[0]}= 1;
            }
        }
        
    }
}

	open (OUT, ">$dom1.txt") || die "I can't open $dom1.txt\n";

 # print y header
print OUT "\t";

foreach my $ycat (sort keys %ycate) {
    print OUT "#$ycat\t$ycat\t";
}
 print OUT "\n";

#print Xheader

foreach my $line (@in) {
        chomp $line;
        if ($line =~/\w+/) {

        my @arr = split(/\t/, $line);
#        if (exists $arr[0] ) {
#        print "\n$arr[0]\n";
        print OUT shift(@arr);
        print OUT "\t";

        foreach my $elem2 ( @arr) {
            $elem2 =~s/ //g;
            $elem2 =~s/,$//;
            $elem2 =~s/\.1\.\.pep//g;
            $elem2 =~s/\.2\.\.pep//g;
            $elem2 =~s/\.3\.\.pep//g;

#            print "$elem2\n";
        }

        my @sarr = sort(@arr);

        foreach my $ycat (sort keys %ycate) {
            my $match = 0;
            foreach my $elem3 ( @sarr) {

            $elem3 =~s/ //g;
            $elem3 =~s/,$//;
            my @arr2 = split (/_/, $elem3);
            my @arr3 = split (/,/, $elem3);
            my $len = scalar(@arr3);

            if (scalar @arr2 > 0) {
#            print "$elem3\n";
            
#                     print "$ycat\n";

                # if the elem exists in file
                if ($arr2[0] eq $ycat) {

                    print OUT "$len\t$elem3\t";
#                    print "$elem3\t";
                    $match = 1;
                }

                # else 
                else {
#                    print OUT "\t";
#                    print "\t";
                    # do nothing
                }
            }

            }

            if ($match =~ /^0$/) {
                print OUT "\t\t";
                $match = 0;
            }
        }
           print OUT "\n"; 
#           print "\n"; 
    }

}
#}
    #
close (OUT);
