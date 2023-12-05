#!/usr/bin/perl -w

use strict;


unless (@ARGV > 2) {
        &USAGE;
}



sub USAGE {

    die '


Usage: genomewide_in_R.pl <windowsize> <stepsize> in.table

i.e.


This program takes a file with genome-wide density data, and makes a sliding window correction on it

in.table = has header and column names


    ' . "\n";
}



my $ws=shift;
my $ss= shift;
my $in= shift;


my $reps =`head -2 $in| tail -1 | awk '{print NF}'`;
chomp $reps;
#print "REPS:$reps:\n";

open (IN, "<$in") || die "I can't open $in\n";
open (OUT, ">$in.$ws.$ss.gw") || die "I can't open $in.$ws.$ss.gw\n";


my $wi=0;
my $si=0;


my @head1;
my @same1 = (0)x($reps-1);
#my @both;
my $rows=0;

my $first = <IN>;
print OUT "$first";

foreach my $l (<IN>) {
chomp $l;
#print "$rows\t$ws\n";	
my @same =@same1;
my @head =@head1;

	if ($rows==($ws)) {
		#print "Printres\n";
		# print results
		print OUT "$head[0]\t";
		my $same = join("\t",@same);
		print OUT "$same\n";

		# set to 0 again
		my @head;
		my @same = (0)x($reps-1);
		$rows=0;
		#print "@same\n";

		#print "Else 1\n";
		my @a = split("\t",$l);
		my $head = shift(@a);
		push (@head,$head);
		my $i=0;
		#print "@same\n";

		foreach my $val (@a) {
			#print "$head\t$i\t$val\n";
			$same[$i]=$same[$i]+$val;
			$i++;		
		}
		#print "@same\n";
		@same1=@same;
		@head1 =@head;

	}
	else {
# foreach line, split and read in-values
		#print "Else 2\n";
		my @a = split("\t",$l);
		my $head = shift(@a);
		push (@head,$head);
		my $i=0;
		#print "@same\n";

		foreach my $val (@a) {
			#print "$head\t$i\t$val\n";
			$same[$i]=$same[$i]+$val;
			$i++;		
		}
		#print "@same\n";
		@same1=@same;
		@head1 =@head;
	# check if window has reached maximum
		# if it has; print values
	# if not, keep adding
	# check if step size has reached maximum
	}
$rows++;
}


# Make output

##my $n=0;

#fo#reach my
##print "@";




close(OUT);




__END__


print R "library(zoo)\nlibrary(ggplot2)\n";

print R "windowlength <- $ws \n stepsize <- $ss \n";

print R "snps<-read.table(\"$in\", header=TRUE, row.names=1,  sep=\"\\t\")\n";


print R '


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
';


my $i = 1;

while ($i< ($reps-1)) {
	
	print R "geom_point(aes(y= snpb[,$i]), color=cols[$i], alpha = 5/5, shape=46) + \n"; 
	$i++;
}

print R  "geom_point(aes(y= snpb[,$i]), color=cols[$i], alpha = 5/5, shape=46) \n"; 


#save plot

print R " fn = paste (\"$in\" , \".gw.pdf\", sep=\"\")\n";
print R 'ggsave(filename=fn, plot=snpDensity)

';

close(R);

print "R CMD BATCH $in.R >  $in.Rout \n";


exit;

__END__











