#!/usr/local/bin/perl -w

use strict;




unless (@ARGV == 3) {
        &USAGE;
}

sub USAGE {

die 'Usage: scp.pl f/t file destination


Example 1:

perl ~/bin/perl/scp.pl t ~/bin/perl/scp.pl /home/mzarowiecki/bin/perl
Transfers file  scp.pl to LSF:/home/mzarowiecki/bin/perl


Example 2:

perl ~/bin/perl/scp.pl f /home/mzarowiecki/bin/perl/scp.pl /Users/magz/Desktop
Transfers file  scp.pl _from_ LSF to /home/mzarowiecki/bin/perl


f=from LSF
t=to LSF



'
}


my $dc = shift;
my $f = shift;
my $d = shift;

# To LSF
if ($dc=~/t/) {
	print "\nscp -pr $f mzarowiecki\@10.5.8.15:$d\n\n";
	my $res= `scp -pr $f mzarowiecki\@10.5.8.15:$d`;
}
# From LSF
elsif ($dc=~/f/) {
	print "\nscp -pr  mzarowiecki\@10.5.8.15:$f $d\n\n";
	my $res= `scp -pr  mzarowiecki\@10.5.8.15:$f $d`;
}


exit;


