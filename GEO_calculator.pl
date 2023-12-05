
#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==2) {
        &USAGE;
}


sub USAGE {

die 'Usage: GEO_calculator.pl GEOnumber <matrix-factor>

Takes a GEO number, downloads the series_matrix.txt file and calculates DE


Example:


perl ~/bin/perl/GEO_calculator.pl GSE17740 dryrun 


for matrix-factor, you can pass two different things:
		1. The word "dryrun"; if you do, it will only print the variable table for the samples, so you can decide which parameters to compare
		2. A file which contains the groups you want to look at



If the annotation is not downloaded, download the soft-formatted version of the annotation from here:
ftp://ftp.ncbi.nlm.nih.gov/geo/platforms/
download.file("ftp://ftp.ncbi.nlm.nih.gov/geo/platforms/GPL2nnn/GPL2873/soft/GPL2873_family.soft.gz", "GPL2873_family.soft.gz", mode = "w", quiet = TRUE, method = getOption("download.file.method.GEOquery")) 

Read in the file as a GPL object like this:
GPL14943_family <- getGEO(filename="/Users/mzarowiecki/Desktop/Metastatic/GPL14943_family.soft"

To load in the gene set, just do this:
gset <- getGEO(filename="GSE25771-GPL4093_series_matrix.txt.gz")


'
}

### This is to get the actual CEL-files ############
### a <- getGEOSuppFiles('GSM1137')


my $geonum=shift;
my $filename = $geonum . "_series_matrix.txt.gz";
my $variable=shift;

open (R, ">$geonum.R") || die "I can't open $geonum.R\n";


print R "\n
#If the annotation is not downloaded, download the soft-formatted version of the annotation from here:\n
#ftp://ftp.ncbi.nlm.nih.gov/geo/platforms/\n
#download.file(\"ftp://ftp.ncbi.nlm.nih.gov/geo/platforms/GPL2nnn/$geonum/soft/$geonum\_family.soft.gz\", \"$geonum\_family.soft.gz\", mode = \"w\", quiet = TRUE, method = getOption(\"download.file.method.GEOquery\")) \n
\n
#Read in the file as a GPL object like this:\n
#GPL <- getGEO(filename=\"/Users/mzarowiecki/Desktop/Metastatic/$geonum\_family.soft\" \n

";


print R '

################################################################
#   Differential expression analysis with limma
library(Biobase)
library(GEOquery)
library(limma)
library(ggplot2)

# load series and platform data from GEO

';





# only download the gene set if it doesn't already exist in folder
#if (-f $filename) {
	#print R "gset <- getGEO(filename=\"$filename\") ";
#}
#else {
	print "Downloading data\n";
	print R "gset <- getGEO(\"$geonum\", GSEMatrix =TRUE, AnnotGPL=TRUE, destdir=\".\")\n";
	print R "# try(getGEOSuppFiles(\"$geonum\"))\n";  # this get supplementary files, which sometimes can be very big
	#}


my @platform = split(/\s+/, `gzcat $filename | grep \!Series_platform_id`);
$platform[1]=~s/\"//g;
#print ":$platform[1]:\n";

print R "if (length(gset) > 1) idx <- grep(\"$platform[1]\", attr(gset, \"names\")) else idx <- 1\n";
print R "gset <- gset[[idx]]\n";


# Do a dryrun, or get the full data

if ($variable=~/dryrun/) {

	print R "colnames(gset\@phenoData\@data)\n";
	print R "summary(gset\@phenoData\@data)\n";
	print R "write.table(as.data.frame(gset\@phenoData\@data),file=\"$geonum.pheno\", sep=\"\\t\")\n";

	# Now make a list of characters to work with
	print R "for (i in 1:dim(gset\@phenoData\@data)[2]) { if(length(levels(gset\@phenoData\@data[,i]))>1) {write.table(levels(gset\@phenoData\@data[,i]), file=paste(\"$geonum\", colnames(gset\@phenoData\@data)[i], i,\"pheno\",sep=\'.\'), sep=\"\\t\") }}\n"; 

	#print R "dfl = getGSEDataTables(\"$geonum\")\n";
#	print R "lapply(dfl,head)\n";
	close(R);
	system "R CMD BATCH $geonum.R > $geonum.Rout";
	system "perl ~/bin/perl/GEO_parser.pl $filename";
	print "Read this file to decide which factor to use:\ncat $filename.sample.txt\ncat $geonum.pheno\n";
	exit;
}






print R '

# make proper column names to match toptable 
fvarLabels(gset) <- make.names(fvarLabels(gset))
';


# Create list of characters
my @a = split(/\./, $variable);
print R "x <- as.vector(gset\@phenoData\@data[,$a[-2]])\n";
print R "des <- read.table(\"$variable\", header=FALSE)\n";
# Translate those
print R "y <- des\$V1\nnames(y) <- des\$V2\nsml <- as.vector(y[x[x%in%names(y)]])\n";



print R '

# group names for all samples
#gsms <- "000000222222111111XXXXXXXXXXXXXXXXX"
#sml <- c()
#for (i in 1:nchar(gsms)) { sml[i] <- substr(gsms,i,i) }

key <- t(rbind(rownames(gset@phenoData@data),y[x[x%in%names(y)]], names(y[x[x%in%names(y)]])))
rownames(key)<- rownames(gset@phenoData@data)
colnames(key) <- c("ID","Character", "Treatment")

';

print R "fn <- paste(\"$geonum\", \"design.txt\" , sep='.')\n";


print R '

write.table(as.data.frame(key), file=fn, row.names=F, sep="\t")
#dev.off()


# Eliminate invariant genes
######### TODO ########


# log2 transform
ex <- exprs(gset)
exprs(gset)[1:5,1:5]
qx <- as.numeric(quantile(ex, c(0., 0.25, 0.5, 0.75, 0.99, 1.0), na.rm=T))
LogC <- (qx[5] > 100) ||
          (qx[6]-qx[1] > 50 && qx[2] > 0) ||
          (qx[2] > 0 && qx[2] < 1 && qx[4] > 1 && qx[4] < 2)
if (LogC) { ex[which(ex <= 0)] <- NaN
  exprs(gset) <- log2(ex) }
exprs(gset)[1:5,1:5]

# make PCA
#
#labels
v <- paste(key[,2],key[,3], sep='.')
#v <- v[order(v)]
#lab <- v[!duplicated(v)]
pca <- prcomp(as.matrix(t(na.omit(ex))), scale=TRUE)
scores <- data.frame(v, pca$x[,1:3])
pca.scores <- qplot(x=PC1, y=PC2, data=scores, colour=factor(v), size=I(6))

';

print R "fn <- paste(\"$geonum\", \"$variable\", \"PCA_all.pdf\" , sep='.')\n";


print R '

pdf(file=fn, useDingbats=FALSE)
plot(pca.scores, size=5)
dev.off()

# eliminate samples marked as "X"
sel <- which(sml != "x")
sml <- sml[sel]
gset <- gset[ ,sel]




# make a new PCA

ex <- exprs(gset)
des
x
y
key <-  key[sel,]
#key <- t(rbind(rownames(gset@phenoData@data),y[x[x%in%names(y)]], names(y[x[x%in%names(y)]])))
rownames(key)<- rownames(gset@phenoData@data)
colnames(key) <- c("ID","Character", "Treatment")

#labels
v <- paste(key[,2],key[,3], sep='.')
#v <- v[order(v)]
#lab <- v[!duplicated(v)]
pca <- prcomp(as.matrix(t(na.omit(ex))), scale=TRUE)
scores <- data.frame(v, pca$x[,1:3])
pca.scores <- qplot(x=PC1, y=PC2, data=scores, colour=factor(v), size=I(6))

';

print R "fn <- paste(\"$geonum\", \"$variable\" , \"PCA.pdf\" , sep='.')\n";


print R '

pdf(file=fn, useDingbats=FALSE)
plot(pca.scores, size=5)
dev.off()




# set up the data and proceed with analysis
sml <- paste("G", sml, sep="")    # set group names
fl <- as.factor(sml)
gset$description <- fl
design <- model.matrix(~ description + 0, gset)
colnames(design) <- levels(fl)
fit <- lmFit(gset, design)


';

# Make all against all
#

print R "list = ''\n";
print R "k <- 0\n";
print R "for (i in 1:length(levels(fl))) { for (j in 1:length(levels(fl))) { if (i!=j) { k<-k+1; list[k]=paste(levels(fl)[i],\"-\",levels(fl)[j],sep=\'\'  ) }}}\n";
print R '

astr=paste(list, collapse=",")
astr
prestr="makeContrasts("
poststr=",levels=design)"
commandstr=paste(prestr,astr,poststr,sep="")
commandstr
cont.matrix <- eval(parse(text=commandstr))
cont.matrix

';
print R "\n";



#print R "cont.matrix <- makeContrasts(list, levels=design)\n";
#cont.matrix <- makeContrasts(G2-G0, G1-G0, G2-G1, levels=design)

print R '
fit2 <- contrasts.fit(fit, cont.matrix)
fit2 <- eBayes(fit2, 0.01)


#tT <- topTable(fit2, adjust="fdr", sort="p")
#tT <- subset(tT, select=c("ID","adj.P.Val","P.Value","F","Gene.symbol","Gene.title"))
';
print R "fn <- paste(\"$geonum\", \"$variable\" , \"res.txt\" , sep='.')\n";


print R '
write.fit(fit2, file=fn, adjust="BH", method="separate" )
#write.table(tT, file=fn, row.names=F, sep="\t")
#dev.off()

';

print R "for (i in 1:dim(fit2\$contrasts)[2]) { fn = paste(\"$geonum\", \"$variable\" , list[i], \"fit.txt\", sep=\'.\'); write.table(topTable(fit2, number=100000, coef=i)[,c(22:27,3,2)], file =fn, sep=\"\t\") }";


print R '

################################################################
#   Boxplot for selected GEO samples

# group names for all samples in a series

#gsms <- "000000222222111111XXXXXXXXXXXXXXXXX"
#sml <- c()
#for (i in 1:nchar(gsms)) { sml[i] <- substr(gsms,i,i) }
#sml <- paste("G", sml, sep="")  set group names

# eliminate samples marked as "X"
#sel <- which(sml != "X")
#sml <- sml[sel]
#gset <- gset[ ,sel]

# order samples by group
ex <- exprs(gset)[ , order(sml)]
sml <- sml[order(sml)]
fl <- as.factor(sml)

';


#  labels <- c("small","large","medium")

print R '

labels <- fl

# set parameters and draw the plot
palette(c("#dfeaf4","#f4dfdf","#f2cb98", "#AABBCC")) ### populate with random colour vector
dev.new(width=4+dim(gset)[[2]]/5, height=6)
par(mar=c(2+round(max(nchar(sampleNames(gset)))/2),4,2,1))
';

print R "title <- paste (\"$geonum\", \'/\', annotation(gset), \" selected samples\", sep =\'\') \n";

print R "fn <- paste(\"$geonum\", \"$variable\" , \"box.pdf\" , sep='.')\n";



print R '

pdf(file=fn, useDingbats=FALSE)
boxplot(ex, boxwex=0.6, notch=T, main=title, outline=FALSE, las=2, col=fl)
dev.off()

lab <- v[!duplicated(v)]
lab
#legend("topleft", as.vector(lab), fill=palette(), bty="n")

#dev.off()

system("rm -f Rplot*")

';


print "\n\nR CMD BATCH $geonum.R > $geonum.Rout \n\n";

exit;





