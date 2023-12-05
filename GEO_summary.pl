#!/usr/local/bin/perl -w

use strict;

unless (@ARGV ==2) {
        &USAGE;
}


sub USAGE {

die 'Usage: GEO_summary.pl gds_result.txt prefix

Takes a GEO gds_result.txt file and tidies it



'
}


	my $in = shift;
	my $prefix=shift;
	my $out = $prefix . ".GEOsummaries.txt";

if ($in =~ /.gz$/) {
	#open(IN, “gunzip -c $file |”) || die “can’t open pipe to $file”;
	open (IN, "gunzip -c $in | ") || die "I can't open $in\n";
}
else {
	open (IN, "<$in") || die "I can't open $in\n";

}


open (OUT, ">$out") || die "I can't open $out\n";


my %res;

my $i = 0; 
while (<IN>) {
chomp;
	if ( $_=~/^$/ || $i=="0" ) {
		#print "New entry $_\n";
		$i++;
	}


	elsif ( $_=~/Submitter supplied/) {
		$_=~s/\(Submitter supplied\) //;
		$res{$i}{"Sub"}{$_}=1;
	}
	elsif ( $_=~/Project:/) {
		$res{$i}{"Proj"}{$_}=1;
	}
	elsif ( $_=~/Organism:/) {
		$_=~s/Organism:\t//;
		$_=~s/\; /;/g;
		$_=~s/ /_/g;
		$res{$i}{"Org"}{$_}=1;
	}
	elsif ( $_=~/Platform:/ || $_=~/Platforms:/ ) {
		my @a = split(/\s+/,$_);
		my $discard = shift(@a);
		$discard = pop(@a);
		my $sams = pop(@a);
		my $IDs = join("\,", @a);
		$IDs=~s/,Platform://;
		$res{$i}{"Samples"}{$sams}=1;
		$res{$i}{"Platform"}{$IDs}=1;
	}
	elsif ( $_=~/Type:/) {
		$_=~s/Type:\t\t//;
		$_=~s/\; /\;/g;
		$_=~s/ /_/g;
		$res{$i}{"Type"}{$_}=1;
	}
	elsif ( $_=~/FTP download:/) {
		$_=~s/, /,/g;
		my @a = split(/\ /,$_);
		my $new = "$a[-1]\t$a[-2]";

		$res{$i}{"FTPlink"}{$a[-1]}=1;
		$res{$i}{"FTPtype"}{$a[-2]}=1;

	}
	elsif ( $_=~/SRA Run Selector:/) {
		$res{$i}{"SRA"}{$_}=1;
	}
	elsif ( $_=~/related Platforms/) {
		my @a = split(/\s+/,$_);
		$res{$i}{"Samples"}{$a[3]}=1;
	}
	elsif ( $_=~/^Series/) {
		my @a =split(/\s+/,$_);
		$res{$i}{"Series"}{$a[2]}=1;
	}
	elsif ( $_=~/\d+\. \w+/) {
		$res{$i}{"Desc"}{$_}=1;
	}
	else {
		print "ELSE:$_:\n";
	}


}

	print OUT "Number\tGEO\tOrganism\tNoSam\tPlatform\tFormat\tUser\tDescription\n";


foreach my $key (sort {$a<=>$b} keys %res) {

	#print  "$key\n";
	print OUT "$key";


	if (exists $res{$key}{"Series"}) {
		foreach my $key2 (keys %{$res{$key}{"Series"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}

	if (exists $res{$key}{"Org"}) {
		foreach my $key2 (keys %{$res{$key}{"Org"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}

	if (exists $res{$key}{"Samples"}) {
		foreach my $key2 (keys %{$res{$key}{"Samples"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}


	if (exists $res{$key}{"Platform"}) {
		foreach my $key2 (keys %{$res{$key}{"Platform"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}
	if (exists $res{$key}{"FTPtype"}) {
		foreach my $key2 (keys %{$res{$key}{"FTPtype"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}
	if (exists $res{$key}{"Sub"}) {
		foreach my $key2 (keys %{$res{$key}{"Sub"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}
	if (exists $res{$key}{"Desc"}) {
		foreach my $key2 (keys %{$res{$key}{"Desc"}} ) {
			print OUT "\t$key2";	
		}
	}
	else {
		print OUT "\tNA";	
	}



	print OUT "\n";

}


