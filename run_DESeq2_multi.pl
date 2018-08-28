#!/usr/bin/perl -w

use strict;
#use File::Slurp;
#use Cwd;
use Data::Dumper;
use Data::Dump;


my $largest = 0;
my $contig = '';


if (@ARGV < 1) {
	print "\n\nUsage: run_DESeq2_multi.pl merged.reads my.design <included columns> <prefix> <design> <file with genes> \n\n" ;

    print " mz3 script for taking eXpress_read_counts and turning them into a DESeq2 matrix \n\n";
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


# Make the design file 
my @design;
foreach my $ele (@inc) {
	if (exists $des[$ele]) {
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
    #print "DES $ele\t$ne\n";
	}
	else {
	die "Not all your chosen columns exist, try again\n";
}
}



# make the same choice for genes

my @submat;

while (<IN>) {
    chomp;
    #print "$_\n";
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

#__END__




# check the experimental design

my @desi1 = split(/[\*,\+,\:]/, $de);
$desi1[0]=~s/~//;

print "DESI: @desi1\n";


# learn how many factors there are to mind from the design

my $header = shift(@design);
my @head = split(/\t/, $header);

my @ind;
my @indi;
my $i=0;

foreach my $cat (@head) {
	foreach my $ele (@desi1) {

		if ($cat=~/^$ele$/) {
			print "Level $ele is used in the design\n";	
			push(@ind, $ele);	
			push(@indi, $i);
		}
	}
	$i++;
}

print "IND @ind\n";
print "INDI @indi\n";

# get design
my $desi="";
foreach my $el (@ind) {
	if ($el=~/\w+/) {
		$desi = $desi . "\"" . "$el" . "\"\,";
	}
}
$desi =  substr($desi, 0, -1);


my %dist;

foreach my $l (@design) {
	chomp $l;
	my @a = split(/\t/,$l);
	foreach my $i (@indi) {
    		#$dist{$a[$i]}=1;
		#print "$head[$i]$a[$i]\n";
		$dist{"$head[$i]$a[$i]"}=1;
	
	}
}

my $size = scalar keys %dist;


print "Number of elements to search $size\n";
print "Desi :$desi:\n";

foreach my $key (sort keys %dist) {
	print "$key\n";
}



#__END__

# now do DESeq2 commandlines
# this bit is same for all

open (R, ">$pre.R") || die "I can't open $pre.R\n";
print R "\n";
print R "\n";
print R "library(DESeq2)\n";
print R "## Read in data\n";
print R "CountTable = read.table( \"$pre.tab\", header=TRUE, row.names=1 )\n";
print R "design =  read.table( \"$pre.design\", header=TRUE, row.names=1 )\n";
print R "dds<-DESeqDataSetFromMatrix(countData= CountTable,colData= design,design=$de)\n";

print R "## releveling\n";

print R "try(dds\$Date <- factor(dds\$Date))\n";
print R "try(dds\$Donor <- factor(dds\$Donor))\n";
print R "try(dds\$Transformation <- relevel(dds\$Transformation, \"MAF6\"))\n";
print R "try(dds\$Transformation <- relevel(dds\$Transformation, \"ME\"))\n";
print R "try(dds\$Transformation <- relevel(dds\$Transformation, \"Normal\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"CD117pos\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"CD34negCD38neg\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"CD34negCD38pos\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"bulk\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"GMP\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"CMP\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"LMPP\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"MPP\"))\n";
print R "try(dds\$Celltype <- relevel(dds\$Celltype, \"HSC\"))\n";
print R "try(dds\$Date <- relevel(dds\$Date, \"201402\"))\n";
print R "try(dds\$Date <- relevel(dds\$Date, \"201404\"))\n";
print R "try(dds\$Date <- relevel(dds\$Date, \"201503\"))\n";
print R "try(dds\$Date <- relevel(dds\$Date, \"201601\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"UPN001\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"N\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"3\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"2\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"1\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"DJ\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"134\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"139\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"141\"))\n";
print R "try(dds\$Donor <- relevel(dds\$Donor, \"143\"))\n";
print R "try(dds\$Treatment <- relevel(dds\$Treatment, \"shKDM5A\"))\n";
print R "try(dds\$Treatment <- relevel(dds\$Treatment, \"pLKO1\"))\n";
print R "try(dds\$Treatment <- relevel(dds\$Treatment, \"DMSO\"))\n";

print R "\n";




print R "## Starting to test interactions\n";
print R "dds <-DESeq(dds)\n";
print R "resultsNames(dds)\n";



# Get some basic stuff
            print R "## Get some basic data; normalised values and PCA overview\n";
            print R "rld<-rlog(dds)  # do blind=TRUE # not informed by design\n";
            print R "vsd<-varianceStabilizingTransformation(dds) # do blind=TRUE # not informed by design\n";
            print R "rlogMat<-assay(rld)\n";
            print R "vstMat<-assay(vsd)\n";
            print R "write.table(as.data.frame(rlogMat),file=\"$pre.rlogMat.txt\", sep=\"\\t\")\n";
            print R "write.table(as.data.frame(vstMat),file=\"$pre.vstMat.txt\", sep=\"\\t\")\n";
	    print R "pdf(file=\"$pre.all.PCA.pdf\", useDingbats=FALSE)\n";
	    print R "plotPCA(vsd,intgroup=c(\"Sample\",$desi))\n";
	    print R "dev.off()\n\n";



# this bit needs to be repeated for all interactions

my $el = 0;
my $el2 = 0;
foreach my $key (sort keys %dist) {
	$el++;

	foreach my $key2 (sort keys %dist) {
		$el2++;

		if ($el=~/^$el2$/ || $el>$el2) {


			#print "Not $el $el2\n";
		}
		else {
			print R "### Test $el  vs  $el2\n";			
            		print R "\n\n# Starting to test interaction $el $el2\n";
            		print R "\n";
            		#print R "res <- results(dds, contrast=list(c(resultsNames(dds)[$key],resultsNames(dds)[$key2])))\n";
            		print R "res <- results(dds, contrast=list(\"$key\",\"$key2\"), test=\"Wald\")\n";
            		print R "mcols(res, use.names=TRUE)\n";
            		print R "summary(res)\n";
            		print R "resOrdered<-res[order(res\$padj),]\n";
            		print R "write.table(as.data.frame(resOrdered),file=\"$pre.$key.$key2.dat\", sep=\"\\t\")\n";
            		print R "pdf(file=\"$pre.$key.$key2.MA.pdf\", useDingbats=FALSE)\n";
            		print R "plotMA(res,main=\"$pre.$key.$key2\",ylim=c(-2,2))\n";
            		print R "dev.off()\n\n";
			print R "top500<-head(rownames(resOrdered), 500)\n";
			print R "chose <- vsd[top500,]\n";
            		print R "pdf(file=\"$pre.$key.$key2.PCA.pdf\", useDingbats=FALSE)\n";
            		print R "plotPCA(chose,intgroup=c($desi))\n";
            		print R "dev.off()\n\n";
			#print R "dev.off()\n\n";
			#print R "dev.off()\n\n";
			#print R "dev.off()\n\n";
            		#print R "attr(dds,\"betaPriorVar\")\n";
            		#print R "dispersionFunction(dds)\n";
            		#print R "attr(dispersionFunction(dds),\"dispPriorVar\")\n";
			print R "resOrdered <- na.omit(resOrdered)\n";
			print R "# Remove downregulated\n";
            		print R "resOrderedUp <- resOrdered[resOrdered\$log2FoldChange<0,]\n";
			print R "lab <- design\$Sample\n";
			print R "pdf(file=\"$pre.$key.$key2.barplot.up.pdf\", useDingbats=FALSE)\n";
			print R "barplot(assay(vsd)[rownames(head(resOrderedUp,10)),], names.arg=lab, cex.names=0.8, las=2)\n";
			print R "dev.off()\n\n";
			print R "# Remove upregulated\n";
            		print R "resOrderedDown <- resOrdered[resOrdered\$log2FoldChange>0,]\n";
			print R "lab <- design\$Sample\n";
			print R "pdf(file=\"$pre.$key.$key2.barplot.down.pdf\", useDingbats=FALSE)\n";
			print R "barplot(assay(vsd)[rownames(head(resOrderedDown,10)),], names.arg=lab, cex.names=0.8, las=2)\n";
			print R "dev.off()\n\n";

		}

		
	}
	$el2=0;
}



            # do plots
	    print R "## Do diagnostic plots\n";
            print R "\npdf(file=\"$pre.normalisation.pdf\", useDingbats=FALSE)\n";
            print R "par( mfrow = c( 1, 2 ) )\n";
            print R "plot(log2( 1 + counts(dds, normalized=TRUE)[ , 1:2] ),col=rgb(0,0,0,.2), pch=16, cex=0.3)\n";
            print R "plot(assay(rld)[,1:2],col=rgb(0,0,0,.2), pch=16, cex=0.3 )\n";
            print R "dev.off()\n\n";

#=cut
            print R "\n";
            print R "matrix1 <- model.matrix($de, colData(dds))\n";
            print R "matrix1\n";
            print R "write.table(as.data.frame(matrix1),file=\"$pre.matrix.txt\", sep=\"\\t\")\n";





close(R);

system "R CMD BATCH $pre.R  $pre.Rout"; wait;
#print "With more complext interaction you have to run this script in interactive mode\nyour script is $pre.R\nR CMD BATCH $pre.R $pre.Rout\n\n";



exit;










