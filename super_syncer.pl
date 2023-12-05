#!/usr/bin/perl
use strict;

unless (@ARGV >1) {
        &USAGE;
}

sub USAGE {

die '

perl ~/bin/perl/super_syncer.pl  1/2 folder  (target folder)

Mode 1:
Generate a complete list of folders and folder sizes
(run once for each folder you want to sync)

Mode 2: Compare two lists of folders and folder sizes
(make sure original folder is first, and target folder second)

Warning: the two folders you compare must have the same name


';

}

my $mode = shift;
my $in = shift;

if ($mode=~/1/) {
open (OUT, "> $in.fol.sync") || die "\nCannot write to file $in.fol.sync\n";
open (OUT2, "> $in.fil.sync") || die "\nCannot write to file $in.fil.sync\n";


# Find all folders and files in the system
# get the file sizes

my @folders = `find $in -type d -exec du -sk \'{}\' \\;`;
my @files = `find $in -type f -exec ls -l \'{}\' \\;`;

foreach my $fol (@folders) {
    my @ar = split(/\s+/, $fol);
    $fol = "$ar[1]\t$ar[0]";
}

foreach my $fil (@files) {
    my @ar = split(/\s+/, $fil);
    $ar[4]=~s/ //g;
#    $ar[8]=~s/^ //;
    $fil = "$ar[8]\t$ar[4]";
}



foreach my $fol (@folders) {
    print OUT "$fol\n";
}

foreach my $fil (@files) {
    print OUT2 "$fil\n";
}

}

elsif ($mode=~/2/) {
    my $in2 = shift;

    unless ($in2=~/\w+/) {
        &USAGE;
    }


    open (OUT, ">$in2.fol.sync.files_to_sopy") || die "\nCannot write to file $in2.fol.sync.files_to_sopy\n";
    open (OUT3, ">$in2.fol.sync.partial_files") || die "\nCannot write to file $in2.fol.sync.partial_files\n";
    open (OUT2, ">$in2.fol.sync.newcoms") || die "\nCannot write to file $in2.fol.sync.newcoms\n";


    # Read in both lists of folders
    open (IN, "<$in.fol.sync") || die "\nCannot write to file $in.fol.sync\n";
    open (IN2, "<$in2.fol.sync") || die "\nCannot write to file $in2.fol.sync\n";
    
    my %in;
    my %in2;
    my %in2fols;

    while (<IN>) {
        chomp;
        $in{$_}=1;
    }
    while (<IN2>) {
        chomp;
        $in2{$_}=1;
        my @ar = split(/\t/, $_);
        $in2fols{$ar[0]}=$ar[1];
    }


    # Get shared folders

    foreach my $key (keys %in) {
        #print "#$key#\n";
        if (exists $in2{$key}) {
            #print "Exists $key\n";
        }
        else {
            my @ar = split(/\t/, $key);
            if (exists $in2fols{$ar[0]}) {
                print "#Folder exists $ar[0]   - but not the right size  $in2fols{$ar[0]} compared to original $ar[1] \n";
            }
            else {
                print OUT2 "mkdir $ar[0]\n";
            }
        }
    }


    close (IN);
    close (IN2);

    # Now lets deal with the files



    # Read in both lists of files
    open (IN, "<$in.fil.sync") || die "\nCannot write to file $in.fil.sync\n";
    open (IN2, "<$in2.fil.sync") || die "\nCannot write to file $in2.fil.sync\n";
   
    #print "\n#Reading in file-lists\n\n";
    my %fin;
    my %fin2;
    my %fin2fols;

    while (<IN>) {
        chomp;
        my @ar = split(/\t/, $_);
        $fin{$ar[0]}=$ar[1];
    }
    while (<IN2>) {
        chomp;
        my @ar = split(/\t/, $_);
        $fin2{$ar[0]}=$ar[1];
        $fin2fols{$ar[0]}=$ar[1];
    }




    # Get shared files

    foreach my $key (keys %fin) {
        # Does the file exist
        if (exists $fin2{$key}) {

            # is it the right size

            if ($fin2{$key}=~/$fin{$key}/ and $fin{$key}=~/$fin2{$key}/ ) {
		    #print "#File exists and is identical $key\n";
            }
            elsif($fin{$key} > $fin2{$key} ) {
                print OUT3 "Exists but is not identical $key  original $fin{$key} target $fin2{$key}\n";
            }
            else {
                print OUT3 "Exists but is not identical $key  original $fin{$key} target $fin2{$key} # WARNING! Target file is larger\n";
            }

        }
        else {
                print OUT "$key\t#\t$fin{$key}\n";
            
        }
    }






system "cat $in2.fol.sync.newcoms | sort > $in2.fol.sync.newcoms.sh";
system "rm -f $in2.fol.sync.newcoms ";


print "\n\n#Good news, Syncing is ready now.\n";
print "#Please go to the target folder and execute this command:\n\n";
print "bash $in2.fol.sync.newcoms.sh\n\n";

print "Then take this list of files and copy over:\n\n";
print "wc -l $in2.fol.sync.files_to_sopy\n\n";


print "These files exist in both locations but have different file sizes:\n\n";
print "wc -l $in2.fol.sync.partial_files\n\n";




}

else {
    &USAGE;

}

exit;



__END__


Or rsync:

rsync -av -e "ssh -p12345" clusteruser@localhost:/location/on/the/cluster .


