#!/usr/bin/perl -w

use strict;


unless (@ARGV > 2) {
        &USAGE;
}



sub USAGE {

    die '


Usage: genomewide_in_R.pl <windowsize> <stepsize> in.table

i.e.


This program takes a file with genome-wide density data, and prints plots from it.
Using  R.

in.table = has header and column names
The first header will be shown as title of the graph

The program does column scaling



    ' . "\n";
}



my $ws=shift;
my $ss= shift;
my $in= shift;
my $reps =`head -2 $in| tail -1 | awk '{print NF}'`;
chomp $reps;
#print "REPS:$reps:\n";

open (R, ">$in.R") || die "I can't open $in.R\n";

print R "library(zoo)\nlibrary(ggplot2)\n";

print R "windowlength <- $ws \n stepsize <- $ss \n";

print R "snps<-read.table(\"$in\", header=TRUE, row.names=1,  sep=\"\\t\")\n";


print R '


# column scaling

#snps <- as.data.frame(scale(snps, center=FALSE,scale=0.0001*colSums(snps)))
snps <- as.data.frame(scale(snps, center=FALSE,scale=colMeans(snps)))

# sliding window
snpb <- as.data.frame(rollapply(snps,windowlength,mean,align="center",by=stepsize, by.column = TRUE))

# Chromosome names
snpb$Chromosome <-  rep(rownames(snps)[1], dim(snpb)[1])
snpb$start <- seq(0,  by = stepsize, length.out=dim(snpb)[1])+windowlength/2

#snps$start <- as.numeric(str_split_fixed(rownames(snps), "_", 2)[,2])
#snps$Chromosome <- str_split_fixed(rownames(snps), "_", 2)[,1]

# Create random colours
ncolls <- dim(snps)[2]
cols <- rgb(runif(ncolls),runif(ncolls),runif(ncolls)) 


# create plot

snpDensity<-ggplot(snpb, aes(x=start))  + 
facet_wrap(~ Chromosome,ncol=2) + xlab("Position in the genome") +  
ylab("Depth") + 
scale_fill_discrete(name="Experimental Condition", labels=colnames(snpb)) +
';


my $i = 1;

while ($i< ($reps-1)) {
	
	print R "geom_point(aes(y= snpb[,$i]), color=cols[$i], alpha = 5/5, shape=46) + \n"; 
	$i++;
}

print R  "geom_point(aes(y= snpb[,$i]), color=cols[$i], alpha = 5/5, shape=46) \n"; 


#save plot

print R " fn = paste (\"$in\" , \".gw.pdf\", sep=\"\")\n";
print R 'ggsave(filename=fn, plot=snpDensity)

';

close(R);

print "R CMD BATCH $in.R >  $in.Rout \n";


exit;

__END__











