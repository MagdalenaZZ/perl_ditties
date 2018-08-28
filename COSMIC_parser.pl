#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >2) {
        &USAGE;
}


sub USAGE {

die 'Usage:  COSMIC_parse.pl input.file <filter> more|less|exact:i|e 


Takes a file from COSMIC and reformats it for statistics

Filter:    column:value 
Filter:		more|less|exact  :  include|exclude


'
}


	my $in = shift;
	my $f1=shift;
	my $f2=shift;

	my $out = $in . ".tsv";


if ($in =~ /.gz$/) {
	#open(IN, “gunzip -c $file |”) || die “can’t open pipe to $file”;
	open (IN, "gunzip -c $in | ") || die "I can't open $in\n";
}
else {
	open (IN, "<$in") || die "I can't open $in\n";

}


open (OUT, ">$out") || die "I can't open $out\n";

my %h;

while (<IN>) {
	chomp;
	my @a=split(/\t/,$_);

foreach my $elem (@a) {
	if ($elem!~/\w+/) {
		$elem="NA";
	}
}

my $Gene_name=$a[0];
my $Accession_Number=$a[1];
my $Gene_CDS_length=$a[2];
my $HGNC_ID=$a[3];
my $Sample_name=$a[4];
my $ID_sample=$a[5];
my $ID_tumour=$a[6];
my $Primary_site=$a[7];
my $Site_subtype_1=$a[8];
my $Site_subtype_2=$a[9];
my $Site_subtype_3=$a[10];
my $Primary_histology=$a[11];
my $Histology_subtype_1=$a[12];
my $Histology_subtype_2=$a[13];
my $Histology_subtype_3=$a[14];
my $Genome_wide_screen=$a[15];
my $Mutation_ID=$a[16];
my $Mutation_CDS=$a[17];
my $Mutation_AA=$a[18];
my $Mutation_Description=$a[19];
my $Mutation_zygosity=$a[20];
my $LOH=$a[21];
my $GRCh=$a[22];
my $Mutation_genome_position=$a[23];
my $Mutation_strand=$a[24];
my $SNP=$a[25];
my $Resistance_Mutation=$a[26];
my $FATHMM_prediction=$a[27];
my $FATHMM_score=$a[28];
my $Mutation_somatic_status=$a[29];
my $Pubmed_PMID=$a[30];
my $ID_STUDY=$a[31];
my $Sample_source=$a[32];
my $Tumour_origin=$a[33];
my $Age=$a[34];

print "$Age\n";
$h{$ID_tumour}{$ID_sample}{"Gene_name"}{$Gene_name}+=1;
$h{$ID_tumour}{$ID_sample}{"Accession_Number"}{$Accession_Number}+=1;
$h{$ID_tumour}{$ID_sample}{"Gene_CDS_length"}{$Gene_CDS_length}+=1;
$h{$ID_tumour}{$ID_sample}{"HGNC_ID"}{$HGNC_ID}+=1;
$h{$ID_tumour}{$ID_sample}{"Sample_name"}{$Sample_name}+=1;
$h{$ID_tumour}{$ID_sample}{"ID_sample"}{$ID_sample}+=1;
$h{$ID_tumour}{$ID_sample}{"ID_tumour"}{$ID_tumour}+=1;
$h{$ID_tumour}{$ID_sample}{"Primary_site"}{$Primary_site}+=1;
$h{$ID_tumour}{$ID_sample}{"Site_subtype_1"}{$Site_subtype_1}+=1;
$h{$ID_tumour}{$ID_sample}{"Site_subtype_2"}{$Site_subtype_2}+=1;
$h{$ID_tumour}{$ID_sample}{"Site_subtype_3"}{$Site_subtype_3}+=1;
$h{$ID_tumour}{$ID_sample}{"Primary_histology"}{$Primary_histology}+=1;
$h{$ID_tumour}{$ID_sample}{"Histology_subtype_1"}{$Histology_subtype_1}+=1;
$h{$ID_tumour}{$ID_sample}{"Histology_subtype_2"}{$Histology_subtype_2}+=1;
$h{$ID_tumour}{$ID_sample}{"Histology_subtype_3"}{$Histology_subtype_3}+=1;
$h{$ID_tumour}{$ID_sample}{"Genome-wide_screen"}{$Genome_wide_screen}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_ID"}{$Mutation_ID}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_CDS"}{$Mutation_CDS}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_AA"}{$Mutation_AA}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_Description"}{$Mutation_Description}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_zygosity"}{$Mutation_zygosity}+=1;
$h{$ID_tumour}{$ID_sample}{"LOH"}{$LOH}+=1;
$h{$ID_tumour}{$ID_sample}{"GRCh"}{$GRCh}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_genome_position"}{$Mutation_genome_position}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_strand"}{$Mutation_strand}+=1;
$h{$ID_tumour}{$ID_sample}{"SNP"}{$SNP}+=1;
$h{$ID_tumour}{$ID_sample}{"Resistance_Mutation"}{$Resistance_Mutation}+=1;
$h{$ID_tumour}{$ID_sample}{"FATHMM_prediction"}{$FATHMM_prediction}+=1;
$h{$ID_tumour}{$ID_sample}{"FATHMM_score"}{$FATHMM_score}+=1;
$h{$ID_tumour}{$ID_sample}{"Mutation_somatic_status"}{$Mutation_somatic_status}+=1;
$h{$ID_tumour}{$ID_sample}{"Pubmed_PMID"}{$Pubmed_PMID}+=1;
$h{$ID_tumour}{$ID_sample}{"ID_STUDY"}{$ID_STUDY}+=1;
$h{$ID_tumour}{$ID_sample}{"Sample_source"}{$Sample_source}+=1;
$h{$ID_tumour}{$ID_sample}{"Tumour_origin"}{$Tumour_origin}+=1;
$h{$ID_tumour}{$ID_sample}{"Age"}{$Age}+=1;




}










close(OUT);


