
# make a correction for GC-content between samples

library(cqn)

data(montgomery.subset)  # matrix with genes, and read counts
data(sizeFactors.subset) # matrix with gene-names and 
data(uCovar) # uCovar is a data frame with 23552 observations on 2 different covariates: gc content and genic length in bp
cqn.subset <- cqn(montgomery.subset, lengths = uCovar$length,
x = uCovar$gccontent, sizeFactors = sizeFactors.subset,
verbose = TRUE)
cqnplot(cqn.subset, n = 1)





library(edgeR)

# read in file and labels
x <- read.delim("test.tab",row.names="ID")

# group lines
group <- factor(c(1,1,2,2))

# calculating library sizes
y <- DGEList(counts=x,group=group)


y <- calcNormFactors(y)
y <- estimateCommonDisp(y)
y <- estimateTagwiseDisp(y)
et <- exactTest(y)
topTags(et)

# the last command gives output


# do GLM analysis instead

# design <- model.matrix(~group)
# y <- estimateGLMCommonDisp(y,design)
# y <- estimateGLMTrendedDisp(y,design)
# y <- estimateGLMTagwiseDisp(y,design)
# fit <- glmFit(y,design)
# lrt <- glmLRT(fit,coef=2)
# topTags(lrt)


# The calcNormFactors function normalizes for RNA composition




