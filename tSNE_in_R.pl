#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >1) {
        &USAGE;
}


sub USAGE {

die 'Usage: tSNE_in_R.pl file labels perplexity


File - is tab-delimited, with column headers and row names
labels - list of labels for the columns (i.e. WT, KO), no header
perplexity - in the form of step size, ie. 5,50,10 (from 5 to 50, step size 10)


'
}


my $in=shift;
my $labs=shift;
my $sr=shift;

open (R, ">$in.R") || die "I can't open $in.R\n";
#open (OUT, ">$in.out") || die "I can't open $in.out\n";


print R 'library(Rtsne)
';

print R "train<- read.table(\"" . $in . "\", header=TRUE,  row.names=1, sep=\"\\t\") ## Choose the train.csv file downloaded from the link above\npx <- seq.int($sr)\n";

print R "lab<- read.table(\"" . $labs . "\", header=FALSE, sep=\"\\t\") \n lab\$V1 <- as.factor(lab\$V1)";


print R '

train <- t(train)

# check that you have enough dimensions #########
# 
dim(train)[1] > 8
# remove values in px that is larger than the number of samples
px <- px[px<dim(train)[1]]

## Curating the database for analysis with both t-SNE and PCA
Labels <- lab
#Labels<-row.names(train)
#train$label<-as.factor(train$label)
## for plotting
colors = rainbow(dim(unique(Labels))[1])
#colors = rainbow(length(unique(Labels)))
names(colors) = unique(Labels)

# Foreach step of px
# nrow(X) - 1 < 3 * perplexity

## Executing the algorithm on curated data
tsne <- Rtsne(train[,-1], dims = 2, perplexity=px, verbose=TRUE, max_iter = 500, check_duplicates = FALSE)
#exeTimeTsne<- system.time(Rtsne(train[,-1], dims = 2, perplexity=30, verbose=TRUE, max_iter = 500))

## Plotting
';

print R "pdf(file=\"" .$in . "\".tsne.pdf\", useDingbats=FALSE)\n";
print R '
plot(tsne$Y, t="n", main="tsne")
text(tsne$Y, labels=Labels, col=colors[Labels])
legend("topright", as.vector(Labels), fill=colors[Labels], bty="n")
dev.off()

';



exit;


