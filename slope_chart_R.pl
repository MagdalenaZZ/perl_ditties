#!/usr/bin/perl -w
use strict;

unless (@ARGV == 1) {
        &USAGE;
}


sub USAGE {

    die '


Usage: slope_chart_R.pl in.tab
i.e.

This program takes a custom tab-delimited file, and creates a slope chart


    ' . "\n";
}



my $in=shift;
#open (IN, "<$in") || die "I can't open $in\n";
open (R, ">$in.R") || die "I can't open $in.R\n";


print R "fn <- paste(\"$in\",\"pdf\",sep=\".\")\nfn\n";


print R '
library(ggplot2)
library(scales)
';

print R "df2<-read.table(\"$in\",header=T, sep=\"\\t\") \n";

print R '
p2 <- ggplot(df2) + geom_segment(aes(x=0.5, xend=1, y=merge, yend=mergef, col=VAF), size=.75, show.legend=T) +
  scale_colour_manual(values=c("red","orange","yellow","lightgreen","darkgreen","blue","purple")) +
  geom_vline(xintercept=0.5, linetype="dashed", size=.1) + 
  geom_vline(xintercept=1, linetype="dashed", size=.1) +
  labs(x="", y="PASS for different VAF") + 
  xlim(0, 1.5) + ylim(0,(1.1*(max(df2$merge, df2$mergef)))) + # X and Y axis limits
 theme(axis.text=element_text(size=14), axis.title=element_text(size=20)) +
 theme_bw()

# Add texts
#p2 <- p2 + geom_text(label=left_label, y=df2$merge, x=rep(1, NROW(df2)), hjust=1.1, size=3.5)
#p2 <- p2 + geom_text(label=right_label, y=df2$mergef, x=rep(2, NROW(df2)), hjust=-0.1, size=3.5)
p2 <- p2 + geom_text(label="Normal", x=0.5, y=1.1*(max(df2$merge, df2$mergef)), hjust=1.2, size=5)  # title
p2 <- p2 + geom_text(label="High", x=1, y=1.1*(max(df2$merge, df2$mergef)), hjust=-0.1, size=5)  # title  
  

p2 + theme(panel.background = element_blank(), 
          panel.grid = element_blank(),
          axis.ticks = element_blank(),
          axis.text.x = element_blank(),
          panel.border = element_blank(),
          plot.margin = unit(c(1,2,1,2), "cm"))

';

print R "ggsave(fn, plot =p2)\n";


close(R);

print "R CMD BATCH $in.R >  $in.Rout \n";
`R CMD BATCH $in.R >  $in.Rout `;


exit;

