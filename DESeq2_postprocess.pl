#!/usr/bin/perl
use strict;
#use Clone qw(clone);

unless (@ARGV == 3) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/DESeq_postprocess.pl <DESeq2.txt>  <GO-file> <prod-file>



GO-file has this structure:

Gene_ID   <TAB>  GOterm,GOterm,GOterm


Prod file has this structure:

Gene_ID   <TAB>  product


';

}



# check that DESeq ran okay

my $dir = shift;
my $go = shift;
my $prod = shift;

unless (-s "$dir") {
    die "\nSorry, the file $dir wasnt made\n";
}



# make nice scores

system "cat $dir | sed \'s/\"//g\' | tr \' \' \'\\t\' | sed \'s/ID=//g\' > $dir.scores.dat";


# make nice dn
system "cat $dir.scores.dat | grep -v baseMean | grep -w -v NA|  awk '\$7\<0.05' | awk '\$3\~\"-\"' | awk '\{print \$0\"\\tDN\"\}'  > $dir.DN";
system "cat $dir.DN | cut -f1 | awk \'{print \$1}\' > $dir.dn.list ";
system "cat $dir.DN | awk \'\$3\<-2\' | awk \'{print \$1}\' > $dir.DN.2LFC";
system "cat $dir.DN | awk \'\$3\<-1\' | awk \'{print \$1}\' > $dir.DN.1LFC";
#print "cat $dir.scores.dat |  grep -v baseMean | awk '\$7\<0.05' | awk '\$3\~\"-\"' | awk '\{print \$0\"\\tDN\"\}'  > $dir.DN\n";
#print "cat $dir.DN | cut -f1 | awk \'{print \$1}\' > $dir.dn.list \n";

#print  "cat $dir.scores.dat | awk '\$8\<0.05' | awk '\$3!\~\"-\"' | awk '\{print \$0\"\\tUP\"\}'  > $dir.dn\n";
#system "cat $dir/lib.dat.dn | cut -f2 | awk -F\'\.\' \'{print \$1}\' > $dir/lib.dat.dn.list ";

# make nice up 
system "cat $dir.scores.dat | grep -v baseMean  | grep -w -v NA| awk '\$7\<0.05' | awk '\$3!\~\"-\"' | awk '\{print \$0\"\\tUP\"\}' > $dir.UP";
system "cat $dir.UP | cut -f1  | awk  \'{print \$1}\' > $dir.up.list ";
system "cat $dir.UP | awk \'\$3\>2\' | awk \'{print \$1}\' > $dir.UP.2LFC";
system "cat $dir.UP | awk \'\$3\>1\' | awk \'{print \$1}\' > $dir.UP.1LFC";
#print "cat $dir.scores.dat | grep -v baseMean  | awk '\$7\<0.05' | awk '\$3!\~\"-\"' | awk '\{print \$0\"\\tUP\"\}' > $dir.UP\n";
#print "cat $dir.UP | cut -f1 | awk  \'{print \$1}\' > $dir.up.list \n";
#system "cat $dir/lib.dat.up | cut -f2 | awk -F\'\.\' \'{print \$1}\' > $dir/lib.dat.up.list ";


# make nice non-sign
system "cat $dir.scores.dat | awk '\$7\>0.05'  | awk '\{print \$0\"\\tNS\"\}' > $dir.NS";
#print "cat $dir.scores.dat | awk '\$7\>0.05'  | awk '\{print \$0\"\\tNS\"\}' > $dir.NS\n";


__END__

system "cat $dir.UP $dir.DN $dir.NS > $dir.txt ";
#print "cat $dir.UP $dir.DN $dir.NS > $dir.txt\n";

#print "\nRunning topGO dn \nperl ~/bin/perl/topGO_starter.pl $dir.dn.list $go BP $prod $dir.dn &\n";
system "perl ~/bin/perl/topGO_starter.pl $dir.dn.list $go BP $prod $dir.dn";

#print "\nRunning topGO up \nperl ~/bin/perl/topGO_starter.pl $dir.up.list $go BP $prod $dir.up &\n";
system "perl ~/bin/perl/topGO_starter.pl $dir.up.list $go BP $prod $dir.up";

print "All done\n";



__END__

perl ~/bin/perl/foreach.pl "cat X | grep DN | awk '{print 2}' > X.dn" *vs*/lib.dat | sed 's/ 2/ $2/' | tail -100 > dn.sh
perl ~/bin/perl/foreach.pl "cat X | grep UP | awk '{print 2}' > X.up" *vs*/lib.dat | sed 's/ 2/ $2/' | tail -100 > up.sh


# do topGO for dn and up
perl ~/bin/perl/topGO_starter.pl aPS_vs_aPS/lib.dat.dn ../EMU_2013_06_09.gff.GOtop BP ../EMU_2013_06_09.prod aPS_vs_aPS/lib.dat.dn;
perl ~/bin/perl/topGO_starter.pl aPS_vs_MCana/lib.dat.dn ../EMU_2013_06_09.gff.GOtop BP ../EMU_2013_06_09.prod aPS_vs_MCana/lib.dat.dn;





