#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >3 ) {
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




__END__




	open (IN, "<$in") || die "I can't open $in\n";
	my @in = <IN>;
	close (IN);

	open (IN2, "<$in2") || die "I can't open $in2\n";
	my @in2 = <IN2>;
	close (IN2);

	open (OUT, ">$out") || die "I can't open $out\n";

my %h1;
my %h2;
$int1--;
$int2--;


#Load the data into hashes 
my $fields1=0;
my $fields2=0;


foreach my $line (@in) {
    chomp $line;
    if  ($line =~m/\w/){
    my @arr = split (/\t/, $line);
    my $key = $arr[$int1];
    $key=~s/ //g;
    splice(@arr, $int1, 1);
    my $new_line =join("\t", @arr);
    unless ($fields1 > scalar(@arr)) {
    $fields1 = scalar(@arr);
    }
    push(@{ $h1{$key}}, $new_line);
#    print "H1:$key:$new_line:\n";
#        print "Fields1:$fields1:\n";    
    }
}


foreach my $line (@in2) {
    chomp $line;
    if  ($line =~m/\w/){
    my @arr = split (/\t/, $line);
    my $key = $arr[$int2];
    $key=~s/ //g;
    splice(@arr, $int2, 1);
    my $new_line =join("\t", @arr);
    unless ($fields1 > scalar(@arr)) {
#        $fields2 = scalar(@arr);
    }
#    $h2{$key}= $new_line;3
    push(@{ $h2{$key}}, $new_line);
#    print "H2:$key:$new_line:\n";
#        print "Fields2:$fields2:\n";  
    }
}

############# Make all fields equal length ##################################

# Make fields



foreach my $key (keys %h1) {
    if ($key =~m/\w/){
        foreach my $elem (@{$h1{$key}}){
            my @arr = split(/\t/,$elem);
                while (scalar(@arr) < $fields1) {
#                print OUT "$key\t@{$h1{$key}}[$i]\n";
                    push (@arr, " ");   
                }
            my $new_elem = join("\t", @arr);
#            $new_elem = "$new_elem\tNEW"; 
            $elem =  $new_elem;

        }
    }
}

foreach my $key (keys %h2) {
    if ($key =~m/\w/){
        foreach my $elem (@{$h2{$key}}){
            my @arr = split(/\t/,$elem);
                while (scalar(@arr) < $fields2) {
#                print OUT "$key\t@{$h1{$key}}[$i]\n";
                    push (@arr, "\t");   
                }
            my $new_elem = join("\t", @arr);
             $new_elem =  $new_elem . "\t";
#            $new_elem = "$new_elem\tNEW"; 
            $elem =  $new_elem;
        }
    }
}

$fields1--;
$fields2--;
#print "$fields1\t$fields2\n";
my $fill1= "\t" x $fields1;
my $fill2= "\t" x $fields2;
#print "$fill1\t$fill2\n";
#
#############################################
#
## Empty the data from hashes


# Keys in common

foreach my $key (keys %h1) {
    if ($key =~m/\w/){
#    print "KEY:$key:\n";
#    foreach my $key2 (keys %h2){ 
        if (exists $h2{$key}) {
            my $i =0;
            foreach my $elem (@{$h1{$key}}){
#                foreach my $elem2 (@{$h2{$key}}){
                    print OUT "$key\t@{$h1{$key}}[$i]\t@{$h2{$key}}\n";
#                }
                $i++;
            }
            delete $h1{$key};
            delete $h2{$key};
        }

# Keys only in hash 1

        else {
            my $i =0;
            foreach my $elem (@{$h1{$key}}){
                print "$key doesnt exist in file 2\n";
                unless ($mode == 3) {
                    print OUT "$key\t@{$h1{$key}}[$i]\t$fill2\n";
                }
                $i++;
            }
            delete $h1{$key};
            delete $h2{$key};

        }
#    }
    }

}



# Keys only in hash 2
if ($mode=~/2/ ) {
foreach my $key (keys %h2) {
    if ($key =~m/\w/){
    print "KEY:$key:\n";
#    foreach my $key2 (keys %h2){ 
        if (exists $h2{$key}) {
            my $i =0;
            foreach my $elem (@{$h2{$key}}){
#                foreach my $elem2 (@{$h2{$key}}){
                    print "$key doesnt exist in file 1\n";
                    print OUT "$key\t$fill1\t@{$h2{$key}}\n";
#                }
                $i++;
            }
            delete $h2{$key};
        }

    }
}
}

close (OUT);


#####
#
=pod

my found = 0;
foreach my $key1 (keys %hash1) {
foreach my $key2 (keys %hash2) {
if ($hash1{$key1} eq $hash2{$key2})

{
$found=1;
}
}
if (!$found)
{
push @missing, $hash1{$key1}
}
else
{
$found=0;
}


# or

my %reversed_hash2 = reverse %hash2;
my @missing = grep ! exists $reversed_hash2{ $_ }, values %hash1;

