#!/usr/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}




sub USAGE {

    die '


Usage: proteinatlas_annotaton.pl <ENSG.list>

i.e.


ENSG.list = a file with Ensembl human identifiers

This program takes a file with a column with Ensembl human identifiers and pulls proteinAtlas annotation for that list.



    ' . "\n";
}

my $in = shift;
my @out;

open (IN, "<$in") || die "I can't open file $in\n";
open (OUT, ">$in.pa.annot") || die "I can't open file $in.pa.annot\n";

print OUT "Gene\tGene_synonym\tEnsembl\tGene_description\tChromosome\tPosition\tProtein_class\tEvidence\tAntibody\tReliability(IH)\tReliability(MouseBrain)\tReliability(IF)\tSubcellular_location\tPrognostic_p-value\tRNA_cancer_category_RNA_tissue_category\tRNA_TS\tRNA_TS\tTPM\tTPM_max_in_non-specific\tRNA_cell_line_category\tRNA_CS\tRNA_CS_TPM\n";

while (<IN>) {
	chomp;

	if ($_=~/^ENSG/) {
	
		#print "wget  \"http://www.proteinatlas.org/$_.tsv\" \n";
		my @res = `wget -qO- http://www.proteinatlas.org/$_.tsv` ;
		print OUT "$res[1]";

	}
	else {
		print "Not all your elements in your input file are Ensembl human genome markers: $_ \n";
		exit;
	}

}


close (IN);
close (OUT);




exit;


