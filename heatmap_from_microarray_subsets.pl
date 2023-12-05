#!/usr/bin/perl -w

use strict;

unless (@ARGV == 3) {
        &USAGE;
}


sub USAGE {




    die '

    Usage: heatmap_from_microarray_subsets.pl merged.reads subset <number of samples in first group>


    Example:  heatmap_from_microarray_subsets.pl test.tab subset.list 1:6



    Reads file-format:

    ID-line Sample1 Sample2
    Gene    Reads    Reads



    Subset

    Either:

    Gene1
    Gene2
    Gene3

    Or:

    Gene1   <TAB> Free-text
    Gene2   <TAB> Hox gene
    Gene3   <TAB> BlahX

Just be careful that all characters of the free-text can be read and understood by R


' . "\n";
}

# Read in file and clean it up
my $in = shift;
my $in2 = shift;
my $set = shift;
my @sets=split(/:/,$set);
my $sete=$sets[1]+1;

open (IN, "<$in")|| die;

my @in = <IN>;

my $header = shift @in;



open (R, "> $in.$in2.R")|| die;

# Print R header
print R '
library("RColorBrewer")
library("gplots")
';

#print R "library(DESeq)\n";
print R "CountTable<-read.table(\"$in\", header=TRUE, row.names=1,  sep=\"\\t\")\n";
print R "subset<-read.table(\"$in2\", header=FALSE,  sep=\"\\t\")\n";





#hmcol = colorRampPalette(brewer.pal(9, "YlOrRd"))(10000)
#hmcol = colorRampPalette(c(\'blue\',\'black\',\'red\'))(1000)


#print R "select = counts(cdsFull)$c\nselect\n";

print R '
hmcol = colorRampPalette(c(\'blue\',\'white\',\'red\'))(1000)
hmcol[1] <- "#ffffe2"
';


print R "

# pick subset of data
CountTable <- CountTable[as.vector(subset\$V1),]
row.names(CountTable) <- subset\$V2
#row.names(CountTable) <- apply(subset[,2:4], 1, paste, collapse=\"_\", sep=\"_\")


# sort by diff in averages


list = ''

for (i in 1:dim(CountTable)[1]) {
	list[i] = sum(CountTable[i,$set])/dim(CountTable[i,$set])[2] - sum(CountTable[i,$sete:dim(CountTable)[2]])/dim(CountTable[i,$sete:dim(CountTable)[2]])[2]
}

CountTable\$mean <- as.vector(list)

CountTable <- CountTable[order(CountTable\$mean),]
CountTable <- CountTable[,1:(dim(CountTable)[2]-1)]

";

# make heatmap from count-table

print R " pdf(\"$in.$in2.pdf\", useDingbats=FALSE)\n";

#print R "heatmap.2(as.matrix(CountTable$c),symm=FALSE,trace=\"none\", col = hmcol,  margin=c(10, 20), scale=c(\"column\") )\n";
print R "heatmap.2(as.matrix(CountTable), trace=\"none\", col = hmcol, scale = \"row\" ,  margin=c(10, 20),dendrogram = \"column\", Rowv=FALSE )\n";

print R "dev.off()\n";

close (R);

print "R CMD BATCH  $in.$in2.R >  $in.$in2.Rout  \n";
system "R CMD BATCH  $in.$in2.R >  $in.$in2.Rout";

exit();

