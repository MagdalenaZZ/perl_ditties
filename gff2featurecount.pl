#!/usr/bin/perl -w
use strict;
use Data::Dumper;

unless (@ARGV >=1) {
        &USAGE;
}


sub USAGE {

die 'Usage: 

Usage: gff2featurecount.pl <input.gff> <OPTIONAL input.fa>

mz script for making a gff file to a featurecount index

'
}

my $gff = shift;

open (GFF, "<$gff") || die "I can't open $gff\n";
my @gff = <GFF>;
close (GFF);

open (OUT1, ">$gff.fc.ref") || die "I can't open $gff.fc.ref\n";


foreach my $line (@gff) {
	chomp $line;
	my @arr =split(/\s+/, $line);
	if ($arr[2]=~/exon/) {
		$arr[1]="fcindex";
		$arr[8] ="gene_id " . $arr[8];
		if ($arr[3]==$arr[4]) {
			next;		
		}
		elsif ($arr[3]>$arr[4]) {
			#print "Wrong orientation $arr[3] $arr[4] $arr[8]\n";
			my $tmp = $arr[3];
			$arr[3]=$arr[4];
			$arr[4]=$tmp;
		}

		print OUT1 join("\t", @arr) . "\n";
	}
}
close (OUT1);


if (@ARGV>0) {

	open (OUT2, ">$gff.fc.refai") || die "I can't open $gff.fc.refai\n";
	my $ref = shift;
	system "samtools faidx $ref";
	open (FAI, "<$ref.fai") || die "I can't open $ref.fai\n";
	my @fai = <FAI>;
	close (FAI);

	foreach my $line (@fai) {
		chomp $line;
		my @a =split(/\s+/, $line);
		#$arr[1]="FAI";
		#$arr[8] ="gene_id " . $arr[8];
		#print OUT2 join("\t", @arr) . "\n";
		print OUT2 "$a[0]\tFAI\texon\t1\t$a[1]\t.\t+\t.\tgene_id Chr$a[0]\n";

	}
	close (OUT2);
}
else {
	exit;
}






exit;


