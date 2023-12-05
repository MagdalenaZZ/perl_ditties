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


Usage: freq_histogram.pl file

This program takes a file with a column with numbers and draws a frequency histogram from it.
Using perl module, not R



    ' . "\n";
}

my $query = shift;
my $stepsize = 1;

open (IN, "<$query") || die "I can't open $query\n";
#my @fas = <FAS>;
#close (FAS);
# Open reference 
my %fas;
my @fas;
my $max = 0;

# Determine maximum length and save data to fas
my $i = "a";

while (<IN>) {
    chomp;
    $fas{ $i } = $_;
    if ($_=~/\d+/ or $_=~/\d+\.\d+/  ) {
        push (@fas, $_);
        $i++;
    
        if ($_> $max) {
            $max = $_;
        }
    }
    else {
        #print "ignored $_\n";
    }
    #print "$i\t$_\n";
}

close (IN);


# Determine X-bins max

my $roundup;

sub roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}

$max = $max / $stepsize;
$roundup = $stepsize* roundup($max);

#print "$roundup\n";

#__END__

my %res;

# for each bin, count up how many transcripts are in that bin

for (my $start = 0; $start < $roundup; $start += $stepsize ) {
    #print "$start\t$roundup\n";
    foreach my $key (keys %fas ) {
        #print "key $fas{$key}\n";
        if ( $fas{$key} >= $start and $fas{$key} < ($start+$stepsize) ) {
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
    #print  "$key2\t$res{$key2}\n";

}
close (OUT);

#__END__

#my ($ymax, $yticks) = scale($max,100);

#$opt{y_max_value}   = $max + 100;          # Fixed
#$opt{y_tick_number} = 10;
#plot(\%opt, \@data, 'hb');


#print "$max\t$roundup\n";
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
        histogram_bins => $max,
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





