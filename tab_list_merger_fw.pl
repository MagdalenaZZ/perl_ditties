#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >3 ) {
        &USAGE;
}


sub USAGE {

die 'Usage: tab_list_merger.pl <field to merge on> output_file.txt  *.files

Takes  tab-delimited files and merges them on any common field, leaving a blank space if no match is done



'
}


my $tab = shift;
my $out = shift;
my @in = @ARGV;
my $in = join("\t", @in);


# read in all files and get all categories to merge on

my @sys = `cat $in | cut -f$tab | sort | uniq `;

$tab = $tab-1;

#print "@sys\n";

my %h;


foreach my $line (@sys) {
    chomp $line;
    #print "$line\n";
    

    # save master
    if ($line=~/\w+/) {
        $h{$line}=1;
    }
}


my $i = 0;

my %res;


# find the longest tab-number
my $tablen = 0;


foreach my $file (@in) {
    #print "$file\n";

    open (IN, "<$file") || die "I can't open $file\n";
	my @input = <IN>;


    foreach my $ele (@input) {
        chomp $ele;

        my @ar = split(/\t/, $ele);
        my $len = scalar(@ar);
        if ($len > $tablen) {
            $tablen = $len;
            #print "$len\t$tablen\n";
        }
    }
}



foreach my $file (@in) {
    #print "$file\n";

    open (IN, "<$file") || die "I can't open $file\n";
	my @input = <IN>;
    close (IN);

    my $var;

    foreach my $ele (@input) {
        chomp $ele;
        my @arr = split(/\t/, $ele);
        
        # check if @arr is long enough
        


        $var = $arr[$tab];
        if (exists $h{$var}) {
            #print "$arr[$tab]\n";
            push (@{$res{$var}}, "\|$ele" );
        }
        else {
            print "Warning! Doesnt exist $arr[$tab]\n";

        }

    $i++;
    #print  scalar(keys %res) . " " .  scalar( @{$res{$var}} ) . " $i " . "\n";

    }

    $i=0;
 
}



foreach my $key (keys %res) {

    print "$key\t";

    my @arr = @{$res{$key}};

    foreach my $el (@arr) {
        print "$el\t";
    }

    print "\n";
}


exit;


__END__



