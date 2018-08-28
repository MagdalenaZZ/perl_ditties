#!/usr/local/bin/perl -w

use strict;

unless (@ARGV >0) {
        &USAGE;
}


sub USAGE {

die 'Usage: calculate_RPKM.pl gene-lengths readcounts


Gene-lengths:   gene-name<TAB>length
readcounts: list or table

'
}


my $gl = shift;
my $file = shift;


open (GL, "< $gl")  || die "I can't open $gl\n";
open (IN, "< $file")  || die "I can't open $file\n";
open (OUT2, "> $file.RPKM")  || die "I can't open $file.RPKM\n";


# Read in gene lengths

my %gls;

while(<GL>){
	chomp;
	my($gene,$len)=split(/\t/,$_);
	$gls{$gene}=$len;
}

#my $C = `awk '{sum+=\$3} END{print sum}'  $file `;
#print "$C\n";
#
#

my @in=<IN>;
my $ids=shift(@in);

print OUT2 "$ids";
my @sums=split(/\s+/,$ids);

foreach my $ele (@sums) {
		$ele=0;
	}
my $no = shift(@sums);

#print scalar(@sums) . "\n";
#print "@sums\n";

# calculate sums
foreach my $el (@in) {
    	chomp $el;
	#print "$el\n";
	my @a=split(/\t/,$el);
	my $i=1;
	foreach my $ele (@sums) {
		if ($a[$i]=~/\d+/) {
			$ele=$ele+$a[$i];
			#print "Is num $a[$i]\n";
		}
		else {
			#print "No num $a[$i]\n";
		}
		$i++;	
		#print "$ele\t";
	}
	#print "\n";
}

print "@sums\n";


##__END__


# calculate the RPKM value

# go through each row
foreach my $el (@in) {
    chomp $el;
    my @arr= split(/\t/, $el);

	my $id=shift(@arr);

	my $i=0;
	#my $gene= shift(@arr);
	print OUT2 "$id\t";
	foreach my $val (@arr) {
		if ($val>0) {
			#print "Y $val\t$i\t$sums[$i]\t$id\t$gls{$id}\n";
	        	my $rp = (1000000000  * $val );
	        	my $km = ( $sums[$i]  * $gls{$id}  );
	        	my $rpkm = ( $rp/ $km) ;	
			print OUT2 "$rpkm\t";
		}	
		else {
			#print "N $val\t$i\t$sums[$i]\t$id\t$gls{$id}\n";	
			print OUT2 "0\t";	
}
		$i++;
		
	}
	print OUT2 "\n";
=pod
    if ($arr[2] > 0 and $arr[1] > 0  ) {
        my $rp = (1000000000  * $arr[2] );
        my $km = ( $C  * $arr[1]  );
        my $rpkm = ( $rp/ $km) ;
        print OUT2 "$arr[0]\t$arr[1]\t$arr[2]\t$rpkm\n";
	print "$arr[0]\t$rpkm\n";
    }
    else {
        print OUT2 "$arr[0]\t$arr[1]\t0\t0\n";
    }
=cut

}

exit;






