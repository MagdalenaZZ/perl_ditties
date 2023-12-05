#!/usr/bin/perl -w

use strict;
#use File::Slurp;
#use Cwd;
use Data::Dumper;
use Data::Dump;


my $largest = 0;
my $contig = '';


if (@ARGV < 1) {
	print "\n\nUsage: run_DESeq2.pl merged.reads my.design <included columns> <prefix> <design> <file with genes> \n\n" ;

    print " mz3 script for taking eXpress_read_counts and turning them into a DESeq2 matrix \n\n";
    print "Suitable for interaction terms\n\n";

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

    print "$ele\t$ne\n";
}



# make the same choice for genes

my @submat;

while (<IN>) {
    chomp;
    my @arr = split(/\s+/, $_);
    my @new_arr;
    #print "@new_arr\n";

    foreach my $ele (@inc) {
        #$ele--;
	if (exists $arr[$ele]) {
    		push (@new_arr, $arr[$ele] );
	}
    }

	if (scalar(@new_arr)>0) {
    		my $new = join("\t", @new_arr);
    		#print "$new\n";
    		push(@submat, "$new\n");
	}
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

# check the experimental design

my @desi1 = split(/[\*,\+,\:]/, $de);
$desi1[0]=~s/~//;




#__END__

# now do DESeq2 commandlines
# this bit is same for all

open (R, ">$pre.R") || die "I can't open $pre.R\n";

print R "\n";
print R "\n";
print R "library(DESeq2)\n";

print R "CountTable = read.table( \"$pre.tab\", header=TRUE, row.names=1 )\n";
print R "design =  read.table( \"$pre.design\", header=TRUE, row.names=1 )\n";
print R "dds<-DESeqDataSetFromMatrix(countData= CountTable,colData= design,design=$de)\n";

print R "## releveling\n";
print R "try(dds\$Trans <- relevel(dds\$Trans, \"normal\"))\n";
print R "try(dds\$Cell <- relevel(dds\$Cell, \"LSK\"))\n";
print R "\n";

#write output
print R "rld<-rlog(dds)  # do blind=TRUE # not informed by design\n";
print R "vsd<-varianceStabilizingTransformation(dds) # do blind=TRUE # not informed by design\n";
print R "rlogMat<-assay(rld)\n";
print R "vstMat<-assay(vsd)\n";
print R "write.table(as.data.frame(rlogMat),file=\"$pre.rlogMat.txt\", sep=\"\\t\")\n";
print R "write.table(as.data.frame(vstMat),file=\"$pre.vstMat.txt\", sep=\"\\t\")\n";
print R "pdf(file=\"$pre.all.PCA.pdf\", useDingbats=FALSE)\n";
$de=~s/\~//g;
my @de2 = split(/\*/,$de);
print R "plotPCA(vsd,intgroup=c(\"$de2[0]\"))\n";
print R "dev.off()\n\n";

print R "pdf(file=\"$pre.sample.PCA.pdf\", useDingbats=FALSE)\n";
print R "plotPCA(vsd,intgroup=c(\"Sample\"))\n";
print R "dev.off()\n\n";


# If it is a simple design

if ( scalar(@desi1) <2 ) { 

# this bit needs to be repeated for all interactions

print R "# Starting to test interactions\n";

print R "dds <-DESeq(dds)\n";

print R "read.counts <- counts(dds, normalized=TRUE)\n";
print R "write.table(as.data.frame(read.counts),file=\"$pre.normread.txt\", sep=\"\t\")\n";
print R "resultsNames(dds)\n";


#print R "res <-results(dds, addMLE=TRUE )\n";
=podprint R "res <-results(dds)\n";
print R "mcols(res, use.names=TRUE)\n";
print R "summary(res)\n";
print R "resOrdered<-res[order(res\$padj),]\n";
print R "write.table(as.data.frame(resOrdered),file=\"$pre.dat\", sep=\"\\t\")\n";
#&pathway("$pre");

print R "pdf(file=\"$pre.MA.pdf\", useDingbats=FALSE)\n";
print R "plotMA(res,main=\"DESeq2\",ylim=c(-2,2))\n";
print R "\ndev.off()\n";

print R "resMLE<-results(dds,addMLE=TRUE)\n";

# check specific genes
#print R "pdf(file=\"$pre.43630.pdf\", useDingbats=FALSE)\n";
#print R "plotCounts(dds,gene=43630,intgroup=\"Trans\")\n";
#print R "dev.off()\n\n";
#print R "res[362,]\n";

#print R "matrix1 <- model.matrix($de, colData(dds))\n";
#print R "matrix1\n";
#print R "write.table(as.data.frame(matrix1),file=\"$pre.matrix.txt\", sep=\"\\t\")\n";

# do plots

print R "pdf(file=\"$pre.normalisation.pdf\", useDingbats=FALSE)\n";
print R '
par( mfrow = c( 1, 2 ) )
plot( log2( 1 + counts(dds, normalized=TRUE)[ , 1:2] ), col=rgb(0,0,0,.2), pch=16, cex=0.3 )
plot( assay(rld)[ , 1:2], col=rgb(0,0,0,.2), pch=16, cex=0.3 )
';
print R "dev.off()\n\n";

print R "attr(dds,\"betaPriorVar\")\n";
print R "dispersionFunction(dds)\n";
print R "attr(dispersionFunction(dds),\"dispPriorVar\")\n";

=cut

print "Now starting R... \nR CMD BATCH $pre.R  $pre.Rout\n\n";
system "R CMD BATCH $pre.R  $pre.Rout"; wait;



}


# If it is a multifactorial design
else {




    my @desi2= ("$desi1[0]","$desi1[1]","$desi1[0]:$desi1[1]");
    push(@desi1, "$desi1[0]:$desi1[1]" );
    my $i1=2;
    my $i2=2;

    foreach my $el (@desi1) {
        #print "DESI1 $el\n";
    }
    foreach my $el (@desi2) {
        #print "DESI2 $el\n";
    }

    print R "dds <-DESeq(dds, betaPrior=FALSE)\n";
    print R "read.counts <- counts(dds, normalized=TRUE)\n";
    print R "write.table(as.data.frame(read.counts),file=\"$pre.normread.txt\", sep=\"\t\")\n";

    print R "# Starting to test interactions\n";

#=pod
    foreach my $el (@desi1) {
        $i2=2; 

#=pod
        foreach my $el2 (@desi2) {
# this bit needs to be repeated for all interactions
            
            if ($i1==$i2) {
                $i2++;
                next;
            }
            print R "\n\n# Starting to test interaction $el $el2\n";
            print R "resultsNames(dds)\n";
            print R "\n";

            print R "res <- results(dds, contrast=list(c(resultsNames(dds)[$i1],resultsNames(dds)[$i2])), )\n";
            print R "mcols(res, use.names=TRUE)\n";
            print R "summary(res)\n";
            print R "resOrdered<-res[order(res\$padj),]\n";
            print R "write.table(as.data.frame(resOrdered),file=\"$pre.$el.$el2.dat\", sep=\"\\t\")\n";
            #print "$i1 $i2 $el $el2\n";
#            &pathway("$pre.$el.$el2");
#            print R "write.table(as.data.frame(resOrdered),file=\"$pre.$i.$2.txt\", sep=\"\\t\")\n";
#            #print R "head(resOrdered)\n";
            print R "pdf(file=\"$pre.$el.$el2.MA.pdf\", useDingbats=FALSE)\n";
            print R "plotMA(res,main=\"$pre.$el.$el2\",ylim=c(-2,2))\n";
            print R "dev.off()\n\n";
            print R "attr(dds,\"betaPriorVar\")\n";
            print R "dispersionFunction(dds)\n";
            print R "attr(dispersionFunction(dds),\"dispPriorVar\")\n";
            $i2++;
        }

#=cut

            # Now do the factor separately
            print "name=resultsNames(dds)[$i1] \n";
            print R "res <- results(dds, name=resultsNames(dds)[$i1] )\n";
            print R "mcols(res, use.names=TRUE)\n";
            print R "summary(res)\n";
            print R "resOrdered<-res[order(res\$padj),]\n";
            print R "write.table(as.data.frame(resOrdered),file=\"$pre.$el.int.dat\", sep=\"\\t\")\n";
#            &pathway("$pre.$el.$el2");
#            print R "write.table(as.data.frame(resOrdered),file=\"$pre.$i.$2.txt\", sep=\"\\t\")\n";
#            #print R "head(resOrdered)\n";
            print R "pdf(file=\"$pre.$el.MA.pdf\", useDingbats=FALSE)\n";
            print R "plotMA(res,main=\"$pre.$el\",ylim=c(-2,2))\n";
            print R "\ndev.off()\n";
            print R "attr(dds,\"betaPriorVar\")\n";
            print R "dispersionFunction(dds)\n";
            print R "attr(dispersionFunction(dds),\"dispPriorVar\")\n\n";
           
            $i1++;

         }



            #write output
            print R "rld<-rlog(dds)  # do blind=TRUE # not informed by design\n";
            print R "vsd<-varianceStabilizingTransformation(dds) # do blind=TRUE # not informed by design\n";
            print R "rlogMat<-assay(rld)\n";
            print R "vstMat<-assay(vsd)\n";
            print R "write.table(as.data.frame(rlogMat),file=\"$pre.rlogMat.txt\", sep=\"\\t\")\n";
            print R "write.table(as.data.frame(vstMat),file=\"$pre.vstMat.txt\", sep=\"\\t\")\n";


            # do plots
            print R "\npdf(file=\"$pre.normalisation.pdf\", useDingbats=FALSE)\n";
            print R '
            par( mfrow = c( 1, 2 ) )
            plot(log2( 1 + counts(dds, normalized=TRUE)[ , 1:2] ),
                 col=rgb(0,0,0,.2), pch=16, cex=0.3 )
            plot( assay(rld)[ , 1:2],
                 col=rgb(0,0,0,.2), pch=16, cex=0.3 )
		';
            print R "dev.off()\n\n";
#=cut

            print R "\n";
#            print R "matrix1 <- model.matrix($de, colData(dds))\n";
#            print R "matrix1\n";
#            print R "write.table(as.data.frame(matrix1),file=\"$pre.matrix.txt\", sep=\"\\t\")\n";


}


close(R);

system "R CMD BATCH $pre.R  $pre.Rout"; wait;
#print "With more complext interaction you have to run this script in interactive mode\nyour script is $pre.R\nR CMD BATCH $pre.R $pre.Rout\n\n";



exit;


#############################################################

sub pathway
{

    my $PRE = $_[0];
    print "PRE $PRE\n";
#    print "Not a very interesting routine\n";
#	print "This does the same thing every time\n";
print R " \n";
print R "####### PATHWAY ANALYSIS #######\n";
print R "require(gage)\n";
print R "require(pathview)\n";


# add pathway data
#print R "featureData = read.table( \"mart_export.Mouse_Ensembl2Entrez.txt\", header=TRUE, row.names=1 )\n";
#print R "mcols(dds)<-DataFrame(mcols(dds), featureData)\n";
#print R "resOrd <-data.frame(resOrdered)\n";
#print R "m3 <- merge(resOrd,featureData, by=0  )\n";
#print R "deseq2.fc=m3\$log2FoldChange\n";
#print R "names(deseq2.fc)=m3\$Entrez\n";



# get results
#print R "deseq2.res <- resOrdered\n";
print R "deseq2.fc=resOrdered\$log2FoldChange\n";
print R "names(deseq2.fc)=rownames(resOrdered)\n";
print R "exp.fc=deseq2.fc\n";
print R "out.suffix=\"$PRE\"\n";
print R "kegg.mouse <- kegg.gsets(species=\"mmu\", id.type=\"entrez\")\n";
print R "fc.kegg.p <- gage(exp.fc, gsets = kegg.mouse , ref = NULL, samp = NULL)\n";
print R "write.table(as.data.frame(fc.kegg.p),file=\"$PRE\.gage.txt\", sep=\"\\t\")\n";
print R 'sel.h <- fc.kegg.p$greater[, "q.val"] < 0.2 & !is.na(fc.kegg.p$greater[, "q.val"])';
print R " \n";
print R "path.ids.h <- rownames(fc.kegg.p\$greater)[sel.h]\n";
print R 'sel.l <- fc.kegg.p$less[, "q.val"] < 0.2 & !is.na(fc.kegg.p$less[,"q.val"])';
print R " \n";
print R 'path.ids.l <- rownames(fc.kegg.p$less)[sel.l]';
print R " \n";
print R "path.ids.all <- c(substr(c(path.ids.h, path.ids.l),1,5),\"05202\",\"04550\",\"04310\")\n";
print R "path.ids.all \n";
print R "pathpv.out.list <- sapply(path.ids.all, function(pid) pathview(gene.data = exp.fc, pathway.id = pid,  out.suffix=\"$PRE.gage\", ";
print R 'species = "mmu", low = list(gene = "seagreen3", cpd = "blue"), mid = list(gene = "lightgoldenrod", cpd = "lightgoldenrod"), high = list(gene = "indianred1", cpd ="yellow"), limit=list(gene=20, cpd=20) ))';

print R " \n\n#SPIA\n";
print R "require(SPIA)\n";

print R "sig_genes1 <- subset(resOrdered, padj<0.01)\n";
print R "sig_genes <-sig_genes1\$log2FoldChange\n";
print R "names(sig_genes) <- rownames(sig_genes1)\n";
print R "all_genes <- rownames(dds)\n";
#print R "all_genes <- mcols(dds)\$Entrez\n";
#print R "all_genes <-  as.vector(na.exclude(mcols(dds)\$Entrez))\n";
print R "spia_result <- spia(de=sig_genes, all=all_genes, organism=\"mmu\", plots=FALSE)\n";
print R "spia_result\n";
print R "write.table(as.data.frame(spia_result),file=\"$PRE.spia.txt\", sep=\"\\t\")\n";
print R "try(plotP(spia_result, threshold=0.01)) \n";
print R "sign.spia <- subset(spia_result, pGFdr<0.01) \n";
#print R "sign.spia$ID  \n";
print R "pathpv.out.list <- sapply(sign.spia\$ID , function(pid) pathview(gene.data = exp.fc, pathway.id = pid,  out.suffix=\"$PRE.spia\", ";
print R 'species = "mmu", low = list(gene = "seagreen3", cpd = "blue"), mid = list(gene = "lightgoldenrod", cpd = "lightgoldenrod"), high = list(gene = "indianred1", cpd ="yellow"), limit=list(gene=20, cpd=20) ))';


print R "\n####### END PATHWAY ANALYSIS #######\n\n";



}



#############################################################











__END__





