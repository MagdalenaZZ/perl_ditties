#!/usr/local/bin/perl -w

# 

use strict;

unless (@ARGV > 0) {
        &USAGE;
}

sub USAGE {

die '


Usage: pairwise_all.fas

Takes one fasta-file, and then does pairwise alignments of all the sequences within it.

'
}


my $dom1 = shift;
#my $dom2 = shift;


# read all fastas to a hash
	open (IN, "<$dom1") || die "I can't open $dom1\n";
#	my @doms = <IN>;
#
my %h;

    while (<IN>) {
        chomp $_;
        if ($_ =~/^>/) {
            my $head = $_;
            $head =~s/.1..pep//;
            $head =~s/.2..pep//;
            $head =~s/.3..pep//;
            $head =~s/>//;
            my $seq = <IN>;
            chomp $seq;
            if ($head =~/\w+/ and $seq =~/\w+/) {
                $h{$head} = $seq;
            }
        }
    }

close (IN);

my %alns;

foreach my $gene1 (keys %h){ 
    foreach my $gene2 (keys %h) {

        my @arr = sort {$a cmp $b} ( $gene1, $gene2 ) ;

        # check if it exists
        my $aa = $arr[0];
        my $bb = $arr[1];

#        print "$aa\t$bb\n";

        if ($bb =~/\Q$aa\E/ and $aa =~/\Q$bb\E/ ) {
            # same ignore
        }
        elsif ( exists $alns{$aa}{$bb} ) {
            # exists do nothing
        }

        else {

        open (A, ">A.seq") || die "I can't open A.seq\n";
        open (B, ">B.seq") || die "I can't open B.seq\n";

         print A ">$arr[0]\n$h{$arr[0]}\n";
         print B ">$arr[1]\n$h{$arr[1]}\n";
#        print A "$gene1\n$h{$gene1}\n";
#        print B "$gene2\n$h{$gene2}\n";

        system "stretcher -asequence A.seq -bsequence B.seq -outfile AB.aln";
        close (A);
        close (B);

        open (ALN, "<AB.aln") || die "I can't open AB.aln\n";
            my $ax;
            my $bx;
            my $score;

           while (<ALN>) {
               chomp $_;
               if ($_ =~/# 1: /) {
                    $ax = $_;
                    $ax =~s/# 1://;
                    $ax =~s/ //g;
#                   print "$ax\n";
               }
               elsif ($_ =~/# 2: / ) {
                   $bx = $_ ;
  
                    $bx =~s/# 2://;
                    $bx =~s/ //g;
#                    print "$bx\n";
               }
               elsif ($_ =~/# Identity:/) {
                   $score= $_;
#                   print "$score\n";

               }
           }
        close (ALN);
        system "rm -f AB.aln";
        $alns{$ax}{$bx}= $score;

        }
    }

}

system "rm -f A.seq B.seq";

# print out
open (OUT, ">$dom1.sim") || die "I can't open $dom1.sim\n";

foreach my $gen1 (sort keys %alns) {
    foreach my $gen2 (sort keys %{$alns{$gen1}} ) {
        print OUT "$gen1\t$gen2\t$alns{$gen1}{$gen2}\n";
    }
}





