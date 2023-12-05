#!/usr/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}




sub USAGE {

    die '


Usage: dotplot_in_R.pl file(s)

i.e.
dotplot_in_R.pl *.numbers.txt
dotplot_in_R.pl *.numbers.txt


This program takes a file with a column with numbers and draws a dotplot from it in R.
Each input file as a separate distribution


File:

Gene1   0.34    0.62
Gene2   0.31    0.57
...



    ' . "\n";
}






#my $in = shift;
my @files = @ARGV;

my $ymax = "0";
my $xmax = "0";
 
my $arr = join(" ", @ARGV);

if ($arr=~/y=/ and $arr=~/x=/) { 
    $ymax = shift;
    $ymax=~s/y=//;
    $xmax = shift;
    $xmax=~s/x=//;
}



# Perl dotplot R
open (R, ">$files[0].dp.R") || die "I can't open $files[0].dp.R\n";

# make the file to print to
print R "pdf(\"$files[0]\.dot\.pdf\", useDingbats=FALSE)\n";

print R '
xlab ="Units"
ylab = "Dotplot"
#mfrow = c(1,1)
#dcol = 1
#lcol = 1

';

my $a = scalar(@files);

print R " col<-rgb(runif($a),runif($a),runif($a))\ncol \n";

# read in data

my $i=0;
foreach my $file (@files) {

        print R " x$i<-read.table(\"$file\",header=T) \n";
        print R "col$i  <-x$i\[\,1\]\n";
        #print R " d$i <-density(col$i)\n";
        # adjust kernel density
        #print R " d$i <-density(col$i, bw=c(0.1))\n";	
	#print R "bw.nrd0(col$i)\n";

        # if y and X max are defined
        #if ($i=~/^1$/  and ( $ymax>0 or $xmax>0 )   ) {
        #    print R "plot(d$i, col=col[$i], main=\"Dotplot of $files[0]\", xlim=c(0, $xmax), ylim=c(0, $ymax) , axes = FALSE)  \n";
        #    print R "axis(side = 1, at = c(1:50)) \n";
        #    print R "axis(side = 2, las = 1) \n";
        #}
        #elsif ($i=~/^1$/) {
        #print R "plot(d$i, col=col[$i], main=\"Frequency density plot of $files[0]\", xlim=c(-2.5, 2.2), ylim=c(0, 1.4) )  \n";
        #}
        # if y and x max are not defined
        if ($i=~/^1$/) {
            print R "plot(d$i, col=col[$i], main=\"Dotplot of $files[0]\", axes = FALSE )  \n";
            print R "axis(side = 1, at = c(1:50)) \n";
            print R "axis(side = 2, las = 1) \n";
        }
        # y and y max automatically calculated by R
        else {
            print R "lines(d$i, col=col[$i])  \n";
        }


        
        $i++;
}


my $legend = join("\",\"", @files);
$legend = '"' . $legend . '"';

#print "$legend\n";

print R " legend(\"topright\", inset=.05, title=\"Legend\",   c($legend), fill=col)\n";

print R "dev.off()\n";
	

system "R CMD BATCH $files[0].dp.R";

print "R CMD BATCH $files[0].dp.R\n";

exit;







