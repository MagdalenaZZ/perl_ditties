#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >2) {
        &USAGE;
}


sub USAGE {

die 'Usage:  CSV_to_tab.pl input.file <inputsep> <outputsep>

Takes a file and keeps together the 



'
}


	my $in = shift;
	my $insep=shift;
	my $outsep=shift;

	my $out = $in . ".sep";

	print ":$insep: :$outsep:\n";

# complain if input or output separators are ' or "
if ($insep=~/\'|\"/ || $outsep=~/\'|\"/ ) {
	        &USAGE;
}



if ($in =~ /.gz$/) {
	#open(IN, “gunzip -c $file |”) || die “can’t open pipe to $file”;
	open (IN, "gunzip -c $in | ") || die "I can't open $in\n";
}
else {
	open (IN, "<$in") || die "I can't open $in\n";

}


open (OUT, ">$out") || die "I can't open $out\n";


while (<IN>) {
	chomp;
	$_=~s/\'/\"/g;

	my @a = split(/$insep/,$_);

	my $inelem=0;
	my $merged='';
	my @new;
	foreach my $line (@a) {
	
		
		
		# ending a merger
		if ($inelem=~/1/ and $line=~/\"/ ){
			# add the element to merged
			$merged= $merged . $insep . $line;
			#print "M3: $merged\n";	
			# add it to array
			push(@new,$merged);

			# set inelem
			$inelem=0;
			
			# reset merged
			$merged='';
		}
		# if the element contains the separator, keep merging until next is found
		elsif ($line=~/\"/) {
			$line=~tr/$insep//;		
			# starting a merger
				# add the element to merged
				$merged=$line;
				#print "M1: $line\n";	
				# set inelem
				$inelem=1;
			
		}
		# continuing a merger
		elsif ($inelem=~/1/){
			$merged= $merged . $insep . $line;
			#print "M2: $merged\n";	
		}
		# if the element does not contain a separator, keep going
		else {
			push(@new,$line);
			#print "added $line\n";
		}



	}


	# now print the final line with new separators
	
	if ($outsep=~/t/) {
		$outsep="\t";
	}

	my $res = join("$outsep", @new);
	print "$res\n";

}



close(OUT);

