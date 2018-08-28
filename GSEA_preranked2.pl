#!/usr/bin/perl
use strict;

unless (@ARGV >2) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/GSEA_preranked.pl <iterations> ranked-list  geneset custom_geneset(y, n)

Then: 
perl GSEA_preranked.pl 1000 lfc.rnk /users/k1470436/brc_scratch/REFERENCES/msigdb.v6.0.symbols.gmt n &




ranked-list has this structure:

Gene_ID   <TAB>  3.21
Gene_ID   <TAB>  -3.1
Gene_ID   <TAB>  -1.6
Gene_ID   <TAB>  0

GeneID will have to be  symbols, i.e. RSF1	ARID4A	NR6A1	TIMM50


Geneset is downloaded from MSigDB .gmt format
default is "msigdb.v6.0.symbols.gmt"





';

}

my $n = shift;
my $rank = shift;
#my $out = shift;
#my $gs = "/Users/magz/gsea_home/my_refs/msigdb.v5.0.symbols.gmt";
my $gs = shift;

=pod
unless ($rank=~/.rnk/) {



#my $rosetta = "/users/k1470436/scratch/REFERENCES/ENSG_2_symbol.chip";
my $rosetta = "/users/k1470436/scratch/REFERENCES/ENSM_2_symbol.chip";


if ($rank=~/.rnk$/) {
    #sopen (OUT, "$rank") || die "Cannot open file $rank\n";
	
}

else {
# Read rosetta

my %syms;

open (IN, "<$rosetta") || die "Cannot find file $rosetta \n";


while (<IN>) {
    chomp;
    my @ar=split(/\t/, $_);
    if (exists $syms{$ar[1]}) {
        #print "Warn: duplicate $ar[1]\n";
    }
    $syms{$ar[0]}="$ar[1]";
	#print "$ar[1]\t$ar[0]\n";
}

close(IN);

open (D, "<$rank") || die "Cannot find file $rank \n";
open (OUT, ">$rank.rnk") || die "Cannot open file $rank.rnk \n";


while (<D>) {
    chomp;
    my @ar=split(/\t/,$_);

    if (exists $syms{$ar[0]} and $ar[1]!~/NA/) {
        print OUT "$syms{$ar[0]}\t$ar[1]\n";
    }
    else {
        print "Excluded $_\n";
    }


}

$rank=$rank . ".rnk";

}

}

=cut

#print "\njava -Xmx1024m -cp ~/bin/gsea2-2.2.0.jar xtools.gsea.GseaPreranked -gmx $gs -collapse false -mode Max_probe -norm meandiv -nperm $n -rnk $rank.rnk -scoring_scheme weighted -rpt_label my_analysis -chip /Users/magz/gsea_home/annotations/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 200 -rnd_seed timestamp -set_max 5000 -set_min 4 -zip_report false -out $rank\_OUT -gui true > $rank.err \n\n";

#system "java -Xmx1024m -cp ~/bin/gsea2-2.2.0.jar xtools.gsea.GseaPreranked -gmx $gs -collapse false -mode Max_probe -norm meandiv -nperm $n -rnk $rank.rnk -scoring_scheme weighted -rpt_label my_analysis -chip /Users/magz/gsea_home/annotations/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 200 -rnd_seed timestamp -set_max 5000 -set_min 4 -zip_report false -out $rank\_OUT -gui true > $rank.err";


print "\njava -Xmx2048m  -cp ~/bin/gsea2-2.2.4.jar xtools.gsea.GseaPreranked -gmx $gs -collapse false -mode Max_probe -norm meandiv -nperm $n -rnk $rank -scoring_scheme weighted -rpt_label my_analysis -chip ~/scratch/REFERENCES/GSEA/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 1000 -rnd_seed timestamp -set_max 5000 -set_min 4 -zip_report false -out $rank\_OUT -gui false > $rank.err \n\n";

print "Starting gsea\n";
system "java -Xmx6g -cp ~/bin/gsea2-2.2.4.jar xtools.gsea.GseaPreranked -gmx $gs -collapse false -mode Max_probe -norm meandiv -nperm $n -rnk $rank -scoring_scheme weighted -rpt_label my_analysis -chip ~/scratch/REFERENCES/GSEA/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 1000 -rnd_seed timestamp -set_max 5000 -set_min 4 -zip_report false -out $rank\_OUT -gui false > $rank.err";

#java -Xmx512m xtools.gsea.GseaPreranked -gmx /users/k1470436/bin/msigdb.v5.1.symbols.gmt -collapse false -mode Max_probe -norm meandiv -nperm 10 -rnk /users/k1470436/scratch/PROJECTS/Humanised/11.GSEA/test3.rnk -scoring_scheme weighted -rpt_label my_analysis -chip /users/k1470436/gsea_home/annotations/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 20 -rnd_seed timestamp -set_max 500 -set_min 15 -zip_report false -out /users/k1470436/gsea_home/output/jun21 -gui false

print "Done GSEA $rank\n";

#<STDIN>;

#system "java -Xmx1024m -cp ~/bin/gsea2-2.2.0.jar xtools.gsea.GseaPreranked -gmx $gs -collapse false -mode Max_probe -norm meandiv -nperm $n -rnk $rank.rnk -scoring_scheme weighted -rpt_label my_analysis -chip /Users/magz/gsea_home/annotations/GENE_SYMBOL.chip -include_only_symbols true -make_sets true -plot_top_x 20 -rnd_seed timestamp -set_max 5000 -set_min 1 -zip_report false -out $rank\_OUT -gui true >  $rank.err";



# parse results

system "mkdir $rank.O";
system "mv $rank\_OUT/my*/g*.xls $rank.O/ \n ";wait;
system "mv $rank\_OUT/my*/r*.xls $rank.O/ \n ";wait;
system "rm -f $rank\_OUT/my*/R*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/B*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/K*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/S*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/M*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/P*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/L*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/C*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/G*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/W*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/H*.html\n ";wait; 
system "rm -f $rank\_OUT/my*/*UP.html\n ";wait; 
system "rm -f $rank\_OUT/my*/*DN.html\n ";wait; 
system "rm -f $rank\_OUT/my*/*.html\n ";wait; 
system "gzip $rank\_OUT/my*/g*.xls "; wait;
system "gzip $rank\_OUT/my*/r*.xls "; wait;
system "gzip $rank\_OUT/my*/R*.xls "; wait;
system "gzip $rank\_OUT/my*/B*.xls "; wait;
system "gzip $rank\_OUT/my*/K*.xls "; wait;
system "gzip $rank\_OUT/my*/M*.xls "; wait;
system "gzip $rank\_OUT/my*/S*.xls "; wait;
system "gzip $rank\_OUT/my*/P*.xls "; wait;
system "gzip $rank\_OUT/my*/L*.xls "; wait;
system "gzip $rank\_OUT/my*/C*.xls "; wait;
system "gzip $rank\_OUT/my*/G*.xls "; wait;
system "gzip $rank\_OUT/my*/W*.xls "; wait;
system "gzip $rank\_OUT/my*/H*.xls "; wait;
system "gzip $rank\_OUT/my*/D*.xls "; wait;
system "gzip $rank\_OUT/my*/T*.xls "; wait;
system "gzip $rank\_OUT/my*/*UP.xls "; wait;
system "gzip $rank\_OUT/my*/*DN.xls "; wait;
system "gzip $rank\_OUT/my*/*.xls "; wait;
system "mv $rank\_OUT/my*/R*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/B*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/K*.xls.gz $rank.O/ \n ";wait;
system "mv $rank\_OUT/my*/M*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/S*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/P*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/L*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/C*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/G*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/W*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/H*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/D*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/T*.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/*UP.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/*DN.xls.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/*.xls.gz $rank.O/ \n ";wait; 
system "gzip $rank\_OUT/my*/enplot_R*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_B*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_K*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_S*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_T*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_M*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_P*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_L*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_C*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_G*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_W*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_H*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_D*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_T*.png "; wait;
system "gzip $rank\_OUT/my*/enplot_*.png "; wait;
system "mv $rank\_OUT/my*/enplot_R*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_B*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_K*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_S*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_T*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_M*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_P*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_L*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_C*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_G*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_W*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_H*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_D*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_T*.png.gz $rank.O/ \n ";wait; 
system "mv $rank\_OUT/my*/enplot_*.png.gz $rank.O/ \n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_1*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_2*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_3*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_4*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_5*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_6*.png\n ";wait; 
system "rm -f $rank\_OUT/my*/gset_rnd_es_dist_*.png\n ";wait; 
system "mv $rank\_OUT/my*/*.* $rank.O/ \n ";wait; 
system "unzip $rank.O/gsea_report_for_na_pos_*.xls";
system "unzip $rank.O/gsea_report_for_na_neg_*.xls";
system "ln -s $rank.O/gsea_report_for_na_neg_*.xls $rank.neg ";
system "ln -s $rank.O/gsea_report_for_na_pos_*.xls $rank.pos "; 
system "cp $rank.neg $rank.neg.xls2 ";
system "cp $rank.pos $rank.pos.xls2 ";


open (IN2, "<$rank.neg") || die "Cannot find file $rank.O/my*/gsea_report_for_na_neg_* \n";
open (IN3, "<$rank.pos") || die "Cannot find file $rank.O/my*/gsea_report_for_pos_neg_* \n";



open (OUT2, ">$rank.neg.gs.txt") || die "Cannot find file $rank.neg.gs.txt \n";
open (OUT22, ">$rank.neg.genes.txt") || die "Cannot find file $rank.neg.genes.txt\n";

print "Doing $rank negative...\n\n";

#open (OUT3, "<$rank.pos") || die "Cannot find file $rank.O/gsea_report_for_pos_neg_* \n";

# Deal with negative values

mkdir("$rank.Final_out_neg");
system "cp $rank.neg.xls $rank.Final_out_neg";


while (<IN2>) {
    chomp;
    my @ar2 =split(/\t/,$_);

    if ($ar2[0]=~/^NAME$/) {
        print OUT2 "$ar2[0]\t\t$ar2[4]\t$ar2[5]\t$ar2[7]\t$ar2[8]\t$ar2[9]\t$ar2[10]\tSignificant\tNon-significant\n";    
    }
    elsif ($ar2[3]>5) {
        print OUT2 "$ar2[0]\t\t$ar2[4]\t$ar2[5]\t$ar2[7]\t$ar2[8]\t$ar2[9]\t$ar2[10]\t";

        # Move results-files to final
        
        #print "ls $rank.O/$ar2[0].xls\n";
        open (TMP, "<$rank.O/$ar2[0].xls") ||  next ;

    
        my @gn;
        my @gs;

        while (<TMP>) {
            chomp;
            my @t =split(/\t/,$_);
            if ($t[0]=~/^NAME$/) {
                print OUT22 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";   
            }
            elsif ($t[7]=~/Yes/ ) {
                print OUT22 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";
                push(@gs, "$t[1]");
            }
            elsif ( $t[7]=~/No/ ) {
                print OUT22 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";
                push(@gn, "$t[1]");
            }            


        
        }

        close(TMP);
        system "cp $rank.O/$ar2[0]*.xls $rank.Final_out_neg ";
        system "cp $rank.O/enplot_$ar2[0]*.png $rank.Final_out_neg ";
      
            my $gs = join(",", @gs);
            my $gn =join(",", @gn);
            print OUT2 "$gs\t$gn";


    }
            print OUT2 "\n";   
}

#print OUT2 "\n\n";
close(OUT2);


# Deal with positive values


open (IN3, "<$rank.pos") || die "Cannot find file $rank.pos  \n";
open (OUT2, ">$rank.pos.gs.txt") || die "Cannot find file $rank.pos.gs.txt \n";
open (OUT33, ">$rank.pos.genes.txt") || die "Cannot find file $rank.pos.genes.txt\n";

print "Doing $rank  positive...\n\n";

mkdir("$rank.Final_out_pos");
system "cp $rank.pos.xls $rank.Final_out_pos";

while (<IN3>) {
    chomp;
    my @ar2 =split(/\t/,$_);

    if ($ar2[0]=~/^NAME$/) {
        print OUT2 "$ar2[0]\t\t$ar2[4]\t$ar2[5]\t$ar2[7]\t$ar2[8]\t$ar2[9]\t$ar2[10]\tSignificant\tNon-significant\n";    
    }
    elsif ($ar2[3]>5) {
        print OUT2 "$ar2[0]\t\t$ar2[4]\t$ar2[5]\t$ar2[7]\t$ar2[8]\t$ar2[9]\t$ar2[10]\t";

        # Move results-files to final
        
        #print "ls $rank.O/$ar2[0].xls\n";
        open (TMP, "<$rank.O/$ar2[0].xls") || next ;
 
    
        my @gn;
        my @gs;

        while (<TMP>) {
            chomp;
            my @t =split(/\t/,$_);
            if ($t[0]=~/^NAME$/) {
                print OUT33 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";   
            }
            elsif ($t[7]=~/Yes/ ) {
                print OUT33 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";
                push(@gs, "$t[1]");
            }
            elsif ( $t[7]=~/No/ ) {
                print OUT33 "$ar2[0]\t$t[1]\t$t[3]\t$t[4]\t$t[5]\t$t[6]\t$t[7]\n";
                push(@gn, "$t[1]");
            }            


        
        }

        close(TMP);
        system "cp $rank.O/$ar2[0]*.xls $rank.Final_out_pos ";
        system "cp $rank.O/enplot_$ar2[0]*.png $rank.Final_out_pos ";
      
            my $gs = join(",", @gs);
            my $gn =join(",", @gn);
            print OUT2 "$gs\t$gn";

    }
            print OUT2 "\n";    
}

#print OUT2 "\n\n";


close(OUT2);

#### clean up ########
#

system "rm -f $rank.pos $rank.neg ";
#system "rm -fr $rank.O ";
system "mkdir $rank\_Final_out";
system  "mv $rank.* $rank\_Final_out";
#system "rm -fr $rank\_OUT";


exit;





