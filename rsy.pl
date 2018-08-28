#!/usr/local/bin/perl -w

use strict;




unless (@ARGV == 3) {
        &USAGE;
}

sub USAGE {

die 'Usage: rsy.pl f/t file destination


Example 1:

perl ~/bin/perl/rsy.pl f ~/bin/perl/rsy.pl /home/mzarowiecki/bin/perl
Transfers file  rsy.pl _from_ here to LSF:/home/mzarowiecki/bin/perl


Example 2:

perl ~/bin/perl/rsy.pl f /home/mzarowiecki/bin/perl/rsy.pl /Users/magz/Desktop
Transfers file  rsy.pl _from_ LSF to /home/mzarowiecki/bin/perl


f=from LSF
t=to LSF



'
}

my $dc = shift;
my $f = shift;
my $d = shift;


# To LSF
if ($dc=~/t/) {
	print "\nrsync -av $f mzarowiecki\@10.5.8.15:$d\n\n";
	my $res = `rsync -av $f mzarowiecki\@10.5.8.15:$d` ;
	#print "RESULTS:\n\n$res\n";
}
# From LSF
elsif ($dc=~/f/) {
	print "\nrsync -av mzarowiecki\@10.5.8.15:$f $d\n\n";
	#my $res = `rsync -av mzarowiecki\@10.5.8.15:$f $d` ;
	#print "RESULTS:\n\n$res\n";
}

exit;


