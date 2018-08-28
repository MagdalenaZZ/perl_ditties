#!/usr/bin/perl -w

use strict;
#use File::Slurp;
#use Cwd;
use Data::Dumper;
use Data::Dump;


my $largest = 0;
my $contig = '';


if (@ARGV < 1) {
	print "\n\nUsage: runDESeq.pl merged.reads my.design <included columns> <prefix> <design> <file with genes> \n\n" ;

    print " mz3 script for doing voom and LMfit in EdgeR and limma \n\n";
    print "Verify the re-leveling strategy!!!\n";
	exit ;
}


push(@ARGV, " ");
my $file = shift;
my $des = shift;  
my $incl = shift;
my $pre = shift;
my $de=shift;
my $genes = shift;


# open the file
open (IN, "$file") || die "I can't open $file\n";
open (IN2, "$des") || die "I can't open $des\n";
my @des = <IN2>;


# make a choice of subset rows and columns 

my @inc = split(/\,/, $incl);

unshift @inc, "0";

my @design;

foreach my $ele (@inc) {
    #$ele--;
    my $ne = $des[$ele];
    $ne=~s/^\t//;
    $ne=~s/^\s+//g;
    #$ne=~s/^\s+//g;
    #$ne=~s/^\s+//g;
    #$ne=~s/^\s+//g;
    #$ne=~s/^\s//g;
    #$ne=~s/ //g;
    push (@design, "$ne" );

    #print "$ele\t$ne\n";
}



# make the same choice for genes

my @submat;

while (<IN>) {
    chomp;
    my @arr = split(/\s+/, $_);
    my @new_arr;

    foreach my $ele (@inc) {
        #$ele--;
    push (@new_arr, $arr[$ele] );
    }

    my $new = join("\t", @new_arr);
    #print "$new\n";
    push(@submat, "$new\n");
}





# write outfiles

open (OUT, ">$pre.tab") || die "I can't open $pre.tab\n";
open (OUT2, ">$pre.design") || die "I can't open $pre.design\n";

foreach my $l (@design) {
    print OUT2 "$l";
}

foreach my $l (@submat) {
    print OUT "$l";
}

close(OUT2);
close(OUT);



open (R, ">$pre.R") || die "I can't open $pre.R\n";

print R "\n";
print R "\n";
print R "library(DESeq)\nlibrary(edgeR)\nlibrary(limma)\n";

print R "CountTable = read.table( \"$pre.tab\", header=TRUE, row.names=1 )\n";
print R "desig =  read.table( \"$pre.design\", header=TRUE, row.names=1 )\n";
print R "\n";

print R '
y <- DGEList(counts=CountTable)
isexpr <- rowSums(cpm(y)) >= 4
y <- y[isexpr,]
y <- calcNormFactors(y)
';

#expt=factor(c(1,2,1,2,3,4,3,4))
#treat=factor(c("wt","wt","ko","ko","wt","wt","ko","ko"), levels=c("wt","ko"))
print R "Experiment <- factor(desig\$Experiment)\n";
print R "Cell <- factor(desig\$Cell)\n";
print R "Trans <- factor(desig\$Trans)\n";
print R "KO <- factor(desig\$KO)\n";
print R "Virus <- factor(desig\$Virus)\n";
print R "Leu <- factor(desig\$Leu)\n";
print R "design <- model.matrix($de)\n";



print R 'v <- voom(y,design,plot=TRUE)
#v <- voom(new,design,plot=TRUE)
fit <- lmFit(v, design)
fit <- eBayes(fit)
';

print R "write.table(as.data.frame(design),file=\"$pre.matrix.txt\", sep=\"\\t\")\n";

my $i=2;

for ($i; $i<10; $i++) {
    #print R "colnames(design)[$i]\n";
    print R "result=topTable(fit, coef=colnames(design)[$i], n=Inf, sort=\"p\")\n";
    print R 'norm.counts <- cpm(y)
    result1=merge(result,norm.counts,by.x=0,by.y=0)';
    print R "\nwrite.table(result1,file=\"$pre.$i.dat\",quote=FALSE, sep=\"\\t\",row.names=TRUE)\n";
}

close(R);

system "R CMD BATCH $pre.R  $pre.Rout"; wait;

exit;



