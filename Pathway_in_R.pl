#!/usr/bin/perl -w

use strict;
#use File::Slurp;
#use Cwd;
use Data::Dumper;
use Data::Dump;


my $largest = 0;
my $contig = '';


if (@ARGV < 1) {
	print "\n\nUsage: Pathway_in_R.pl log2fold.dat <prefix>  <species>  <pathways> \n\n" ;

    print " mz3 script for taking results.dat from DESeq and doing KEGG pathway analysis \n\n";
    print "Suitable for interaction terms\n\n";
    print "kegg pathways in the format for instance 04310 04550\n\n";
    print "Example: perl ~/bin/perl/Pathway_in_R.pl Cell-type.dat Resname  mmu 04310 04550\n\n";
    print "Example: perl ~/bin/perl/Pathway_in_R.pl HSC_vs_CMP.dat test hsa 04310 04550\n\n";
    print "Expects Ensembl IDs, but that can be changed using pathview(gene.idtype=\"xxx\")\n";

    print "Verify the re-leveling strategy!!!\n";
	exit ;
}


my $file = shift;
my $pre = shift;
my $species = shift;
my @paths = @ARGV;

open (R, ">$pre.R") || die "I can't open $pre.R\n";

print R "resOrdered <- read.table( \"$file\", header=TRUE, row.names=1 )\n";

print R " \n";
print R "####### PATHWAY ANALYSIS #######\n";
print R "require(gage)\n";
print R "require(pathview)\n";

# get results
#print R "deseq2.res <- resOrdered\n";
print R "library(org.Hs.eg.db)\n";
print R "resOrdered\$entrez <- mget(rownames(resOrdered), revmap(org.Hs.egENSEMBL),ifnotfound=NA)\n";
print R "mg <- mget(rownames(resOrdered), revmap(org.Hs.egENSEMBL),ifnotfound=NA)\n";
print R "mg <- data.frame(mg = unlist(mg))\n";
print R "deseq2.fc <- as.data.frame(resOrdered\$log2FoldChange)\n";
print R "row.names(deseq2.fc)=row.names(resOrdered)\n";
print R "deseq2.fc\$ID <- row.names(deseq2.fc)\n";
print R "mg\$ID <- row.names(mg)\n";
print R "mg2 <- as.data.frame(merge(deseq2.fc, mg, by.x=\"ID\", by.y=\"ID\", sort=FALSE))\n";
print R "row.names(mg2) <- mg2\$ID\n";
print R "deseq2.fc<- as.data.frame(mg2\$`resOrdered\$log2FoldChange`)\n";
print R "row.names(deseq2.fc) <- mg2\$mg\n";
print R "exp.fc <- deseq2.fc\n";
print R "out.suffix=\"$pre\"\n";
print R "kegg.mouse <- kegg.gsets(species=\"$species\", id.type=\"entrez\")\n";
print R "fc.kegg.p <- gage(exp.fc, gsets = kegg.mouse , ref = NULL, samp = NULL)\n";
print R "write.table(as.data.frame(fc.kegg.p),file=\"$pre\.gage.txt\", sep=\"\\t\")\n";
print R 'sel.h <- fc.kegg.p$greater[, "q.val"] < 0.2 & !is.na(fc.kegg.p$greater[, "q.val"])';
print R " \n";
print R "path.ids.h <- rownames(fc.kegg.p\$greater)[sel.h]\n";
print R 'sel.l <- fc.kegg.p$less[, "q.val"] < 0.2 & !is.na(fc.kegg.p$less[,"q.val"])';
print R " \n";
print R 'path.ids.l <- rownames(fc.kegg.p$less)[sel.l]';
print R " \n";
#print R "path.ids.all <- c(substr(c(path.ids.h, path.ids.l),1,5),\"05202\",\"04550\",\"04310\")\n";
print R "path.ids.all <- c(substr(c(path.ids.h, path.ids.l),1,5)";
foreach my $elem (@paths) {
    	chomp $elem;
	if($elem=~/\w+/) {
		print R "\,\"$elem\"";
    }
}
print R ")\n";
print R "path.ids.all \n";
print R "max<- max(na.omit(deseq2.fc))\n";
print R "pathpv.out.list <- sapply(path.ids.all, function(pid) pathview(gene.data = exp.fc, pathway.id = pid, gene.idtype=\"entrez\", out.suffix=\"$pre.gage\", ";
print R "species = \"$species\", high = list(gene = \"seagreen3\", cpd = \"blue\"), mid = list(gene = \"lightgoldenrod\", cpd = \"lightgoldenrod\"), low = list(gene = \"indianred1\", cpd =\"yellow\"), limit=list(gene=max, cpd=20) ))\n";

print R " \n\n#SPIA\n";
print R "require(SPIA)\n";
print R "rownames(resOrdered) <- getGenes(resOrdered, fields=\"entrezgene\")\$entrezgene\n";

# Have to fix this bit with translating ensembl gene names to entrez IDs

print R "sig_genes1 <- subset(resOrdered, padj<0.01)\n";
print R "sig_genes <-sig_genes1\$log2FoldChange\n";
print R "names(sig_genes) <- rownames(sig_genes1)\n";
print R "all_genes <- rownames(resOrdered)\n";
#print R "all_genes <- mcols(dds)\$Entrez\n";
#print R "all_genes <-  as.vector(na.exclude(mcols(dds)\$Entrez))\n";
print R "spia_result <- spia(de=sig_genes, all=all_genes, organism=\"$species\", plots=FALSE)\n";
print R "spia_result\n";
print R "write.table(as.data.frame(spia_result),file=\"$pre.spia.txt\", sep=\"\\t\")\n";
print R "try(plotP(spia_result, threshold=0.01)) \n";
print R "sign.spia <- subset(spia_result, pGFdr<0.01) \n";
#print R "sign.spia$ID  \n";
print R "pathpv.out.list <- sapply(sign.spia\$ID , function(pid) pathview(gene.data = exp.fc, pathway.id = pid, gene.idtype=\"entrez\", out.suffix=\"$pre.spia\", ";
print R "species = \"$species\", high = list(gene = \"seagreen3\", cpd = \"blue\"), mid = list(gene = \"lightgoldenrod\", cpd = \"lightgoldenrod\"), low = list(gene = \"indianred1\", cpd =\"yellow\"), limit=list(gene=max, cpd=20) ))\n";


print R "\n####### END PATHWAY ANALYSIS #######\n\n";






system "R CMD BATCH $pre.R > $pre.Rout";



exit;


#############################################################


