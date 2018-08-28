#!/usr/local/bin/perl -w

use strict;




unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die 'Usage: tab_merger.pl  *files



'
}



# print "@ARGV\n";


my @files = @ARGV;

#foreach my $file (@files) {

#    system "cat $file | grep -v RPKM | awk '{print \$1\"\t\"\$3}' > $file.1  ";
#    system "cat $file | grep -v RPKM | awk '{print \$1\"\t\"\$2}' > $file.1  ";
#}


my %h;

foreach my $file (@files) {

    open (IN , "<$file") || die;

    while (<IN>) {
        chomp;
        my @arr = split("\t", $_);
        
        push ( @{$h{$arr[0]}} , $arr[1] ); 
        #print "$arr[0]\t$arr[1]";

    }

    close (IN);
}




open ( OUT , ">merged.reads") || die;



print OUT "ID\t";


=pod

foreach my $file (@files) {
    $file=~s/\.BEDcoverage\.final\.count//g;
    #$file =~s/#/-/g;

    if ($file=~/^9887_8#7$/ || $file=~/^9887_7#7$/ || $file=~/^9887_6#7$/ || $file=~/^9887_5#7$/ || $file=~/^9887_4#8$/ || $file=~/^9887_3#8$/ ) {
        $file = "MCanaerob";
    }
    elsif ($file=~/^9887_8#8$/ || $file=~/^9887_7#8$/ || $file=~/^9887_5#8$/ || $file=~/^9887_6#8$/ || $file=~/^9887_4#9$/ || $file=~/^9887_3#9$/ ) {
        $file = "MCu";
    }
    elsif ($file=~/^9887_8#11$/ || $file=~/^9887_7#11$/ || $file=~/^9887_6#11$/ || $file=~/^9887_5#11$/ || $file=~/^9887_4#12$/ || $file=~/^9887_3#12$/ ) {
        $file = "aPS";
    }
    elsif ($file=~/^9887_8#10$/ || $file=~/^9887_7#10$/ || $file=~/^9887_6#10$/ || $file=~/^9887_5#10$/ || $file=~/^9887_3#11$/ || $file=~/^9887_4#11$/ ) {
        $file = "naPS";
    }
    elsif ($file=~/^9887_8#6$/ || $file=~/^9887_7#6$/ || $file=~/^9887_6#6$/ || $file=~/^9887_5#6$/ || $file=~/^9887_4#6$/ || $file=~/^9887_3#6$/ ) {
        $file = "MCvivo";
    }
    elsif ($file=~/^9887_3#4$/ || $file=~/^9887_4#4$/ || $file=~/^9887_5#4$/ || $file=~/^9887_6#4$/ || $file=~/^9887_7#4$/ || $file=~/^9887_8#4$/ ) {
        $file = "MCnoBC";
    }
    elsif ($file=~/^9887_8#5$/ || $file=~/^9887_7#5$/ || $file=~/^9887_6#5$/ || $file=~/^9887_5#5$/ || $file=~/^9887_4#5$/ || $file=~/^9887_3#5$/ ) {
        $file = "MCvitro";
    }
    elsif ($file=~/^9887_8#3$/ || $file=~/^9887_7#3$/) {
        $file = "PC3-21";
    }
    elsif ($file=~/^9887_8#2$/ || $file=~/^9887_7#2$/) {
        $file = "PC2-11";
    }
    elsif ($file=~/^9887_8#1$/ || $file=~/^9887_7#1$/) {
        $file = "PC1-2";
    }
    elsif ($file=~/^9887_3#1$/ || $file=~/^9887_4#1$/) {
        $file = "PC1-2";
    }
    elsif ($file=~/^9887_3#2$/ || $file=~/^9887_4#2$/) {
        $file = "PC2-7";
    }
    elsif ($file=~/^9887_3#3$/ || $file=~/^9887_4#3$/) {
        $file = "PC3-22";
    }
    elsif ($file=~/^9887_5#1$/ || $file=~/^9887_6#1$/) {
        $file = "PC1-2";
    }
    elsif ($file=~/^9887_5#2$/ || $file=~/^9887_6#2$/) {
        $file = "PC2-9";
    }
    elsif ($file=~/^9887_5#3$/ || $file=~/^9887_6#3$/) {
        $file = "PC3-16";
    }

    else {
        $file=~s/#/-/;
    }

}

=cut


my $files = join ("\t", @files);

print OUT "$files\n";

foreach my $gene (sort keys %h) {


    my $exp = join ("\t", @{$h{$gene}});

    print OUT "$gene\t$exp\n";

}


exit;


