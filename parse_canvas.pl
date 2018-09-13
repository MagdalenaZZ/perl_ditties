#!/usr/bin/perl -w

use strict;





if (@ARGV != 1) {
	print "Usage: parse_canvas.pl file.vcf.gz \n\n" ;

	exit ;
}

my $file = shift @ARGV;



open(IN, "bcftools view -H $file |") or die "Couldn't open file";


open (OUT, ">$file.res") or die "oops!\n" ;


my %res;
my %resp;

while (<IN>) {
	chomp ;

	my @a = split(/\t/,$_);

	unless ($a[2]=~/Canvas:/) {
		next;
	}
	my @p = split(/:/,$a[2]);
	my @f = split(/:/,$a[10]);
	push(@f,"NA");
	
	my $chr=$a[0];
	my $start=$p[3];
	my $stop=$p[4];
	my $length=$stop-$start;
	my $change =$p[1];
	my $qual=$a[6];
	my $cov=$f[3];

##FORMAT=<ID=CN,Number=1,Type=Integer,Description="Copy number genotype for imprecise events">
##FORMAT=<ID=MCC,Number=1,Type=Integer,Description="Major chromosome count (equal to copy number for LOH regions)">
	if ($cov=~/NA/) {
		$cov =$f[2];
	}	

	$res{$a[0]}{$p[1]}{"LEN"}+=$length;

	# Only do high-depth res

	if ($qual=~/PASS/) {
		$resp{$a[0]}{$p[1]}{"LEN"}+=$length;
	}
	else {
		$resp{$a[0]}{"REF"}{"LEN"}+=$length;
	}

	print  OUT "$a[0]\t$a[1]\t$p[1]\t$p[3]\t$p[4]\t$a[5]\t$a[6]\t$f[2]\t$f[3]\n";

	#print "$a[0]\t$a[1]\t$p[1]\t$p[3]\t$p[4]\t$a[5]\t$a[6]\n";


}

#__END__

# Pad missing values
foreach my $key (sort keys %res) {
	unless (exists $res{$key}{"GAIN"} ) {
		$res{$key}{"GAIN"}{"LEN"}=0;
	}
	unless (exists $res{$key}{"LOSS"} ) {
		$res{$key}{"LOSS"}{"LEN"}=0;
	}
	unless (exists $res{$key}{"REF"} ) {
		$res{$key}{"REF"}{"LEN"}=0;
	}
}
foreach my $key (sort keys %resp) {
	unless (exists $resp{$key}{"GAIN"} ) {
		$resp{$key}{"GAIN"}{"LEN"}=0;
	}
	unless (exists $resp{$key}{"LOSS"} ) {
		$resp{$key}{"LOSS"}{"LEN"}=0;
	}
	unless (exists $resp{$key}{"REF"} ) {
		$resp{$key}{"REF"}{"LEN"}=0;
	}
}




#__END__

foreach my $key (sort keys %res) {
	print "$file\t$key\t";
	foreach my $key2 (sort keys %{$res{$key}} ) {
		foreach my $key3 (sort keys %{$res{$key}{$key2}} ) {
			#print "KEY3:$key3:";
			if ($key3=~/LEN/) {
				print "$key2\t$res{$key}{$key2}{$key3}\t";
			}
		}
	}
	foreach my $key2 (sort keys %{$resp{$key}} ) {
		foreach my $key3 (sort keys %{$resp{$key}{$key2}} ) {
			#print "KEY3:$key3:";
			if ($key3=~/LEN/) {
				print "$key2\t$resp{$key}{$key2}{$key3}\t";
			}
		}
	}

	print "\n";
}





close(IN);
close(OUT);


exit;


