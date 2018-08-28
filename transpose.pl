#!/usr/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}




sub USAGE {

    die '


Usage: transpose.pl  file

Transposes a tab-delimited file nad prints to STDOUT

    ' . "\n";
}



my(%data);          # main storage
my($maxcol) = 0;
my($rownum) = 0;
while (<>) {
    chomp;
    my(@row) = split /\t/;
    my($colnum) = 0;
    foreach my $val (@row)
    {
        $data{$rownum}{$colnum++} = $val;
    }
    $rownum++;
    $maxcol = $colnum if $colnum > $maxcol;
}

my $maxrow = $rownum;
for (my $col = 0; $col < $maxcol; $col++)
{
    for (my $row = 0; $row < $maxrow; $row++)
    {
        printf "%s%s", ($row == 0) ? "" : "\t",
                defined $data{$row}{$col} ? $data{$row}{$col} : "";
    }
    print "\n";
}

exit;


