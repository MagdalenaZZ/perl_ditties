#!/usr/bin/perl -w

use strict;


unless (@ARGV == 1) {
        &USAGE;
}



sub USAGE {

    die '


Usage: phyper_in_R.pl in.tab
i.e.


This program takes a custom tab-delimited file, calculates hypergeometric testing on each line and the column sums


    ' . "\n";
}



my $in=shift;
#open (IN, "<$in") || die "I can't open $in\n";
open (R, ">$in.R") || die "I can't open $in.R\n";


print R "fn=\"$in\"\n";


print R '

df  <- read.table(fn, header=F, sep="\t", na="NA", stringsAsFactors=FALSE)
colnames(df) <- c("pass_us","pass_both","pass_us_flags","pass_both_flags")

# Create a rowsum
df[dim(df)[1]+1,] <- colSums(df) 


# Create phyper variables
df$k <- df$pass_us_flags
df$q <- df$pass_us_flags-df$pass_both_flags-1
df$m <- df$pass_both
df$n <- df$pass_us-df$pass_both


# Calculate hypergeometric test and other stats
for (i in  1:dim(df)[1]) {
  df$phype[i] <- phyper(df$q[i], df$m[i], df$n[i], df$k[i], lower.tail = TRUE, log.p = FALSE)
  df$pval[i] <- 1-phyper(df$q[i], df$m[i], df$n[i], df$k[i], lower.tail = TRUE, log.p = FALSE)

}
df$exp <- (df$m/df$pass_us)*df$k
df$enrichment <- (df$q+1)/((df$m/df$pass_us)*df$k)

# Write output
write.table(df,file=paste(fn,"table.txt",sep="."), sep="\t")


';



close(R);

print "R CMD BATCH $in.R >  $in.Rout \n";
`R CMD BATCH $in.R >  $in.Rout `;


exit;









