#!/usr/bin/perl -w

use strict;

unless (@ARGV == 3) {
        &USAGE;
}


sub USAGE {

    die '


Usage: probe_to_gene.pl file.chip expression_data <log n/2/10>

Takes a file with expression_data, and gets the avergages for probes to genes

If log2-values, fix before merging


' . "\n";
}


my $chip = shift;
my $in = shift;
my $log2 = shift;


open (CHIP, "<$chip")|| die;

my %chip;

# 
while (<CHIP>) {
chomp;
    if ($_=~/^\!/) {
        # header
        #print "Header $_\n";
    }
    elsif (($_=~/---/)) {
        #print "$_\n";
    }
    else {
        my @arr = split(/\t/, $_);
        $chip{$arr[0]}{"$arr[1]"}=1;
        #print "$arr[0]\t$arr[1]\n";
        #print "Not Header $_\n";

    }
}



open (IN, "<$in")|| die;

my @chip = split(/\//,$chip);
open (OUT, ">$in.$chip[-1].$log2.pergene.rnk")|| die;



my %data;

while(<IN>) {
chomp;


    if($_!~/\w+/) {
        #nothing
    }
    elsif ($_=~/^ID/) {
        $_=~s/\"//g;
        print OUT "$_\n";
        print "ID line found $_\n";

    }
	elsif ($_=~/NA/) {
	# do nothing	
}

    else {
        my @a = split(/\t/, $_);
        $a[0]=~s/\"//g;

        if (exists $chip{$a[0]}) {
            #print "Exists $a[0] \n";

            # Save in new hash
            my $probe = shift(@a);


            #my @genes;
            foreach my $key (sort keys %{$chip{$probe}} ) {
                #print "$key\n";
                #foreach my $key2 (keys %{$chip{$key}} ) {
                my $gene = $key;
                $gene =~s/ //g;
                $gene =~s/\/\/\///g;
                my $line = join("\t", @a); 
                #print "$gene\t$probe\t$line\n";
                $data{$gene}{$probe}="$line";
            }
            
        }
        else {
            #print "Not exists $a[0] \n";
        }
    }

}


if ($log2=~/n/) {
                    print "Your values are  NOT log transformed\n";
}
else {
                    print "Your values are log $log2 transformed\n";
}



# get the average of the gene probe value

foreach my $gene (sort keys %data) {
    
    my $num = scalar keys  %{$data{$gene}};

    if ($num < 2 ) {
        foreach my $probe (sort keys %{$data{$gene}}) {
            print OUT "$gene\t$data{$gene}{$probe}\n";
        }
    }

    # or if the same gene has several probes 
    else {
    
        # make an array to hold the added values
        my $val=0;
	my @vals;

        #my $newval;

        foreach my $probe (sort keys %{$data{$gene}}) {


		#print "Probe $probe\t$data{$gene}{$probe}\n";
		my $elem=$data{$gene}{$probe};

		# un-log if not normal
 		if ($log2!~/n/) {
		    #print "Before $elem\n";
                    #my $log2 = log($num)/log(2);
		    # Element is delogged
                    $elem = $log2**($elem);
		    #print "After $elem\n";
		    # Element is divided
		    $elem = $elem / $num; 
		    $val=$val+$elem;
		    push (@vals, $elem);
                }
		# or leave as it is
		else {
			$elem = $elem / $num; 
		    	$val=$val+$elem;
		}
	}

	# Log it back again
	if  ($log2!~/n/) {
		$val =log($val)/log($log2);
	}
	#print OUT "$gene\t$val\t", "@vals". "\n";
	print OUT "$gene\t$val\n";
     }
}
    




exit;


__END__

=pod
		#my @a = split(/\t/, $data{$gene}{$probe});
            
            my $i=0;
            foreach my $elem (@a) {


                # Transform log2 values to normal
                if ($log2!~/n/) {
		    #print "Before $elem\n";
                    #my $log2 = log($num)/log(2);
                    $elem = $log2**($elem);
		    #print "After $elem\n";
                }


                if (exists $vals[$i]) {
                    #print "$gene First $a[$i]\n";
                    $vals[$i]=$vals[$i]+ $elem;
                    #print "$gene Then $a[$i]\n";
                }
                else {
                    $vals[$i]=$elem;
                }
                $i++;
            }
            #print "$gene\t$data{$gene}{$probe}\n";

        }
        # now do average of all values

        print OUT "$gene\t";
        print "VALS  " . "@vals\n";
            foreach my $elem (@vals) {
                $elem = $elem / $num; 
                # if log transformed, transform back now
                if ($log2 !~/n/) {
                    #print "Before $elem\n";
                    $elem = log($elem)/log($log2);
                    #my $elem = 2**($elem);
                    #print "After $elem\n";
                }
            }

        my $newvals =  join("\t", @vals);
        print "$newvals\n";
        #print "\n";
=cut


