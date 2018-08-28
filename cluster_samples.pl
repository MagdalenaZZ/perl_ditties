#!/usr/local/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die 'Usage: cluster_samples.pl  merged.tab



'
}



my $data = shift;

open(DATA, "<$data") or die "Cant fild file $data\n  $!";

chomp(my $head = <DATA>);
close DATA;

my @head = split /\t/, $head;
my $cols = scalar @head - 1;

my @libs = ();

for(1..$cols)
{
	push @libs, '"paired-end"';
}
my $lib_string = join ',', @libs;

open(OUT, ">$data.cluster.R") or die "$!";

print OUT "

TestCountTable <- read.table(\"$data\", header=TRUE, row.names=1 )

TestDesign <- data.frame (row.names = colnames(TestCountTable), condition = colnames(TestCountTable), libType= c($lib_string))

library(\"DESeq\")

cdsFull <- newCountDataSet( TestCountTable, TestDesign )

cdsFull <- estimateSizeFactors( cdsFull )

cdsFullBlind <- estimateDispersions( cdsFull, method = \"blind\" )

vsdFull <- getVarianceStabilizedData( cdsFullBlind )

dists <- dist( t( vsdFull ) )

pdf(\"$data.heatmap.pdf\")

heatmap( as.matrix( dists ),symm=TRUE, scale=\"none\", margins=c(20,20),col = colorRampPalette(c(\"seagreen\",\"blanchedalmond\",\"darkred\" ))(100),labRow = paste( pData(cdsFullBlind)\$condition, pData(cdsFullBlind)\$libType ) )

dev.off()

";

close OUT;

system("R-3.0.0 --no-save < $data.cluster.R") == 0 or die "$!";


exit;


