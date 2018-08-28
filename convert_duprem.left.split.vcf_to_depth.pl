#!/usr/local/bin/perl -w

use strict;

unless (@ARGV==1) {
        &USAGE;
}


sub USAGE {

die 'Usage: convert_duprem.left.split.vcf_to_depth.pl infile.vcf.gz




'
}

my $vcf = shift;
my $out = $vcf . ".addDP.vcf";

open (VCF, "bcftools view $vcf |") || die "I can't open $vcf\n";
#open (VCF, "<$vcf") || die "I can't open $vcf\n";
open (OUT, ">$out") || die "I can't open $out\n";


while (<VCF>) {
    
	if ($_=~/^#/) {
		print OUT "$_";
	}
	else {
		chomp $_;
		my @arr = split(/\t/, $_);
    		
		# If it is indel
		if ($arr[6]=~/DP:DP2:TAR:TIR:TOR:DP50:FDP50:SUBDP50/) {
			print "INDEL $arr[6]\n";
		}
		# If it is SNV
		elsif ($arr[6]=~/DP:FDP:SDP:SUBDP:AU:CU:GU:TU/) {
			print "SNP $arr[6]\n";	
		}
		else {
			print "Dont know what to do with $arr[6]\n";
		}

	}
}

__END__
		my @info=split(/\;/,$arr[7]);
		$info[1]=~s/GN=//;
		if ($info[1]=~/=/) {
			next;
		}
		#print "$info[1]\n";
		my @info2=split(/\,/,$info[1]);
		#$info2[0]=~s/GN=//;
		#print "$info2[0]\n";
		my $call='0/0';
		if ($info2[1]<1) {
			$call='0/0';
		}
		elsif ($info2[1]>$info2[0] ) {
			$call='1/2';	
		}
		elsif ($info2[1]/($info2[0]+$info2[1]) > 0.05 ) {
			$call='0/1';
		}
		else {
		}
		my $newline = "$arr[0]\t$arr[1]\t$arr[2]\t$arr[3]\t$arr[4]\t$arr[5]\t$arr[6]\t$arr[7]";
		print OUT "$newline\t$call:$info[1]\n";
	}
}


exit;
