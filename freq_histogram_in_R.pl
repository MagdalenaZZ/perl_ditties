#!/usr/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}




sub USAGE {

    die '


Usage: freq_histogram_in_R.pl y=Y-max x=X-max file(s)

i.e.
freq_histogram_in_R.pl *.numbers.txt


This program takes a file with a column with numbers and draws a frequency histogram from it.
Using  R





    ' . "\n";
}

my $ymax = "0";
my $xmax = "0";
 
my $arr = join(" ", @ARGV);

if ($arr=~/y=/ and $arr=~/x=/) { 
    $ymax = shift;
    $ymax=~s/y=//;
    $xmax = shift;
    $xmax=~s/x=//;
}

my @files = @ARGV;

open (R, ">$files[0].R") || die "I can't open $files[0].R\n";
#open (OUT, ">$files[0].out") || die "I can't open $files[0].out\n";


my $i = "1";



# make the file to print to

#print R "file = \"$files[0]\.histo\.pdf\"";
print R "pdf(\"$files[0]\.hist\.pdf\")\n";

print R '
xlab ="Units"
ylab = "Frequency density"
mfrow = c(1,1)
dcol = 1
lcol = 1

';

my $a = scalar(@files);

print R " col<-rgb(runif($a),runif($a),runif($a))\ncol \n";

# read in data

foreach my $file (@files) {

        print R " x$i<-read.table(\"$file\",header=F) \n";
        print R "col$i  <-x$i\[\,1\]\n";
	print R "col$i <- log2(col$i)\n";
        print R " d$i <-density(col$i)\n";
        # adjust kernel density
        print R " d$i <-density(col$i, bw=c(0.06))\n";	
	    #print R "bw.nrd0(col$i)\n";

        # if y and X max are defined
        if ($i=~/^1$/  and ( $ymax>0 or $xmax>0 )   ) {
            print R "plot(d$i, col=col[$i], main=\"Frequency density plot of $files[0]\", xlim=c(-6, $xmax), ylim=c(0, $ymax) , axes = T)  \n";
            #print R "axis(side = 1, at = c(1:50)) \n";
            #print R "axis(side = 2, las = 1) \n";
        }
        #elsif ($i=~/^1$/) {
        #print R "plot(d$i, col=col[$i], main=\"Frequency density plot of $files[0]\", xlim=c(-2.5, 2.2), ylim=c(0, 1.4) )  \n";
        #}
        # if y and x max are not defined
        elsif ($i=~/^1$/) {
            print R "plot(d$i, col=col[$i], main=\"Frequency density plot of $files[0]\", axes = T)  \n";
            #print R "axis(side = 1, at = c(1:50)) \n";
            #print R "axis(side = 2, las = 1) \n";
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
	

system "R CMD BATCH $files[0].R";
####

__END__
 x<-read.table("test2.hist",header=F)
 y<-read.table("test3.hist",header=F)
 coly<-y[,1]
 colx<-x[,1]
 dx <-density(colx)
 dy <-density(coly)
 plot(dx)
 lines(dy)


