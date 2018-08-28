#!/usr/bin/perl
use strict;
use Cwd;
use File::Slurp;

my $cwd = cwd();




sub USAGE {

die ' 



perl ~/bin/perl/cleaner_script.pl  folder

Give a folder, and the script will look for files which can be cleaned or changed and output a list of suggested commands


';

}



unless (@ARGV > 0) {
        &USAGE;
}


my $in  = shift;

my $in2=$in;
$in2=~s/\//\./g;

open (OUT, ">$in2.suggested_clean.sh") || die "Cant make file $in2.suggested_clean.sh";


# get rid of empty files

print "\nFind 1\n";
system "find  $in  -type f -empty  > $in2.suggested_clean.empty ";





# find dirs and files
print "Find 2\n";
system "find  $in -type d > $in2.suggested_clean.dirs";
print "Find 3\n";
system "find $in -type f  > $in2.suggested_clean.files";

print "Read clean\n";
open(FILE, "<$in2.suggested_clean.files") ||  die "Cant open file $in2.suggested_clean.files";
open(OUT4, ">$in2.suggested_clean.folder_counts") ||  die "Cant open file $in2.suggested_clean.folder_counts";

my @file = <FILE>;
my %fols;

foreach my $fil (@file) {
    chomp $fil;

    my @arr = split(/\//, $fil);
    pop(@arr);
    my $fol = join( "\/", @arr);
    $fols{$fol}+=1;
}

close(FILE);

print "Write clean\n";
foreach my $elem (keys %fols) {
    print OUT4 "$elem\t$fols{$elem}\n";
}

close (OUT4);



# go through directories

open(DIR, "<$in2.suggested_clean.dirs") ||  die "Cant open file $in2.suggested_clean.dirs";

while (<DIR>) {
    chomp;

    my @arr = split(/\//, $_);

    # ignore software
    if ( $_=~/UNUSED_SOFTWARE/ ) {
        next;
    }
    if ($arr[-1]=~/^old$/i) {
        unless ($_=~/fold/ or $_=~/scaffold/ or $_=~/gold/   ) {
            print OUT  "rm -fr $_ # OLD\n";
        }
    }
    if  ($_=~/\.temp/i or $_=~/\.tmp/i  ) {
        print OUT "rm -fr \t$_ # TEMP\n";
    }
    if  ($_=~/test/i and not $_=~/test_/i  and not $_=~/_test/i  ) {
        print OUT "rm -fr \t$_ # TEST\n";
    }
    if ($_=~/\_Inline/) {
        print OUT "rm -fr \t$_ # INLINE\n";
    
    }



}

close (DIR);



# go through files

open(FILE, "<$in2.suggested_clean.files") ||  die "Cant open file $in2.suggested_clean.files";

while (<FILE>) {
    chomp;

    my @arr = split(/\//, $_);

    # ignore software
    if ( $_=~/UNUSED_SOFTWARE/ ) {
        next;
    }

    # temporary
    elsif  ($_=~/\.temp/i or $_=~/\.tmp/i  ) {
        print OUT "rm -f \t$_ # TEMP\n";
    }
    # temporary
    elsif  ($_=~/Cache\/AllAll/   ) {
        print OUT "rm -f \t$_ # OMA\n";
    }
    # test
    elsif  ($arr[-1]=~/test/i   ) {
        print OUT "rm -f \t$_ # TEST\n";
    }
    # indexes
    elsif  ($_=~/.bai$/i or $_=~/.fai$/i or $_=~/.tbi$/i  or $_=~/.bti$/i or $_=~/.fai.gz$/i  or $_=~/.bai.gz$/i  or $_=~/.tbi.gz$/i  ) {
        print OUT "rm -f \t$_ # INDEX\n";
    }
    # lists
    elsif  ($_=~/.list$/ ) {
        print OUT "rm -f \t$_ # LIST\n";
    }
    # mapping
    elsif  ($_=~/\.info$/ or $arr[-1]=~/out\.sorted\.markdup\.bam\.insert\.gp/ or $arr[-1]=~/out\.raw\.bam/ or $arr[-1]=~/stage-2\.mapping-job-array\.o/ ) {
        print OUT "rm -f \t$_ # MAPPING\n";
    }
    # mapping
    elsif  ($arr[-1]=~/ebwt.gz$/ or $arr[-1]=~/bt2.gz$/ or $arr[-1]=~/ebwt$/  or $arr[-1]=~/bt2$/  ) {
        print OUT "rm -f \t$_ # INDEX\n";
    }
    # samfiles
    elsif  ($_=~/\.sam$/ ) {
        print OUT "samtools view -S -b \t$_ > $_\.bam # SAM\n";
    }
    # database fetch
    elsif  ($arr[-1]=~/www_bget/ ) {
        print OUT "rm -f $_ # DB\n";
    }
    # quality
    elsif  ($arr[-1]=~/\.qual$/ ) {
        print OUT "rm -f $_ # QUAL\n";
    }
    # blast
    elsif  ($arr[-1]=~/tmp-qry-split/ or $arr[-1]=~/tmp-blast-split/  ) {
        print OUT "rm -f $_ # BLAST\n";
    }
    # blast
    elsif  ($arr[-1]=~/01.setup.sh/ or $arr[-1]=~/02.run_array/ or $arr[-1]=~/03.combine.sh/   ) {
        print OUT "rm -f $_ # BLAST\n";
    }
    # interpro
    elsif  ($arr[-1]=~/^\d+.seq.gz$/ or $arr[-1]=~/^\d+.seq$/  ) {
        print OUT "rm -f $_ # IP\n";
    }

    # old
    elsif ($_=~/\.old/i) {
        unless ($_=~/fold/ or $_=~/scaffold/ or $_=~/gold/  ) {
            print OUT  "rm -f $_ # OLD\n";
        }
    }
    # temporary
    elsif  ($arr[-1]=~/^\./ or $arr[-1]=~/\~$/   ) {
        print OUT "rm -f $_ # INVISIBLE\n";
    }
    # cufflinks
    elsif  ($arr[-1]=~/^skipped\.gtf\.gz$/ or $arr[-1]=~/^skipped\.gtf$/ or $arr[-1]=~/^genes\.fpkm_tracking/ or $arr[-1]=~/^genes\.fpkm_tracking\.gz/   ) {
        print OUT "rm -f $_ # CUFFLINKS\n";
    }
    # uniprot
    elsif  ($arr[-1]=~/^\w{6}\.fasta\.gz$/ or $arr[-1]=~/^\w{6}\.fasta$/ ) {
        print OUT "rm -f $_ # UP\n";
    }
    # office
    elsif  ($arr[-1]=~/\.docx$/ or $arr[-1]=~/\.pptx$/  or $arr[-1]=~/\.xlsx$/ or $arr[-1]=~/\.pdf$/) {
        #print OUT "rm -f $_ # OFFICE\n";
        }
   # gzip
    elsif ($_!~/.gz$/ and not $_=~/suggested_clean/  ) {
        unless ($_=~/\.z$/ or $_=~/\.bam$/) {
            print OUT "gzip $_ # GZIP\n";
        }
    }

    else {
        # good file
    }



}

close (FILE);



system "cat $in2.suggested_clean.dirs | awk '{print \"find \"\$1\" -prune -empty\" }' > $in2.suggested_clean.dirs.sh ";
print "bash $in2.suggested_clean.dirs.sh > $in2.suggested_clean.dirs.sh.empty \n";





my $advice = `cat $in2.suggested_clean.sh | awk -F\'# \' \'{print \$2}\' | sort | uniq -c `;

print "\nSummary:\n$advice\n";

print "\nDont forget to remove files:\nrm -f $in2.suggested_clean.files $in2.suggested_clean.dirs $in2.suggested_clean.sh\n\n";


exit;






__END__


# list all the directories in the folder

my @paths = read_dir( "$in", prefix => 1 ) ;
my @dirs;



# Collect all folders in this folder

foreach my $folder (@paths) {
	if (-d "$folder") {
        push (@dirs, $folder);
        print "$folder\n";
    }
	else {
#		print "Is file $folder\n";
	}
}


# Go to second level





chdir $in;

#__END__

# for each directory, make a du-call
foreach my $dir (@dirs) {

    print "du -sk $dir\n";
#    my $res = `du -sk $dir `;
    print  "$dir\n";
}



