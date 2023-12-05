#!/usr/bin/perl -w

use strict;

unless (@ARGV == 2) {
        &USAGE;
}


sub USAGE {




    die '

    Usage: heatmap_from_counts.pl merged.reads subset

    file-format:

    ID-line Treatment.rep Treatment.rep 
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



#system "~/bin/perl/tab_list_co-ordinator.pl $in 1 $in2 1 1 $in2.temp ";
# system "cat $in.temp |  sort | awk -F'\t' '{print \$1\""\t\"\$2\"\t\"\$3\"\t\"\$4\"\t\"\$5\"\t\"\$6\"\t\"\$7\"\t\"\$8\"\t\"\$9\"\t\"\$10}' | tr -d ' '|  sort -r >  $in.temp2 ";
#system "cat $in.temp |  sort | tr -d ' '|  sort -r >  $in.temp2 ";



#__END__
open (IN, "<$in")|| die;
open (TMP, "> $in2.RPKM.tmp")|| die;


my @in = <IN>;

my $header = shift @in;

print TMP "$header";

my @arr = split(/\s+/, $header);
my $id = shift @arr;

my @pe;

foreach my $elem (@arr) {
#    my @arr2 = split(/\./, $elem);
#    $elem = $arr2[0];
    push (@pe, "paired-end");
}

#print "@arr\n";

#print "\n";




# read in index
open (IN2, "<$in2")|| die;

my %ind;

while (<IN2>) {
    chomp;
    my @arr2 = split(/\t/, $_);
#    $elem = $arr2[0];   
    push(@arr2, " ");
    push(@arr2, " ");

    # add alternative name
    if ($arr2[1]=~/\w+/) {
        $ind{$arr2[0]}="$arr2[1]";
        #print "I\t$arr2[0]\t$arr2[1]\n";
    }
    # but only if one exists
    else {
        $ind{$arr2[0]}="0"; 
        #print "E\t$arr2[0]\t \n";
    }
}


# make index array
my @c;
my $index=1;

foreach my $l (@in) {
    chomp $l;
    my @arr2 = split(/\t/, $l);

    # check if it exists and add to c-array
    # also write to the temp-file
    if (exists $ind{$arr2[0]} and  $ind{$arr2[0]}!~/^0$/) {
        #print "Exists\t$arr2[0]\t$index\t$ind{$arr2[0]}\n";
        push(@c, $index);
        my @arr3 = @arr2;
        shift @arr3;
        my $arr2=join("\t",@arr3);
        print TMP "$ind{$arr2[0]}\t$arr2\n";
        #print  "$ind{$arr2[0]}\t$arr2\n";

    }
    # add to C but dont substitute name
    elsif (exists $ind{$arr2[0]}) {
        #print "Elsif\t$arr2[0]\t$index\t$ind{$arr2[0]}\n";
        push(@c, $index);
        my $arr2=join("\t",@arr2);
        print TMP "$arr2\n";
        #print  "$arr2\n";
    }
    
    # dont add to c and dont substitute name
    else {
        #print "NOT\t$arr2[0]\t$index\n";
        my $arr2=join("\t",@arr2);
        print TMP "$arr2\n";

    }
    $index++;
}


my $c = join("\,",@c);
$c = "[c(" . $c . "),]" ;
#[c(1, 3),]
#print "$c\n";

if (scalar(@c)< 1) {
    print "\nNo hits found between infile and list\nCheck your data\n$in\n$in2\n";
    die;
}

#__END__
open (R, "> $in2.RPKM.R")|| die;

# Print R header

print R "library(DESeq)\n";
print R "pasillaCountTable<-read.table(\"$in2.RPKM.tmp\", header=TRUE, row.names=1,  sep=\"\\t\")\n";



# Print 

my $pas = join("\", \"", @arr );
my $pe = join("\", \"", @pe );

print R "pasillaDesign = data.frame(row.names = colnames( pasillaCountTable ), condition = c(\"$pas\") ";
 
print R ", libType = c( \"$pe\" ) )\n";


# Print R calculations
#
#print R "cdsFull = newCountDataSet( pasillaCountTable, pasillaDesign )\n";
#print R "cdsFull = estimateSizeFactors( cdsFull )\n";
#print R " cdsFull = estimateDispersions( cdsFull )\n";


# make heatmap from count-table

print R " pdf(\"$in2.RPKM.genes_clustered.pdf\", useDingbats=FALSE)\n";


print R '

#cdsFullBlind = estimateDispersions( cdsFull, method = "blind" )
#vsdFull = varianceStabilizingTransformation( cdsFullBlind )
library("RColorBrewer")
library("gplots")
';

#print R "select = counts(cdsFull)$c\nselect\n";

print R '
order = order(rowMeans(pasillaCountTable), decreasing=TRUE)
#hmcol = colorRampPalette(brewer.pal(9, "YlGnBu"))(10000)
hmcol = colorRampPalette(brewer.pal(9, "YlOrRd"))(10000)
#hmcol = colorRampPalette(c(\'blue\',\'black\',\'red\'))(1000)
hmcol[1] <- "#ffffe2"
#hmcol[1] <- "#FFFFFF"
';


print R "

# make transformation to normalize columns

# first normalise columns
x <- as.matrix(pasillaCountTable) %*% diag(1/colSums(as.matrix(pasillaCountTable))) * 1000000
# make into matrix
y <- as.matrix(x)
# add column names
colnames(y) <- colnames(pasillaCountTable)
# then do log10 transformed values
pas2 <- log10(pasillaCountTable$c + 1) 

";

#print R "heatmap.2(as.matrix(pasillaCountTable$c),symm=FALSE,trace=\"none\", col = hmcol,  margin=c(10, 20), scale=c(\"column\") )\n";
print R "heatmap.2(as.matrix(pasillaCountTable$c), trace=\"none\", col = hmcol,  margin=c(10, 20) )\n";

print R "dev.off()\n";

print R " pdf(\"$in2.RPKMlog10.genes_clustered.pdf\", useDingbats=FALSE)\n";

print R "heatmap.2(as.matrix(pas2), trace=\"none\", col = hmcol,  margin=c(10, 20) )\n";

print R "dev.off()\n";



#print R "heatmap.2(exprs(vsdFull)$c, col = hmcol, trace=\"none\", margin=c(10, 20))\n";

# without reordering
#print R "heatmap.2(as.matrix(pasillaCountTable$c), symm=FALSE,trace=\"none\", col = hmcol,  margin=c(10, 20), Rowv=NA )\n";
#        heatmap.2(as.matrix(pasillaCountTable[c(1328,2896,4676,6260,7611,7612,7614,8340,8341,8342,8370,8544,10577),]), trace="none", col = hmcol, margin=c(10, 20))

#print R "heatmap.2(pasillaCountTable$c, col = hmcol, trace=\"none\", margin=c(10, 20))\n";
#print R "write.table(exprs(vsdFull)$c , file=\"$in2.final.tab\", row.names=TRUE, col.names=TRUE )\n";


# make heatmap from cluster distances
#print R " pdf(\"$in.heatmap.pdf\")\n";
=pod
print R "
dists = dist( t( exprs(vsdFull) ) )
mat = as.matrix( dists )
rownames(mat) = colnames(mat) = with(pData(cdsFullBlind), paste(condition, libType, sep=\" :\"))
#heatmap.2(mat, trace=\"none\", col = rev(hmcol), margin=c(13, 13))
";
#print R "dev.off()\n";



print R "pdf(\"$in2.heatmap.pdf\", useDingbats=FALSE)\n";
print R '

heatmap( as.matrix( dists ),symm=TRUE, scale="none", margins=c(20,20),col = colorRampPalette(c("seagreen","blanchedalmond","darkred" ))(100),labRow = paste( pData(cdsFullBlind)$condition, pData(cdsFullBlind)$libType ) )

';
print R "dev.off()\n";


# Principal component plot of the samples

print R " pdf(\"$in2.PCA.pdf\", useDingbats=FALSE)\n";
print R ' print(plotPCA(vsdFull, intgroup=c("condition", "libType")))

';
print R "dev.off()\n";


=cut

close (R);

#__END__

system "R CMD BATCH   $in2.RPKM.R";


__END__

library(DESeq)


# read in datafile in R

countTable<-read.table("EMU.merged.reads.txt", header=TRUE, row.names=1)

condition = c("7745_8-3", "7745_8-4", "7745_8-5", "7745_8-6", "7745_8-7", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu")


#cds = newCountDataSet( countTable, condition )
 cds = estimateSizeFactors( cds )
sizeFactors( cds )
cdsFull = newCountDataSet( countTable, pasillaDesign )


# make heatmap from count-table

print R '
cdsFullBlind = estimateDispersions( cdsFull, method = "blind" )
vsdFull = varianceStabilizingTransformation( cdsFullBlind )
library("RColorBrewer")
library("gplots")
select = order(rowMeans(counts(cdsFull)), decreasing=TRUE)[1:30]
hmcol = colorRampPalette(brewer.pal(9, "GnBu"))(100)
heatmap.2(exprs(vsdFull)[select,], col = hmcol, trace="none", margin=c(10, 6))

';


# make heatmap from cluster distances

print R '

dists = dist( t( exprs(vsdFull) ) )
mat = as.matrix( dists )
rownames(mat) = colnames(mat) = with(pData(cdsFullBlind), paste(condition, libType, sep=" : "))
heatmap.2(mat, trace="none", col = rev(hmcol), margin=c(13, 13))

';


# Principal component plot of the samples

print R ' print(plotPCA(vsdFull, intgroup=c("condition", "libType")))

';


pasillaDesign = data.frame(
 row.names = colnames( countTable ), 
 condition = c("aPS", "aPS", "aPS", "MCana", "MCana", "MCana", "MCnoBC", "MCnoBC", "MCnoBC", "MCu", "MCu", "MCu", "MCvitro", "MCvitro", "MCvitro", "MCvivo", "MCvivo", "MCvivo", "naPS", "naPS", "naPS", "PC1-2", "PC1-2", "PC1-2", "PC2", "PC2", "PC2", "PC3", "PC3", "PC3")
, libType = c( "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end", "paired-end", "paired-end",  "paired-end" ) )



condition = c("aPS", "aPS", "aPS", "MCana", "MCana", "MCana", "MCnoBC", "MCnoBC", "MCnoBC", "MCu", "MCu", "MCu", "MCvitro", "MCvitro", "MCvitro", "MCvivo", "MCvivo", "MCvivo", "naPS", "naPS", "naPS", "PC1-2", "PC1-2", "PC1-2", "PC2", "PC2", "PC2", "PC3", "PC3", "PC3")



pasillaDesign = data.frame(  row.names = colnames( countTable ), condition = c("7745_8-3", "7745_8-4", "7745_8-5", "7745_8-6", "7745_8-7", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu", "naPS", "aPS", "PC1", "PC2", "PC3", "MCnoBC", "MCvitro", "MCvivo", "MCanaerob", "MCu") , libType = c( "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end", "paired-end" ) )


cdsFull = newCountDataSet( pasillaCountTable, pasillaDesign )
cdsFull = estimateSizeFactors( cdsFull )
cdsFull = estimateDispersions( cdsFull )
