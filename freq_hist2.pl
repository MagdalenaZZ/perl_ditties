#!/usr/bin/perl -w

use strict;

use GD;
use GD::Graph::hbars;
use GD::Graph::lines;
use GD::Graph::points;
use GD::Graph::linespoints;
use GD::Graph::histogram;

unless (@ARGV > 0) {
        &USAGE;
}




sub USAGE {

    die '


Usage: fasta_histogram.pl file

This program takes a file and makes a histogram of assembly-lengths

    ' . "\n";
}

my $query = shift;

open (FAS, "<$query") || die "I can't open $query\n";
#my @fas = <FAS>;
#close (FAS);
# Open reference 
my %fas;
my @fas;
my $max = 0;

# Determine maximum length and save data to fas
my $i = "a";

while (<FAS>) {
    my @arr = split(/\s+/, $_);
    $fas{ $i } = $arr[1];
    if ($arr[1]=~/\d+/) {
        push (@fas, $arr[1]);
        $i++;
    }
    if ($arr[1] > $max) {
        $max = $arr[1];
    }
    #print "$i\t$arr[1]\n";

}

# Determine X-bins max

my $roundup;

sub roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}

$max = $max / 100;
$roundup = 100* roundup($max);

#print "$roundup\n";

my %res;

# for each bin, count up how many transcripts are in that bin

for (my $start = 0; $start < $roundup; $start += 10 ) {
    #print "$start\t$roundup\n";
    foreach my $key (keys %fas ) {
        #print "key $fas{$key}\n";
        if ( $fas{$key} >= $start and $fas{$key} < ($start+10) ) {
            #print "Match $start $fas{$key} \n";
            $res { $start } += 1;
        }
    }
    unless (exists $res{ $start }) {
        $res { $start } = 0;
    }
}

open (OUT, ">$query.txt") || die;
foreach my $key2 (sort {$a <=> $b} keys %res ) {
    print OUT "$key2\t$res{$key2}\n";
}
close (OUT);


#my ($ymax, $yticks) = scale($max,100);

#$opt{y_max_value}   = $max + 100;          # Fixed
#$opt{y_tick_number} = 10;
#plot(\%opt, \@data, 'hb');
#print "@fas\n";


draw_graph( "$query.png" , @fas );

sub draw_graph {
    my ( $filename, @fas ) = @_;
    my $graph = new GD::Graph::histogram( 1000, 1000 );
    $graph->set(
        x_label           => 'Data',
        y_label           => 'Count',
        title             => 'A Histogram Chart',
        x_labels_vertical => 1,
        bar_spacing       => 1,
        shadow_depth      => 0,
        shadowclr         => 'dred',
        transparent       => 0,
        histogram_type => 'count',
        histogram_bins => $max ,
        x_max_value       => $roundup,
        y_min_value       => 0,
        x_min_value       => 0,

      )
      or warn $graph->error;

    my $gd = $graph->plot( \@fas ) or die $graph->error;

    open( IMG, '>' . $filename ) or die $!;
    binmode IMG;
    print IMG $gd->png;
}





