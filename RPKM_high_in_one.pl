#!/usr/local/bin/perl -w

# 

use strict;


unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die '


Usage: RPKM_high_in_one.pl merged.RPKM cut-off




'
}

my $file = shift;
my $cut = shift;



my %h;

# read all domain architectures into a hash
#
	open (IN, "<$file") || die "I can't open $file\n";
	open (OUT, ">$file.maxexpressed") || die "I can't open $file.maxexpressed\n";
    my @in = <IN>;
	close (IN);


my @arr2 = split(/\t/, $in[0] );
shift @in;


print OUT "Gene\tCondition\t999999 Max RPKM\tSum of RPKMs\n";

foreach my $s (@in) {
    chomp $s;
    my @arr = split(/\t/,$s);

    my $max = 0;
    my $maxstate = "";
    my $i = 0;
    my $sum= 0;

    # find max
    foreach my $ele (@arr) {
        if ($ele=~/^\d+\.\d+$/ or $ele=~/^\d+$/  ) {

            if ($ele>$max) {
                $max = $ele;
                $maxstate = $arr2[$i];
                $i++;
                $sum= $sum+$ele;

                #print "$max\t$maxstate\t$i\n";
            }
            else {
                $sum= $sum+$ele;
            }
        }
        else {
                $i++;            
        }
    }


    # find if max is sufficiently large
    $i = 0;
    my $larger = 0;

    foreach my $ele (@arr) {
        if ($ele=~/^\d+\.\d+$/ or $ele=~/^\d+$/  ) {
            $ele= $ele+0.1;
    # is the same/itself
            if ($ele =~/$max/) {
                $i++;
                #print "SAME\t$ele\t$max\t$maxstate\t$i\n";
            }
            elsif ($ele > ($cut*$max) ){
                #print "LOWER\t$ele\t" . $cut*$max . "\t$maxstate\t$i\n";

            }
            else {
                #print "HIGHER\t$arr[0]\t$ele\t$max\t" . $cut*$max . "\t$maxstate\t$i\n";
                $larger++;
            }
        }
        else {
                $i++;            
        }
    }

    my $lim = scalar(@arr)-3;


    if ($larger > $lim) {
        print OUT "$arr[0]\t$maxstate\t$max\t$sum\n";
    }
    else {
        #print "NO\t$arr[0]\t$lim\t$larger\t$maxstate\t$max\n";
    }




}

close (OUT);
exit;





