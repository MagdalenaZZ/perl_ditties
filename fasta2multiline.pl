#!/usr/local/bin/perl -w
# mz3 script 


use strict;

unless (@ARGV == 2) {
        &USAGE;
 }

 sub USAGE {

die 'Usage: fasta2multiline.pl <length> <input.fa>

If you put "s" instead of a line length, the script will make a single-line file
 

'
}

### this of the script ####
my $len = shift;
my $in = shift;
my $out = "$in" . "\.mul.$len";


open (IN, "<$in") || die;
open (OUT, ">$out") || die;

my $temp='';
my @files;

local $/ = ">";
while (my $line = <IN>)  {

  # discard initial empty chunk
  next unless $line;
  chomp($line);

	if($line=~/\w+/ & $line=~/\n/) {
		my @arr = split(/\n/, $line);
 		my $head = shift(@arr);
		my $seq = join("",@arr);
		$seq=~s/\n//g;
		$seq=~s/\t//g;
		$seq=~s/ //g;
		if ($len=~/s/) {		
			print OUT ">$head\n$seq\n";
		}
		elsif ($len=~/\d+/) {
			print OUT ">$head\n";
			my @se = $seq =~ /(.{1,$len})/g;
			foreach my $ele (@se) {
				print OUT "$ele\n";
			}

		}
		else {
			print "I dont understand length $len \n\n";		
		}
	}
	else {
		print "I have discarded this line $line\n\n";
		
	}

} 



exit;




