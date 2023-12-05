#!/usr/bin/perl
use strict;

unless (@ARGV >1) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/pairplot_in_R.pl values.file  target_genes.list

values.file is a file that contains columns of numbers you want to compare to each other
target_genes.list is a list of specific rows you want to subset. If you want all, just put the same file as values.file 

Files must not have headers


';

}

my $in = shift;
my $col = shift;
#my $in3 = shift;

#my $col = shift;
#my $leg = shift;


my @inr=split(/\//,$in);
my @colr=split(/\//,$col);


my $len = `cat $in | awk '{print NF}' | head -1`;

#print $len;

my @ns = map { 2 * $_ } 1 .. ($len/2);

foreach my $elem (@ns) {

	$elem = "V" . $elem;
}

my $ns = join ("+", @ns);
#print "$ns\n";

open (R, ">$inr[-1].$colr[-1].R") || die "Cannot print to file $inr[-1].$colr[-1].R\n";


# Read in data

print R "CountTable = read.table( \"$in\", header=FALSE, row.names=1 )\n";  


# Read in target genes
print R "tars = read.table( \"$col\", header=FALSE, row.names=1 )\n";   

# make selected set
print R "lt <- na.omit(CountTable[rownames(tars),])\n";

print R '
cols <- paste("V",seq(2,round(dim(lt)[2]/2)+2,2), sep="")
';


print R '
ls <- list()
ts <- list()
is <- list()
js <- list()

n=1 

for (i in cols) {
	for (j in cols) {
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


fn <- paste(\"$inr[-1].$colr[-1].\",\"pdf\", sep=\"\")
pdf(file=fn, useDingbats=FALSE)
scatterplotMatrix(~$ns, data=lt, ellipse=FALSE, col=c(\"black\", \"red\",rgb(0.1,0.6,0.1,0.1)), pch=19, log=\"xy\")
dev.off()


\n";


system "R CMD BATCH $inr[-1].$colr[-1].R >  $inr[-1].$colr[-1].Rout";
system "cat  $inr[-1].$colr[-1].Rout | grep  't =' >  $inr[-1].$colr[-1].tres";
system "cat  $inr[-1].$colr[-1].Rout | grep -A 1 R-squared | paste - - - | sed \'s/\< /\</\' | awk \'{print \$3\"\t\"\$6\"\t\"\$15}' | tr -d \'\,\' >  $inr[-1].$colr[-1].lmres";

exit;






