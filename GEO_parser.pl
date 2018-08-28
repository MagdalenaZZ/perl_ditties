#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: GEO_parser.pl file 

Takes a GEO series_matrix.txt file and splits it into separate handy files

'
}


	my $in = shift;
	my $out1 = $in . ".metadata";
	my $out2 = $in . ".sample.txt";
	my $out3 = $in . ".data";

if ($in =~ /\.gz$/) {
	#open(IN, “gunzip -c $file |”) || die “can’t open pipe to $file”;
	open (IN, "gunzip -c $in | ") || die "I can't open $in\n";
}
else {
	open (IN, "<$in") || die "I can't open $in\n";
}
	open (OUT1, ">$out1") || die "I can't open $out1\n";
	open (OUT2, ">$out2") || die "I can't open $out2\n";
	open (OUT3, ">$out3") || die "I can't open $out3\n";

# read in all the IDs in the list

my @data;
my %samp;
my @samps;
my $i = 0;
my @head;
$head[0]="ID";
my %seen;
my $add="A";
my $started=0;


while (<IN>) {
	chomp;

	if ($_=~/^\!Series/) {
		push (@data, $_);
	}
	elsif  ($_=~/^\!Sample_title/) {
	#my $line = $_;
		@samps = split(/\t/,$_);
		#print "Samps\n";
		#print @samps;
		my $discard = shift(@samps);

	}
	elsif ($_=~/^\!Sample/) {

		# test if the sample is static or multipe entries
		my @array = split(/\t/,$_);
		my $var = shift(@array);
		if (exists $seen{$var}) {
			$var = $var . "." . $add;
			$add++;
		}
		$seen{$var}=1;
		my %hash = map { $_ => 1 } @array;
		
		#foreach my $key (keys %hash) {
			#print "$var\t$key\t$hash{$key}\n";
			#}
		# Single - add to series data
		if (scalar keys %hash < 2 ) {
			push  (@data, "$var\t$array[0]");
		}
		# Multiple, create a matrix
		else {
			foreach my $elem (@array) {
				#$samp{$samps[$i]}{$var}=$elem;
				$var=~s/\!//;
				$samp{$samps[$i]}{$var}=$elem;
				$i++;
				if ($i==1) {
					$var=~s/\!//;
					push (@head, $var);
				}
			}
			$i=0;	
		}
	}

	elsif ($_=~/^\!series_matrix_table_begin/) {
		$started =1;
	}
	elsif ($_=~/^\!series_matrix_table_end/) {
		# do nothing
	}
	elsif ($started>0) {
		$_=~s/\"//g;
		print OUT3 "$_\n";
	}

	# Series matrix
	else {
		print "Discarded line:\n$_\n";
	}

}

close (IN);

# Now print the metadata

foreach my $ele (@data) {
	print OUT1 "$ele\n";
}

# Now print the sample matrix

foreach my $eleme (@head) {
print OUT2 "$eleme\t";
}
print OUT2 "\n";

#my $j=0;

foreach my $key (sort keys %samp) {
	print OUT2 "$key\t";

	#print  "$key\n";


	foreach my $e (@head) {
		if (exists $samp{$key}{$e} ) {
			$samp{$key}{$e} =~s/\s+/_/g;
			$samp{$key}{$e} =~s/\"//g;
			print OUT2 "$samp{$key}{$e}\t";
				}
		else {
			#print "\nNot $e\n";
		}
		#$j++;
	}
	print OUT2 "\n";

#	foreach my $key2 (keys %{$samp{$key}}) {
	
#		print "";
#	}


}


close (OUT1);
close(OUT2);
close(OUT3);


system `perl ~/bin/perl/GEO_make_pheno.pl $out2 `;


exit;

