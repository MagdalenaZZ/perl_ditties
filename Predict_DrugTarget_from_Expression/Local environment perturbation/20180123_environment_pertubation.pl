#!/usr/bin/perl



use strict;

#Create interact and phopho hashes
my %interact=();
my %phospho=();

#Read in file of interactions and phospho data
my $int=shift;
my $phos=shift;


open (I,$int);
while (<I>){
  if (/(\S+)\s+interacts\s+(\S+)/){
    my $p1=$1;
    my $p2=$2;
    next if ($p1 eq $p2);
    $p1=~tr/a-z/A-Z/;
    $p2=~tr/a-z/A-Z/;
    $interact{$p1}{$p2}=1;
    $interact{$p2}{$p1}=1;

  }
}
close I;


open (P,$phos);
while(<P>){
  next if (/Prot/);
  if (/(\S+)\s+(\S+)/){
    my $p=$1;
    my $val=$2;
    $p=~tr/a-z/A-Z/;
    $phospho{$p}=$val;
  }
}
close P;

my ($max) = sort { $b <=> $a } values %phospho;

my ($min) = sort { $a <=> $b } values %phospho;

my $range = $max-$min;





print "Prot\tlocalEnvPertub\n";
#for every protein in interaction file
foreach my $p1 (keys %interact){
  my $newval=0;
  $newval+=(abs($phospho{$p1}));
  print STDERR "$p1=$newval  ";

  foreach my $p2 (keys %{$interact{$p1}}){
    $newval=$newval+(abs($phospho{$p2}));
    print STDERR "$p2=$phospho{$p2} ->$newval  ";
  }
  my $norm_newval=$newval/$range;
      print  "Original $p1=$phospho{$p1}\t\t Range $range\t\t FINAL $p1 raw\t\t $newval\t\t\t\t Normalised value $p1 \t$norm_newval\n";

}
