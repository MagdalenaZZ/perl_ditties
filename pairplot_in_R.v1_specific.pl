#!/usr/bin/perl
use strict;

unless (@ARGV >1) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/pairplot_in_R.pl values.file  target_genes.list



';

}

my $in = shift;
my $col = shift;
#my $in3 = shift;

#my $col = shift;
#my $leg = shift;


my @inr=split(/\//,$in);
my @colr=split(/\//,$col);


open (R, ">$inr[-1].$colr[-1].R") || die "Cannot print to file $inr[-1].$colr[-1].R\n";


# Read in data

print R "CountTable = read.table( \"$in\", header=TRUE, row.names=1 )\n";  


# Read in target genes
print R "tars = read.table( \"$col\", header=FALSE, row.names=1 )\n";   

# make selected set
print R "lt <- na.omit(CountTable[rownames(tars),])\n";


print R '
ls <- list()
ts <- list()
is <- list()
js <- list()

n=1 

for (i in colnames(lt)) {
	for (j in colnames(lt)) {
		if(i==j) {
			#n= n+1
		}
		else {
			si <- as.vector(lt[,paste(i, sep="")])
			sj <- as.vector(lt[,paste(j, sep="")])
			ts[[n]] <- t.test(si,sj, paired=TRUE)
			lm.ij <- lm(si~sj)
			ls[[n]] <- summary(lm.ij)
			is[[n]] <- i
			js[[n]] <- j
			n= n+1
		}
	}
}

is

js

ts

ls

';

print R "

library(car)

#fn <- paste(\"$inr[-1].\",\"all.pdf\", sep=\"\")
#pdf(file=fn, useDingbats=FALSE)
#scatterplotMatrix(~HSC+CMP+GMP+LMPP, data=CountTable, ellipse=FALSE, col=c(\"black\", \"red\",rgb(0.1,0.6,0.1,0.1)), pch=19)
#dev.off()

fn <- paste(\"$inr[-1].$colr[-1].\",\"pdf\", sep=\"\")
pdf(file=fn, useDingbats=FALSE)
scatterplotMatrix(~HSC+CMP+GMP+LMPP, data=lt, ellipse=FALSE, col=c(\"black\", \"red\",rgb(0.1,0.6,0.1,0.1)), pch=19)
dev.off()


\n";



system "R CMD BATCH $inr[-1].$colr[-1].R >  $inr[-1].$colr[-1].Rout";


system "cat  $inr[-1].$colr[-1].Rout | grep  't =' >  $inr[-1].$colr[-1].tres";
system "cat  $inr[-1].$colr[-1].Rout | grep -A 1 R-squared | paste - - - | sed \'s/\< /\</\' | awk \'{print \$3\"\t\"\$6\"\t\"\$15}' | tr -d \'\,\' >  $inr[-1].$colr[-1].lmres";

exit;






