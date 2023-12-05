#!/usr/local/bin/perl -w

use strict;


unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die 'Usage: table_sum_down.pl merged.tab  (optional: read lengths)


Sums up values with identical headers, outputs a file with all the sums


Read lengths file:

Gene1   Length1
Gene2   546
Gene3   1034
Gen..   ...

Gene is the same order as in  merged.tab


'
}



my $data = shift;


open(DATA, "<$data") or die "Cant find file $data\n  $!";
open(SH, ">$data.sh") or die "Cant find file $data.sh\n  $!";

chomp(my $head = <DATA>);
#print "$head\n";

my @arr1 = split(/\t/,$head);

my $col = scalar(@arr1);

#print "$col\n";


### determine which should be merged


my %seen;

my $index = 1;

foreach my $elem (@arr1) {
    if (exists $seen{$elem}) {
        #push (@{$seen{$elem}} , $index);
        $seen{$elem}{$index}=  1;
        
    }
    else {
        $seen{$elem}{$index} =  1;
    }
    $index ++;
}


use Data::Dumper;
#print Dumper(%seen);


my %res;

my @res;
my @files;

foreach my $key (sort keys %seen ) {

  
    my $res = "cat $data | cut -f";

    foreach my $key2 ( keys %{$seen{$key}} ) {
        $res = $res . "$key2,";
        #print " cols=(\$(sed '1!d;s/\\t/\\n/g' $data | grep -w -n $key | sed 's/:.*\$//')) \n ";
        #print "cut  -f 1\$(printf \",\%s\" \"\${cols[@]}\") $data > $data.$key.dat \n";
    }

    $res =~s/,$//;
    $res = $res . " > $data.$key.dat ";

    push (@res, $res);
    my $res2 = "awk \'{sum=0\; for(i=1\; i\<=NF; i++){sum+=\$i}\; print sum}\' $data.$key.dat  > $data.$key.dat2 ";
    push (@res, $res2);

    unless ($key=~/^ID$/) {
        push(@files, "$data.$key.dat2");
    }
}

foreach my $ele (@res) {
    print SH "$ele \n";
}

system "bash $data.sh";



if (scalar(@ARGV)>0) {




    # reading in lengths
    print "Reading file $ARGV[0]\n";
    open(IN, "<$ARGV[0]") or die "Cant find file $ARGV[0]\n  $!";
    my @in = <IN>;
    my $tmp = shift @in;
    chomp @in;


    foreach my $file (@files) {

        open(IN2, "<$file") or die "Cant find file $file\n  $!";
        my @temp = split(/\./, $file);
        open(OUT2, ">$temp[-2].$temp[-1].rpkm") or die "Cant print file $temp[-2].$temp[-1].rpkm\n  $!";
        print OUT2 "gene_id\tlength\treads\tRPKM\n";
        my @in2 = <IN2>;
        my $tmp2 = shift @in2;


        # calculate the RPKM value

        ## total number of reads
        my $C = `awk '{sum+=\$1} END{print sum}' $file`;
        print "$file\t$C\n";


        my $i = 0;

        foreach my $el (@in2){
            chomp $el;
            #print ":$el:\t:$in[$i]:\n";
            my @arr = split(/\t/, $in[$i]);

            if ($el > 0 and $arr[1] > 0  ) {
                my $rp = (1000000000  * $el );
                my $km = ( $C  * $arr[1]  );
                my $rpkm = ( $rp/ $km) ;
                print OUT2 "$arr[0]\t$arr[1]\t$el\t$rpkm\n";
            }
            else {
                print OUT2 "$arr[0]\t$arr[1]\t0\t0\n";
            }




        $i++;    
        }




    }

}


else {


    my @data = <DATA>;

    foreach my $file (@files) {

        open(IN2, "<$file") or die "Cant find file $file\n  $!";
        my @temp = split(/\./, $file);
        open(OUT2, ">$temp[-2].$temp[-1].reads") or die "Cant print file $temp[-2].$temp[-1].reads\n  $!";
        #print OUT2 "gene_id\treads\treads\treads\n";
        my @in2 = <IN2>;
        my $tmp2 = shift @in2;

        # calculate the RPKM value
        ## total number of reads
        my $C = `awk '{sum+=\$1} END{print sum}' $file`;
        print "File:\t$file\t$C\n";


        my $i = 0;

        # now print transposed
        foreach my $el (@in2){


            # get the row header
            my @heads = split(/\t/,$data[$i]);


            chomp $el;
            #print ":$el:\t:$in2[$i]:\t:$heads[0]:\n";
            my @arr = split(/\t/, $in2[$i]);

            #if ($el > 0 and $arr[1] > 0  ) {

                #my $rp = (1000000000  * $el );
                #my $km = ( $C  * $arr[1]  );
                #my $rpkm = ( $rp/ $km) ;
                #print OUT2 "$arr[0]\t$arr[1]\t$el\t$rpkm\n";
                #}
            #else {
            
            #print OUT2 "$el\t\n";
            print OUT2  "$heads[0]\t$el\t$el\t$el\n"; 

                #}
        $i++;    
        }




    }


system "perl ~/bin/perl/tab_merger_RPKM.pl merge *dat2.reads";
system "rm -f merge.merged.RPKM";

}


close(DATA);




__END__






while (<IN>) {
    chomp;
    my @arr= split(/\t/, $_);

    if ($arr[2] > 0 and $arr[1] > 0  ) {
        my $rp = (1000000000  * $arr[2] );
        my $km = ( $C  * $arr[1]  );
        my $rpkm = ( $rp/ $km) ;
        print OUT2 "$arr[0]\t$arr[1]\t$arr[2]\t$rpkm\n";
    }
    else {
        print OUT2 "$arr[0]\t$arr[1]\t0\t0\n";
    }
}




__END__



my %h;

$index = 1;

while (<DATA>) {

    my @arr = split(/\t/,$_);

    my $gene = shift @arr;


    print "$gene\n";

    foreach my $elem (@arr) {
        foreach my $ke ( %seen ) {
            if (exists $seen{$ke}{$index} ) {
                push( @{$h{$ke}{$index}}, $elem );
                print "$ke\t$index\t$elem\n";
            }
        }

    }

    $index++;

}




close DATA;



exit;
