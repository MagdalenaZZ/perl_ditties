#!/usr/local/bin/perl -w

use strict;

unless (@ARGV > 3 ) {
        &USAGE;
}


sub USAGE {

die 'Usage: tab_list_merger.pl <field to merge on> output_file.txt  *.files

Takes  tab-delimited files and merges them on any common field



'
}


my $tab = shift;
my $out = shift;
my @in = @ARGV;
my $in = join(" ", @in);


open (OUT, ">$out") || die "I can't open $out\n";

# read in all files and get all categories to merge on

my @sys = `cat $in | cut -f$tab | sort | uniq `;

$tab = $tab-1;

#print "@sys\n";
my %h;
my %res;



foreach my $line (@sys) {
    chomp $line;
    #print "$line\n";
    

    # save master
    if ($line=~/\w+/) {
        $h{$line}=1;
        push(@{$res{$line}}, "x");
    }
}


my $i = 1 ;




# find the longest tab-number
my $tablen = 0;
my %categories;

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

        # save the counting categories
        my $cat = $ar[$tab];
        $categories{$cat}=1;
    }
}

#print "Tablen $tablen\n";
#print "Tab $tab\n";

foreach my $key (sort keys %categories) {
    #print "Category :$key:\n";
}



#__END__

print OUT "ID\t";
#$tablen=2;

#my $i =1;

my $pad = "\tx" ;

# go through input again
foreach my $file (@in) {

# Make header
    my $new = "." x($tablen-1) ;
    $new=~s/\.\./\.\tx\t\./g;
    #$new=~s/\.\./\.\t\./g;
    print OUT "x\t$file\t";


    open (IN, "<$file") || die "I can't open $file\n";
	my @input = <IN>;
    close (IN);


	# Save the input in hash
	my %in;
	foreach my $line (@input) {
		if ($line=~/\w+/){
			chomp $line;
			my @a = split(/\t/,$line);
			$in{$a[$tab]}="$line";
			#print "Add $file\t$a[$tab]\n";
		}
	}	

	# Now compare the input with already known data

    foreach my $cate ( sort keys %categories ) {
		
	# if the element exists, fill
	if (exists $in{$cate}) {
		#print "It exists $file $cate\n";
		push (@{$res{$cate}}, "$in{$cate}" );
	}
	# otherwise pad
	else {
		#print "Not here :$cate:\n";
		push (@{$res{$cate}}, "$pad" );
		}
	}

}
    
print OUT "\n";


foreach my $key (sort keys %h) {

    print OUT "$key\t";
    my @arr = @{$res{$key}};

    foreach my $el (@arr) {
        print OUT "$el\t";
    }

    print OUT "\n";
}




__END__




