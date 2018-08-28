#!/usr/local/bin/perl -w

use strict;
#use Data::Dumper;

unless (@ARGV==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: TAC_output_parser.pl all_data.txt


Give the program the TAC all_data.txt export file you want to parse  



'
}

	my $in = shift;	
	my $out = shift;

	open (IN, "<$in") || die "I can't open $in\n";
	my @in = <IN>;
	close (IN);

	open (OUT, ">$in.out") || die "I can't open $in.out\n";
	open (OUT2, ">$in.out.noncoding") || die "I can't open $in.out.noncoding\n";
	

#my %hash;

# Take each line and take the gene-name as a key, and then fill the variable array with annotation

my $header = shift(@in);
$header=~s/ Bi-weight Avg Signal/_Expression/g;	

my @head= split (/\t/, $header);
$head[1]=~s/\s+//g;
$head[2]=~s/\s+//g;	

#print "$header\n";

print OUT  "Gene\tLogFoldChange\tAdj.Pval\t$head[1]\t$head[2]\tTotalProbes\tEntrez\tChromosomePos\tGeneName\tSign\n";

foreach my $line (@in) {
chomp $line;

	my @arr= split (/\t/, $line);

	if ($line=~/^Transcript Cluster ID/) {
		#print "Header $line";
	}
	else {
		my @name;
		$arr[11]=~s/\s+//g;
		
		# Annotate significance
		my $sign;
		if ($arr[7]<0.05 && ($arr[5]>2 || $arr[5]<-2  ) ) {
			$sign="UP";
			if ($arr[5]=~/-/) {
				$sign="DOWN";
			}
		}
		elsif ($arr[7]<0.05 ) {
			$sign="Up";
			if ($arr[5]=~/-/) {
				$sign="Down";
			}
		}
		else{
			$sign="No";
		}

		
			

		if ($arr[8]=~/\;/) {
			@name= split(/\;/,$arr[8]);
		}
		elsif($arr[8]!~/\w+/) {
			#print "$arr[0]\t$arr[6]\t$arr[7]\t$arr[1]\t$arr[2]\t#\t$arr[18]\t$arr[20]\t#\t$arr[9]\n";
			print OUT2 "$arr[0]\t$arr[5]\t$arr[7]\t$arr[1]\t$arr[2]\t$arr[18]\t$arr[20]\t$arr[10]:$arr[11]:$arr[12]\t$arr[9]\t$sign\n";

		}

		else {
			$name[0]=$arr[8];
			print OUT "$name[0]\t$arr[5]\t$arr[7]\t$arr[1]\t$arr[2]\t$arr[18]\t$arr[20]\t$arr[10]:$arr[11]:$arr[12]\t$arr[9]\t$sign\n";
		}

	}
	
}

close (OUT);
close (OUT2);
exit;



