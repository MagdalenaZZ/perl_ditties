library(zoo)
library(ggplot2)
windowlength <- 1000 
 stepsize <- 999 
snps<-read.table("all.PAED2.depths3.chrM.tab", header=TRUE, row.names=1,  sep="	")



# column scaling

#snps <- as.data.frame(scale(snps, center=FALSE,scale=0.0001*colSums(snps)))
snps <- as.data.frame(scale(snps, center=FALSE,scale=colMeans(snps)))

# sliding window
snpb <- as.data.frame(rollapply(snps,windowlength,mean,align="center",by=stepsize, by.column = TRUE))

# Chromosome names
snpb$Chromosome <-  rep(rownames(snps)[1], dim(snpb)[1])
snpb$start <- seq(0,  by = stepsize, length.out=dim(snpb)[1])+windowlength/2

#snps$start <- as.numeric(str_split_fixed(rownames(snps), "_", 2)[,2])
#snps$Chromosome <- str_split_fixed(rownames(snps), "_", 2)[,1]

# Create random colours
ncolls <- dim(snps)[2]
cols <- rgb(runif(ncolls),runif(ncolls),runif(ncolls)) 


# create plot

snpDensity<-ggplot(snpb, aes(x=start))  + 
facet_wrap(~ Chromosome,ncol=2) + xlab("Position in the genome") +  
ylab("Depth") + 
scale_fill_discrete(name="Experimental Condition", labels=colnames(snpb)) +
geom_point(aes(y= snpb[,1]), color=cols[1], alpha = 5/5, shape=46) 
 fn = paste ("all.PAED2.depths3.chrM.tab" , ".gw.pdf", sep="")
ggsave(filename=fn, plot=snpDensity)

