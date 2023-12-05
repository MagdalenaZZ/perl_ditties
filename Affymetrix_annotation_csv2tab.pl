#!/usr/local/bin/perl -w

use strict;
#use Data::Dumper;

unless (@ARGV==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: Affymetrix_annotation_csv2tab.pl Affymetrix.csv

Give the program the  Affymetrix.csv annotation file you want to parse  



'
}

	my $in = shift;	
	my $out = shift;

	open (IN, "<$in") || die "I can't open $in\n";
	my @in = <IN>;
	close (IN);

=pod
#	open (OUT, ">$in.out") || die "I can't open $in.out\n";
#	open (OUT2, ">$in.out.noncoding") || die "I can't open $in.out.noncoding\n";
	

#my %hash;

# Take each line and take the gene-name as a key, and then fill the variable array with annotation

my $header = shift(@in);
$header=~s/ Bi-weight Avg Signal/_Expression/g;	

my @head= split (/\t/, $header);
$head[1]=~s/\s+//g;
$head[2]=~s/\s+//g;	

#print "$header\n";

print OUT  "Gene\tLogFoldChange\tAdj.Pval\t$head[1]\t$head[2]\tTotalProbes\tEntrez\tChromosomePos\tGeneName\tSign\n";

=cut

my @header = (1..1000);

my %h;

my %out;


foreach my $line (@in) {
chomp $line;
	
	if ($line=~/^#%/  || $line=~/^##/  ) {
		# do nothing
	}
       elsif ($line=~/transcript_cluster_id/)	{
	       #print "Header $line\n";
		unshift(@header,  split (/,/, $line));
		foreach my $elem (@header) {
			#print "$elem\n";
			
		}

       }

	else {

		my @arr= split (/\"\,\"/, $line);
	
		my $i=0;
		my $probe =$arr[0];
		$probe=~s/\"//;

		foreach my $elem (@arr) {
			#print "$header[$i]\t$elem\n";

			# Do different things with the different categories
			if ($header[$i]=~/\"gene_assignment\"/) {
				# split by ///
				
				unless ($elem=~/---/){

				my @a = split(/\/\/\//,$elem);
					foreach my $elem2 (@a) {
						my @a3 = split(/\/\//,$elem2);
						$a3[0]=~s/\s+//g;
						#print "$probe\t$elem2\n";
						# get ENSMUST
						#if ($a3[0]=~/ENS/) {
							#$out{$probe}=$a3[0];
							#}
						# Get gene symbol
							#if ($a[1]=~/\w+/) {
							#$out{$probe}=$a3[1];
							#}
						# get gene_number
						if ($a3[4]=~/\w+/) {
							$out{$probe}=$a3[4];
						}

					}
				}

			}
			else {
				$h{$probe}{$header[$i]}="$elem";	
			}
			
			$i++;
		}

		#print "NEXT\n";

	}
	
}



foreach my $key (keys %h) {

	my $koi ="\"gene_assignment\"";
	#print "$key\t$h{$key}{$koi}\n";
}


foreach my $key (sort keys %out) {
	print "$key\t$out{$key}\n";
}


#close (OUT);
#close (OUT2);
exit;



