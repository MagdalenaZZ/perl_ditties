#!/usr/bin/perl -w
# Munge data
# magdalena.z@icr.ac.uk 28 March 2018
# more info 
# https://pubchemdocs.ncbi.nlm.nih.gov/programmatic-access
# https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest
# https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest-tutorial
# https://pubchemdocs.ncbi.nlm.nih.gov/pug-view
#

use strict;
use Try::Tiny;

unless (@ARGV == 1) {
	print "Usage: split_end.pl gene-symbol \n\n" ;

    print " mz3 script for creating a split end file \n\n";

	exit ;
}


#my $gene="MYCN";
my $gene=shift;
my $jasfol="/Users/mzarowiecki/Desktop/pug_REST/CID";

open (OUT, ">$gene.PubChem.res") || die "I can't open $gene.PubChem.res\n";




unless(-f "$gene.list"  ){
	system("wget -O $gene.list https://pubchem.ncbi.nlm.nih.gov/rest/pug/assay/target/genesymbol/$gene/aids/TXT");
}

# Download files from this


open (IN, "<$gene.list") || die "I can't open $gene.list\n";


my @csvs;

# Get the results for each assay
while(<IN>) {
	chomp;
	my $aid = $_;
	if(-f "$gene.$aid.csv"  ){
		push(@csvs,"$gene.$aid.csv");
	}
	else {
		try{ 
			system("wget -O $gene.$aid.csv https://pubchem.ncbi.nlm.nih.gov/rest/pug/assay/aid/$aid/CSV");
			push(@csvs,"$gene.$aid.csv");
		}

		# If that fails, pull down the list in pieces
		# https://pubchem.ncbi.nlm.nih.gov/rest/pug/assay/aid/602332/sids/XML?sids_type=doseresponse&list_return=listkey
		# followed by
		# https://pubchem.ncbi.nlm.nih.gov/rest/pug/assay/aid/602332/doseresponse/CSV?sid=listkey&listkey=xxxxxx&listkey_count=100 (where ‘xxxxxx’ is the listkey returned by the previous URL)
		# more info https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest
		# https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest-tutorial
	}
}

# Read those CSVs


my %aidRes;



foreach my $csv (@csvs) {
	#print "cat $csv | head -1 \n";

	
	open (IN, "<$csv") || die "I can't open :$csv:\n";
	my @in = <IN>;

	# If the csv file has content
	if (scalar(@in)>0) {
		my @headers= split(/\,/,shift(@in));
		#print ("$csv\t$headers[3]\n");
		my $i=0;
		foreach my $ele (@in) {
			my @a = split(/\,/,$ele);
			my $sid=$a[1];
			my $cid=$a[2];
			my $act=$a[3];
			if ($act=~/^Active$/ and $cid=~/\d+/) {
				#print "$gene\tSID:$sid\tCID:$cid\tACT:$act\n";
				$aidRes{$gene}{"CID"}{$cid}=1;
			}
			if ($act=~/^Active$/ and $sid=~/\d+/) {
				#print "$gene\tSID:$sid\tCID:$cid\tACT:$act\n";
				$aidRes{$gene}{"SID"}{$sid}=1;
			}

		}
	}
}




##################

# Now download the AIDs associated with the gene

## Pick out relevant information about that AID

# Example https://pubchem.ncbi.nlm.nih.gov/bioassay/319620#section=Top
# Primary Citation: 	Synthesis and structure based optimization of novel Akt inhibitors. Bioorg Med Chem Lett. 2008 Jun 1;18(11):3359-63 
# PMID link  Abstract: PubMed
#
#Title: Synthesis and structure based optimization of novel Akt inhibitors.
# Abstract: Based on a high throughput screening hit, pyrrolopyrimidine inhibitors of the Akt kinase are explored. X-ray co-crystal structures of two lead series results in the understanding of key binding interactions, the design of new lead series, and enhanced potency. The syntheses of these series and their biological activities are described. Spiroindoline 13j is found to have an Akt1 kinase IC(50) of 2.4+/-0.6 nM, Akt cell potency of 50+/-19 nM, and provides 68% inhibition of tumor growth in a mouse xenograft model (50 mg/kg, qd, po).

## Related targets
# "Q9Y243","RAC-gamma serine/threonine-protein kinase","human",100,0.0,82
#"AAA58364","protein serine/threonine kinase","human",99,0.0,81
#"NP_001617","RAC-beta serine/threonine-protein kinase isoform 1","human",99,0.0,81
#"P31751","RAC-beta serine/threonine-protein kinase","human",99,0.0,81
#"NP_001193658","RAC-gamma serine/threonine-protein kinase isoform 2","human",95,0.0,82
#"3O96_A","Chain A, Crystal Structure Of Human Akt1 With An Allosteric Inhibitor","human",92,0.0,100
#"4EJN_A","Chain A, Crystal Structure Of Autoinhibited Form Of Akt1 In Complex With N-(4- (5-(3-Acetamidophenyl)-2-(2-Aminopyridin-3-Yl)-3h-Imidazo[4,5- B]pyridin-3-Yl)benzyl)-3-Fluorobenzamide","human",92,0.0,99


my %cidRes;

# Now download the CIDs associated with the gene

foreach my $gen (keys %aidRes) {

	foreach my $ci (keys %{$aidRes{$gen}{"CID"}}) {

		unless (-f "$jasfol/$ci.json" ) {
			#system ("wget -O $gene.$ci.index.json https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/index/compound/$ci/JSON");
			#system ("wget -O $gene.$ci.data.json https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/$ci/JSON");
			system ("wget -O $jasfol/$ci.json https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/$ci/JSON");
			sleep(1);
		}
		unless (-f "$jasfol/$ci.aid.txt" ) {
			system ("wget -O $jasfol/$ci.aid.txt https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$ci/aids/TXT?aids_type=active");
			sleep(1);
		}
		system ("cat $jasfol/$ci.json| grep $gen > $gen.$ci.genres");
		system ("[[ -s $gen.$ci.genres ]] && echo \"cat $gen.$ci.genres\" || rm $gen.$ci.genres");
		open (IN, "<$jasfol/$ci.json") || die "I can't open :$jasfol/$ci.json:\n";

		my $isname=0;
		my $issyn=0;
		my $ispharma=0;
		while (<IN>) {
			chomp;

			
			# Pick out primary name of CID
			if ($_=~/"Name": "Record Title",/) {
				$isname=1;
			}
			elsif($isname==1){
				my $name=$_;
				$name=~s/\s+"StringValue": "//;
				$name=~s/\"//;
				#print "NAME:$name:\n";
				$cidRes{$gen}{$ci}{"NAME"}{$name}=1;
				$isname=0;
			}
			# Pick out synonyms
			if ($_=~/"Name": "Depositor-Supplied Synonyms"/) {
				$issyn=1;
			}
			elsif($issyn==1){
				# end of synonym list
				if ($_=~/ ]/) {
					$issyn=0;
					# tidy up and report
				}
				elsif ($_=~/"StringValueList":/) {
					# just ignore
				}

				else {
					my $drug=$_;
					$drug=~s/\"//g;
					$drug=~s/\s+//g;
					$drug=~s/\,//g;
					#print "SYN:$gen\t$ci\t$drug\n";
					$cidRes{$gen}{$ci}{"SYN"}{$drug}=1;
				}
			}
			# Pick out pharmacology description
			elsif ($_=~/"Name": "Pharmacology",/) {
				$ispharma=1;
			}
			elsif($ispharma==1){
				my @a=split(/\>/,$_);
				@a=splice(@a,1);
				my $a=join('>',@a);
				$a=~s/\;/\,/g;
				#print "PHARMA:\"\>$a:\n";
				$cidRes{$gen}{$ci}{"PHARMA"}{"\"$a"}=1;
				$ispharma=0;

			}
			# Pick out NCI linkout
			elsif ($_=~/https:\/\/ncit.nci.nih.gov\/ncitbrowser\/ConceptReport/) {
				my $nci=$_;
				$nci=~s/"URL": "//;
				$nci=~s/\"//g;
				$nci=~s/\s+//g;
				#print "NCI:$nci:\n";
				$cidRes{$gen}{$ci}{"NCI"}{$nci}=1;
			}
			else {

			}
		}	
	}
}



my @htmls;

# Print output from CID res
print OUT "GENE\tCID\tPrimary_name\tSynonyms\tPharmacology\n";
my $nores=0;

foreach my $ge (keys %cidRes) {

	foreach my $cinu (keys %{$cidRes{$ge}}) {

		# Get the primary_name
		my @names;
		foreach my $name (keys %{$cidRes{$ge}{$cinu}{"NAME"}}) {
			push(@names,$name);
		}
		my $names=join(';',@names);


		# Get the synonyms
		my @syns;
		foreach my $syn (keys %{$cidRes{$ge}{$cinu}{"SYN"}}) {
			push(@syns,$syn);
		}
		my $syns=join(';',@syns);

		# Get the NCI linkouts
		my @ncis;
		foreach my $nci (keys %{$cidRes{$ge}{$cinu}{"NCI"}}) {
			push(@ncis,$nci);
		}
		my $ncis=join(';',@ncis);


		# Get the Pharma
		my @pharmas;
		foreach my $pharma (keys %{$cidRes{$ge}{$cinu}{"PHARMA"}}) {
			push(@pharmas,$pharma);
		}
		my $pharmas=join(';',@pharmas);
		print OUT "$ge\t$cinu\t$names\t$syns\t$ncis\t$pharmas\n";
		push(@htmls,"$ge\t$cinu\t$names\t$syns\t$ncis\t$pharmas");
		#		if (length($pharmas . $ncis)>1) {
#		}
		

		# Good drugs have a lot more information and link-out on their CID page
		# https://pubchem.ncbi.nlm.nih.gov/compound/Crizotinib#section=Information-Sources

	
		#Get the AIDs associated with that CID - to look for alternative targets
		my $aids `wget https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/2244/aids/TXT?aids_type=active`;
		# Foreach aid associated with a CID, get the gene targets
		my $aid_targets =`wget https://pubchem.ncbi.nlm.nih.gov/rest/pug/assay/aid/1258899/targets/GeneSymbol/TXT`;
		# Tally up targets for that CID. The list should contain our gene, but may also contain others
		##########################
	}

}

my @also;

# Make HTML of results
open (O, ">$gene.PubChem.html") || die "I can't open $gene.PubChem.html\n";
print O ("<!DOCTYPE html>\n<html>\n<body>\n\n");
print O ("<h1>$gene</h1>\n");


foreach my $line (@htmls) {

	my @l = split("\t",$line);
	

	# Only pick lines with results
	if ($line=~/http/) {
		print O ("<h2>$l[2]</h2>\n");
		print O ("<p>$l[2] has been found to be active against $gene in a <a class=\"whatever\" href=\"https://pubchem.ncbi.nlm.nih.gov/compound/$l[1]#section=Biological-Test-Results\">bioAssay</a></p>\n");
	      	print O ("<p>Read more about the drug at NCI: <a class=\"whatever\" href=\"$l[4]\">NCI-link</a></p>\n\n");
		$l[5]=~s/\\//g;
		$l[5]=~s/\"//g;
		$l[5]=~s/\;/<p>\n<\/p>/g;
		print O ("<p>$l[5]</p>\n\n");
		#print "HTTP:$l[2]\n";
	}
	elsif ($l[2]=~/\b([A-Z]+-[A-Z]+-[A-Z]+)/) {
		# ignore
		# YDGAIFLOOACQIQ-UHFFFAOYSA-N
		# MZIQJPGLZXVJCP-UHFFFAOYSA-N
	}
	else {
		push (@also,"$l[1]\t$l[2]");
	}
}

@also = sort @also;
print O ("<h2>Also consider</h2>\n");
foreach my $elem (@also) {
	my @a=split(/\t/,$elem);
	print O ("<p><a class=\"whatever\" href=\"https://pubchem.ncbi.nlm.nih.gov/compound/$a[0]#section=Biological-Test-Results\">$a[1]</a></p>");
}
print O ("\n</body>\n</html>\n");



# search drug databases
# for patients
# https://vsearch.nlm.nih.gov/vivisimo/cgi-bin/query-meta?v%3Aproject=medlineplus&v%3Asources=medlineplus-bundle&query=Trametinib
# Trametinib is used alone or in combination with another medication (dabrafenib [Tafinlar]) to treat a certain type of melanoma (a type of skin cancer) that cannot be treated with surgery or that has spread to other parts of the body. Trametinib is also used in combination with dabrafenib to treat a certain type of non-small-cell lung cancer (NSCLC) that has spread to nearby tissues or to other parts of the body. Trametinib is in a class of medications called kinase inhibitors. It works by blocking the action of an abnormal protein that signals cancer cells to multiply. This helps stop the spread of cancer cells.
# https://www.drugs.com/uk/mekinist.html Drugs.com only have retail names
#
# for doctors
# https://druginfo.nlm.nih.gov/drugportal/name/Mekinist
# link-outs to other sources of information

# MIMS is only for GPs, others paid subscription https://www.mims.co.uk/
#
#
# My favourite
# https://www.medicines.org.uk/emc/search?q=Trametinib
#
#

exit;


