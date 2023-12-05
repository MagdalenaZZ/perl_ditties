#!/usr/bin/perl
use strict;
#use Clone qw(clone);

unless (@ARGV == 2) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/Manhattan_in_R.pl gene.list  EnsDB.pack


Example:   perl ~/bin/perl/Manhattan_in_R.pl  genes.lfc  EnsDb.Hsapiens.v86

gene.list has:
Gene_name <TAB> value




';

}

my $list = shift;
my $db = shift;


open (R, ">$list.R") || die "I can't open $list.R\n";


print R '

# source any packages you need
#source("https://bioconductor.org/biocLite.R")
#biocLite("ensembldb")
#biocLite("Gviz")
';


# Get the libraries
print R '
library(Gviz)
library("ensembldb")
source("~/bin/Manhattan.R")

';

# Get the right annotation library
print R "#biocLite(\"$db\")\n";
print R "library(\"$db\")\nedb <- $db\n";

# Read in the table
print R "tab <- read.table( \"$list\", header=TRUE, row.names=1 )\n";

#tab <- read.table( "Manhattan/WTvsp53.WT.KO.dat.manh", header=TRUE, row.names=1 )
#tab <- read.table( "Manhattan/p53vsp53ATRX.p53.p53ATRX.dat.manh", header=TRUE, row.names=1 )
#tab <- read.table( "Manhattan/WTvsp53.WT.KO.dat.manh", header=TRUE, row.names=1 )

# Pick annotation and save to genes, 
print R '
genes <- genes(edb,columns = c("seq_name", "gene_seq_start", "gene_seq_end","gene_name"),return.type = "DataFrame")

# Mark whole chromosomes
#chrs <- as.data.frame(select(edb,keytype ="SEQNAME",column=c("SEQNAME","SEQLENGTH")))
#chrs2 <-chrs
#chrs$SEQLENGTH = 1
#chrs3 <- as.data.frame(rbind(chrs,chrs2))


rownames(genes) <- genes$gene_id

# Attach annotation to gene-list
for(i in 1:dim(tab)[1]) {
	gene <- rownames(tab)[i]
	tab$chr[i] <-genes[gene,1]
	tab$start[i] <-genes[gene,2]
	tab$end[i] <-genes[gene,3]	
}

# Remove empty values
tab <- na.omit(tab)
#man <- merge(tab, genes, by = intersect(genes$gene_id,tab$baseMean ), all=FALSE, sort=FALSE)

tab$mid = tab$end - tab$start
colnames(tab) <- c("val","chr","start","end","mid")

#ann<-annotateSNPRegions(rownames(tab), tab$chr,tab$mid,tab$val, c("ENSG00000091129", "ENSG00000284523"), labels=c("GENE1","GENE2"), col="blue",kbaway=1)

tab$chr <- as.factor(tab$chr)

# Sort the chromosomes and genes
try(tab$chr <- relevel(tab$chr,"M"))
try(tab$chr <- relevel(tab$chr,"MT"))
try(tab$chr <- relevel(tab$chr,"Y"))
try(tab$chr <- relevel(tab$chr,"X"))
try(tab$chr <- relevel(tab$chr,"23"))
try(tab$chr <- relevel(tab$chr,"22"))
try(tab$chr <- relevel(tab$chr,"21"))
try(tab$chr <- relevel(tab$chr,"20"))
try(tab$chr <- relevel(tab$chr,"19"))
try(tab$chr <- relevel(tab$chr,"18"))
try(tab$chr <- relevel(tab$chr,"17"))
try(tab$chr <- relevel(tab$chr,"16"))
try(tab$chr <- relevel(tab$chr,"15"))
try(tab$chr <- relevel(tab$chr,"14"))
try(tab$chr <- relevel(tab$chr,"13"))
try(tab$chr <- relevel(tab$chr,"12"))
try(tab$chr <- relevel(tab$chr,"11"))
try(tab$chr <- relevel(tab$chr,"10"))
try(tab$chr <- relevel(tab$chr,"9"))
try(tab$chr <- relevel(tab$chr,"8"))
try(tab$chr <- relevel(tab$chr,"7"))
try(tab$chr <- relevel(tab$chr,"6"))
try(tab$chr <- relevel(tab$chr,"5"))
try(tab$chr <- relevel(tab$chr,"4"))
try(tab$chr <- relevel(tab$chr,"3"))
try(tab$chr <- relevel(tab$chr,"2"))
try(tab$chr <- relevel(tab$chr,"1"))


tab <- tab[order(tab[,2],tab[,4]),]

';

# Write one pdf for all

print R	"fn <- paste(\"$list\",\".chr\", \"ALL\" , \".manhattan.pdf\",sep=\'\')\n";

print R '
	pdf(file=fn, useDingbats=FALSE)
	print(manhattan.plot(tab$chr,tab$start,tab$val,cex=0.1, col=c("orange","blue"),sig.level=0,should.thin=F, ylim=c(-15,15),pch =1 ))
	dev.off()
';


# Write a pdf for each chromosome
print R ' 
for(i in 1:length(levels(as.factor(tab$chr)))) {
	subtab <-tab[tab$chr==levels(as.factor(tab$chr))[i],]
';
print R	"fn <- paste(\"$list\",\".chr\", levels(as.factor(tab\$chr))[i] , \".manhattan.pdf\",sep=\'\')\n";
print R '
	pdf(file=fn, useDingbats=FALSE)
	print(manhattan.plot(subtab$chr,subtab$start,subtab$val,cex=0.5, col=c("blue","orange"),sig.level=0,should.thin=F, ylim=c(-15,15),pch =1 ))
	plot(runmed(subtab$val,93), pch=20, cex=0.5,col="darkgreen")
	abline(a=0,b=0)
	dev.off()
}




';




print "\nR CMD BATCH $list.R > $list.Rout\n\n";


exit;


__END__



# Other plot


gwasRes <- cbind(tab$chr,tab$chr,tab$start,tab$val)
colnames(gwasRes) <- colnames(gwasResults)
gwasRes <- as.data.frame(gwasRes)
as.data.frame(table(gwasRes$CHR))

gwasRes <- within(gwasRes, levels(CHR)[levels(CHR) == "X"] <- "23")
gwasRes <- within(gwasRes, levels(CHR)[levels(CHR) == "Y"] <- "24")
gwasRes$CHR <- as.numeric(gwasRes$CHR)
gwasRes$BP <- as.numeric(gwasRes$BP)
gwasRes$P <- as.numeric(gwasRes$P)



