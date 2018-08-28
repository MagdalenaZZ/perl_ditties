#!/usr/bin/perl


use FindBin qw($Bin);

print "$Bin\n";

use strict;
use Getopt::Std;
use Cwd;

print "Hi 12\n";

use PDF::API2;              ## needed to create a PDF file
use Math::Trig;             ## needed for sinus function
use List::Util qw(min max); ## needed to provide min and max function for lists  
use File::Basename;

Usage() if(not $ARGV[0] or $ARGV[0] =~ /-*-he*l*p*/);

my $n_count = 0;
my $k_count = 0;
my $e_count = 0;
my $sig = 0;

my $infile;         ## miRDeep output file
my $pdfs = 0;       ## force pdf creation
my $threshold= 0;   ## hairpins have to have score above threshold in order to be reported
my $csv = 0;

my $xposshift = 40;
my $lstruct_multi;
my $sb_obs;

## read in available organisms at the end of the script
my %organisms;
while(<DATA>){
    chomp;
    my $tmp;
    $tmp=$_;
    $_ =~ s/\s+//g;
    $organisms{$_}=$tmp;
}
my $known;

## read in miRDeep output file
my $id;
my %hash;   ## takes up all entries from the miRDeep2 module
my %seen;


my $created = 1;

my $in;
my $counter=0;

my %struct; ## counts how often a nt is covered reads

my $i;

my $offset = 0;

my $me=0;     ## mature end coordinate
my @desc;

my %mat_pre_arf =();


my $lflank1; ## length(string of left flank)
my $fl1;    ## 
my $lflank2; ## length string of right flank

my $fl2b=0;   ## right flank begin  
my $lloop;   ## string of loop
my $lb=0;     ## starting position of loop

my $lstar;   ## string of star sequence
my $sb=0;     ## starting 
my $lmature; ## string of mature 

my $mb=0;     ## mature begin
my $struct; ## structure string
my $pri_seq;## pri-cursor sequence
my $lenstr=0; 

my $pdf;    ## pdf descriptor
my $page;   ## page descriptor
my $gfx;    ## graphic variable

my $trb;    ## fontvariable
my $text;
my $text2;


my $aligned;                          ## reads reading 
my %hash2;                            ## begin of read in precursor

my %hash2c;                           ## number of reads per read sequence 
my %hash2key;
my %hash2mm;                          ## number of mismatches
my %hash2order;                       ## output order saved
my %hash2seq;
my %hash2sample;
my %star_exp_hit_pos;
my $blat;
my $spacer;   ## length of longest entry
my $spaces;   ## string of spaces to fill up spacer


my %order;                            ## stores begin coordinates of fl1,m,l,s,fl2 sequences
my $multiplier = 3.6;#4.825;               ## minimal distance between two letters




## calculate predefined pdf loci for alignment characters
my %position_hash;
$counter = 0;
for(my $i=0;$i < 200; $i++){
    $position_hash{$counter} = $xposshift+$multiplier+20+$i*$multiplier;
    $counter++;
}


my $yorig = 500; ## 500
my $downy = 50;

my $dline;                            ## line graphic handler

my $first=1;
my $lastx;
my $lasty;

my $final;                            ## final output string of a read
my @pseq;                             ## precursor sequence  
my @rseq;                             ## read sequence

my $totalreads = 0;
                     
my %assign_str;                       ## color assigned to position where letter is drawn
my %assign_str_exp;

my $bpo1=-10;                             ## left nt pos in first bp 
my $bpo2=-10;                             ## right nt pos in first bp 
my $bpo1r=-10;                            ## left nt pos in second bp 
my $bpo2r=-10;                            ## right nt pos in second bp 


my $ffe=0;                              ## first flank end position
my $ff2b=0;                             ## second flank begin position

my @sorted;                           ## array that stores sorted order of fl1,m,l,s,fl2 
my $y=$yorig;                         ## y coordinate


my ($minx,$miny,$maxx,$maxy);        ## min and max x,y coordinates of rna sequence
my @rna;                 ## rna sequence
my @rna_d;
my %xc;                  ## holds x cooridnate of each nt
my %yc;                  ## holds y coordinate of each nt
my $sid="";        


## pdf histogram colors
my $col_star_exp = 'lightskyblue';
my $col_star_obs = 'darkviolet';
my $col_mature = 'red';
my $col_loop = 'orange';



my %hm;
my %hs;
my %hp;


print "Hi 176\n";

## options
my %options=();

getopts("ugv:f:ck:os:t:w:er:q:dx:y:ab:i:j:lm:M:PW:",\%options);

my %weighted=();
if(-s $options{'W'}){
	open IN,$options{'W'} or die "Could not open file $options{'W'}\n";
	while(<IN>){
		if(/(\S+)\s+(\d+)/){
			$weighted{$1}=$2;
		}
	}
	close IN;
}



## everything else given to it corresponds to the samples
my @files_mirnaex=split(",",$options{'M'});
foreach(@files_mirnaex){
   print STDERR "$_ file with miRNA expression values\n";
}
 


my $time = $options{'y'} or die "no timestamp given with parameter y\n";

if($options{'x'} and not $options{'q'}){
    die "\nError:\n\toption -x can only be used together with option -q\n\n";
}

## determine pdf path when running on a cluster
my $pdf_path;

if($options{'w'}){
    $pdf_path = "http://localhost:8001/links/miRDeep/$options{'w'}";
}


## obtain current working directory
my $cwd = cwd;
if(not $options{'w'}){
    $pdf_path = "file://$cwd";
}

## order output by sample (give -o option) or just by beginning position (no -o option)


## organism parameter
my $org=$organisms{$options{'t'}};


## some quantifier variables
my $mirbase = 0;
my %mature2hairpin;
my %hairpin2mature;  ## some hairpins have more than 1 mature assigned, circumvent this problem
my %hash_q; ## takes up all entries from the quantifier module
 
my $blast="http://blast.ncbi.nlm.nih.gov/Blast.cgi?QUERY=";
my $blast_query = "&db=nucleotide&QUERY_FROM=&QUERY_TO=&QUERYFILE=&GENETIC_CODE=1&SUBJECTS=&stype=nucleotide&SUBJECTS_FROM=&SUBJECTS_TO=&SUBJECTFILE=&DBTYPE=gc&DATABASE=nr&EQ_MENU=&NUM_ORG=1&EQ_TEXT=&BLAS
T_PROGRAMS=blastn&PHI_PATTERN=&MAX_NUM_SEQ=100&SHORT_QUERY_ADJUST=on&EXPECT=10&WORD_SIZE=7&MATRIX_NAME=PAM30&MATCH_SCORES=2,-3&GAPCOSTS=5+2&COMPOSITION_BASED_STATISTICS=0&FILTER=L&REPEATS=repeat_9606&FILT
ER=m&TEMPLATE_LENGTH=0&TEMPLATE_TYPE=0&PSSM=&I_THRESH=&SHOW_OVERVIEW=true&SHOW_LINKOUT=true&GET_SEQUENCE=auauauaauauauauauauuauaa&FORMAT_OBJECT=Alignment&FORMAT_TYPE=HTML&ALIGNMENT_VIEW=Pairwise&MASK_CHAR
=2&MASK_COLOR=1&DESCRIPTIONS=100&ALIGNMENTS=100&NEW_VIEW=true&OLD_BLAST=false&NCBI_GI=false&SHOW_CDS_FEATURE=false&NUM_OVERVIEW=100&FORMAT_EQ_TEXT=&FORMAT_ORGANISM=&EXPECT_LOW=&EXPECT_HIGH=&QUERY_INDEX=&C
LIENT=web&SERVICE=plain&CMD=request&PAGE=Nucleotides&PROGRAM=blastn&MEGABLAST=&RUN_PSIBLAST=&TWO_HITS=&DEFAULT_PROG=megaBlast&WWW_BLAST_TYPE=&DB_ABBR=&SAVED_PSSM=&SELECTED_PROG_TYPE=blastn&SAVED_SEARCH=tr
ue&BLAST_SPEC=&QUERY_BELIEVE_DEFLINE=&DB_DIR_PREFIX=&USER_DATABASE=&USER_WORD_SIZE=&USER_MATCH_SCORES=&USER_FORMAT_DEFAULTS=&NO_COMMON=&NUM_DIFFS=2&NUM_OPTS_DIFFS=1&UNIQ_DEFAULTS_NAME=A_SearchDefaults_1Mn
7ZD_2Sq4_1Z58HQ5Jb_23tpbD_167y9p&PAGE_TYPE=BlastSearch&USER_DEFAULT_PROG_TYPE=blastn&USER_DEFAULT_MATCH_SCORES=3.";


## get mature positions if options a is set
my %mature_pos_hash;
if($options{'a'} and -f "mirdeep_runs/run_$time/tmp/signature.arf"){
    get_mature_pos();
}

my %confident =();
if($options{b}){
    open IN,"<$options{'b'}" or die "file not found\n";
    while(<IN>){
        next if(/\#/);
        chomp;
        my $r = $_;
        $r =~ s/\|/_/g;
        $confident{$r} = 1;
    }
    close IN;
}


PrintQuantifier();

CloseHTML();
system("cp expression_analyses/expression_analyses_${time}/expression_${time}.html expression_${time}.html");


if(not $options{'d'}){
	$mirbase = 1;
	CreateStructurePDFQuantifier(%hash_q);
}
exit;


sub CreateStructurePDFQuantifier{
    my %hash = @_;
    my $filename;
    print STDERR "creating PDF files\n";
    for(sort { $hash{$b}{"score"} <=> $hash{$a}{"score"} } keys %hash){

        next if(not $hash{$_}{'pdf'});
        next if(not $hash{$_}{'freq_total'});
		$sid = $_;
        $sid =~ tr/\|/_/;
        %star_exp_hit_pos =();
        $filename = $sid;

        if($mirbase){
            $filename = $sid; #$hairpin2mature{$sid};
        }

        next if ($seen{$filename});
		next if(-f "$cwd/pdfs_$time/$filename.pdf");
#		next if($hash{$sid}{"score"} < $threshold); ## skip if threshold is not reached not used anymore
        ## reinit variables;
        $i=0;



        $offset = 0;

        $me=0;     ## mature end coordinate
        @desc;
        
        $lflank1 = 0; ## length(string of left flank)
        $fl1 = 0;    ## 
        $lflank2 = 0; ## length string of right flank
        $fl2b=-1;   ## right flank begin  
        $lloop = 0;   ## string of loop
        $lb=-1;     ## starting position of loop
        $lstar = 0;   ## string of star sequence
        $sb=$mat_pre_arf{$sid}{'sb'};     ## starting 
        $lmature = 0; ## string of mature 
        $mb= $mat_pre_arf{$sid}{'mb'};     ## mature begin
        $struct = 0; ## structure string
        $pri_seq="";## pri-cursor sequence
        $lenstr=0; 

        $pdf;    ## pdf descriptor
        $page;   ## page descriptor
        $gfx;    ## graphic variable
        $trb;    ## fontvariable

        %hash2 = ();
        %hash2c = ();
        %hash2mm = ();
        %hash2order = ();
        %order = ();

        $yorig = 500;
        $downy = 50;

        $dline;                            ## line graphic handler

        $first=1;
        $lastx=0;
        $lasty=0;

        $final="";                         ## final output string of a read
        @pseq;                             ## precursor sequence  
        @rseq;                             ## read sequence

        $totalreads = 0;

        %assign_str = ();
        %assign_str_exp = ();

        %struct = ();
        

        $bpo1=-10;                             ## left nt pos in first bp 
        $bpo2=-10;                             ## right nt pos in first bp 
        $bpo1r=-10;                            ## left nt pos in second bp 
        $bpo2r=-10;                            ## right nt pos in second bp 


        $ffe=0;                                ## first flank end position
        $ff2b=0;                               ## second flank begin position
        
        @sorted;                               ## array that stores sorted order of fl1,m,l,s,fl2 
        $y=$yorig;                             ## y coordinate


        ($minx,$miny,$maxx,$maxy);             ## min and max x,y coordinates of rna sequence
        @rna;                                  ## rna sequence

        %xc = ();
        %yc = ();

    }
}









sub CreatePDFQuantifier{
    my ($hash) = @_;
    $pdf=PDF::API2->new; 
	
    $spacer = length($sid);
    $pdf->mediabox('A4');
    $page=$pdf->page;
    $gfx=$page->gfx;
    $text=$gfx;
    $trb=$pdf->corefont('Times-Roman', -encode=>'latin1');
 
    
    ## move everything except the structure downwards if $mirbase is set
    my $madd = 60;

    $gfx->textlabel($xposshift+20,$y+300+$downy,$trb,8,"miRBase precursor",-color=>'black');
    $gfx->textlabel($xposshift+110,$y+300+$downy,$trb,8,": $sid",-color=>'black');


    $spaces = " " x ($spacer - length($$hash{$sid}{"freq_total"}));
    $gfx->textlabel($xposshift+20,$y+230+$madd+$downy,$trb,8,"Total read count",-color=>'black');       
    $gfx->textlabel($xposshift+110,$y+230+$madd+$downy,$trb,8,": $$hash{$sid}{'freq_total'}",-color=>'black');

    ## here should be written how many annotated stuff is actually there and how many not
    my $jk =10;
	# old
    #for(sort {$$hash{$sid}{'mapped'}{$b} <=> $$hash{$sid}{'mapped'}{$a}} keys %{$$hash{$sid}{'mapped'}}){
	#new
	my @h2m=split(",",$hairpin2mature{$sid});
	foreach my $h(@h2m){
		next if($h =~ /^\s*$/);

        if($options{'t'}){
            next if($_ !~ $options{'m'});
        }
        $spaces = " " x ($spacer - length($_));
        $gfx->textlabel($xposshift+20,$y+230-$jk+$madd+$downy,$trb,8,"$h read count",-color=>'black');      
        $gfx->textlabel($xposshift+110,$y+230-$jk+$madd+$downy,$trb,8,": $$hash{$sid}{'mapped'}{$h}",-color=>'black');
        $jk+=10;
    }

    $spaces = " " x ($spacer - length("remaining reads"));
    $gfx->textlabel($xposshift+20,$y+230-$jk+$madd+$downy,$trb,8,"remaining reads",-color=>'black');      
    $gfx->textlabel($xposshift+110,$y+230-$jk+$madd+$downy,$trb,8,": $$hash{$sid}{'remaining_rc'}",-color=>'black');
    $jk+=10;
    $trb=$pdf->corefont('Courier', -encode=>'latin1');
}




sub ClosePDF{
	my $file = shift;
	$file = "output" if($file eq"");
	$pdf->saveas("$cwd/pdfs_$time/$file.pdf");
}



sub Usage {}
