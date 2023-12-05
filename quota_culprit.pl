#!/usr/bin/perl
use strict;
use Cwd;
use File::Slurp;

my $cwd = cwd();


unless (@ARGV > 0) {
        &USAGE;
}


my $in  = shift;

open (OUT, ">>culprit");



# list all the directories in the folder

my @paths = read_dir( "$in", prefix => 1 ) ;
my @dirs;

# print "len(@paths)";

foreach my $folder (@paths) {
#    print "$in\/$folder\n";
	if (-d "$in\/$folder") {
        push (@dirs, $folder);
    }
	else {
#		print "Is file $folder\n";
	}
}

chdir $in;

# for each directory, make a du-call
foreach my $dir (@dirs) {

#    print "du -sk $dir\n";
    my $res = `du -sk $dir `;
    print OUT "$res\n";
}

# sort and organise the output

# report result

system "cat $cwd/culprit | grep -v \'^\$\' | sort -nr";






sub USAGE {

die ' 

Give folder you want to look at

';

}


