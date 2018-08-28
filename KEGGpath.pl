#!/usr/bin/perl
use strict;
#use Clone qw(clone);

unless (@ARGV == 3) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/DESeq_postprocess.pl <DESeq2.txt>  <GO-file> <prod-file>



GO-file has this structure:

Gene_ID   <TAB>  GOterm,GOterm,GOterm


Prod file has this structure:

Gene_ID   <TAB>  product


';

}



# check that DESeq ran okay

my $pre = shift;





&pathway("$pre");



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


