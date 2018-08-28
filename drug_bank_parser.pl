#!/usr/bin/perl -w


use strict;


if (@ARGV < 1) {
        &USAGE;
}


sub USAGE {

die 'Usage: drug_bank_parser_flat.pl  *_ids_with_known_action.csv drug_links.csv all_target.fasta

Takes a list of RCDB-numbers and associates them with the UniProt entry for them




What can possibly go wrong...  :-)


NOT FINISHED SCRIPT!!!!


'
}

my $in = shift;
my $in2 = shift;
my $fas = shift;


open (IN, "<$in") || die "I can't open $in\n";
 
        while (<IN>) {
            chomp;
            my @arr= split(/\,/,$_);
            my $ID = $arr[0];
            my $Name= $arr[1];
            my $GeneName= $arr[2];
            my $GenBankProteinID = $arr[3]; 
            my $GenBankGeneID= $arr[4];
            my $UniProtID= $arr[5];
            my $UniprotTitle= $arr[6];
            my $PDBID= $arr[7];
            my $GeneCardID= $arr[8];
            my $GenAtlasID= $arr[9];
            my $HGNCID= $arr[10];
            my $HPRDID= $arr[11];
            my $SpeciesCategory= $arr[12];
            my $Species= $arr[13];
            my $DrugIDs= $arr[14];
            #print "$ID\t$DrugIDs\n";
}

close (IN);


#print "Hi\n";


# read in 
open (IN, "<$in2") || die "I can't open $in2\n";
 
        while (<IN>) {
            chomp;

            $_=~s/\"\"/\"NA\"/g;
            my @ar2= split(/\"/,$_);

            my $even =0;
            foreach my $ele (@ar2) {
                if ($even=~/1/) {
                    $even = 0;
                    #print "in para $ele\n";
                    $ele=~s/\,/\;/g;
                }
                else {
                    $even = 1;
                    #print "Not in para $ele\n";

                }
            }
            my $line = join("", @ar2); 

            my @arr= split(/\,/,$line);

            my $DrugBankID = $arr[0];
            my $Name = $arr[1];
            my $CASNumber = $arr[2];
            my $DrugType = $arr[3];
            my $KEGGCompoundID = $arr[4];
            my $KEGGDrugID = $arr[5];
            my $PubChemCompoundID = $arr[6];
            my $PubChemSubstanceID = $arr[7];
            my $ChEBIID = $arr[8];
            my $PharmGKBID = $arr[9];
            my $HETID = $arr[10];
            my $UniProtID = $arr[11];
            my $UniProtTitle = $arr[12];
            my $GenBankID = $arr[13];
            my $DPDID = $arr[14];
            my $RxListLink = $arr[15];
            my $PdrhealthLink = $arr[16];
            my $WikipediaLink = $arr[17];
            my $Drugscomlink = $arr[18];
            my $NDCID = $arr[19];
            my $ChemSpiderID = $arr[20];
            my $BindingDBID = $arr[21];
            my $TTDID = $arr[22];

            print "$DrugBankID\t$Name\n";
        }



exit;
