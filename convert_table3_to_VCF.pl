#!/usr/local/bin/perl -w

use strict;

unless (@ARGV>=1) {
        &USAGE;
}


sub USAGE {

die 'Usage: convert_table3_to_VCF.pl infile header.file genome.fa



'
}

my $in = shift;
my $genome = shift;
open (IN, "<$in ") || die "I can't open $in\n";
open (ERR, ">ERR.vcf") || die "I can't open ERR.vcf\n";


my %seen;

while (<IN>) {
	chomp;
	my $ele=$_;

	if ($_=~/^#/) {
		print OUT "$ele";
	}
	elsif($_=/^MutationID/) {
		print "Header: $ele\n";
	}
	else {
		chomp $_;
		my @arr = split(/\t/, $ele);
		#print "$arr[14]\n";
		my @spec=split(/\;/,$arr[14]);
	

		foreach my $elem (@spec) {
			my ($prefix,$call)=split(/\:/, $elem);
			
			# calculate frequency and pass
			my ($alt,$tot)=split(/\//,$call);
			my $freq = $alt/$tot;
			my $status="FAIL";
			my $href=0;
			my $halt=0;

			# Change chromosome names
			$arr[2]=~s/23/X/;
			$arr[2]=~s/24/Y/;
			# Fix delimiters
			$arr[7]=~s/\;/\,/;
			$arr[8]=~s/\;/\,/;



			# Remove fields where reference sequenc is a gap!
			if ($arr[5]=~/-/) {
				print ERR "$arr[2]\t$arr[3]\t.\t$arr[5]\t$arr[6]\t.\tREMOVED\tDP=$tot;ALT=$alt;CSQR=1|$arr[7]|ENSXXXX|$arr[8];ID=$arr[0];ITHState=$arr[13];EFF=$arr[9]\tGT:DP:FQ:QU\t$href/$halt:$tot:$freq:$status\t$arr[1]\_$prefix\n";
				open (TMP, ">$in.$arr[1]\_$prefix.tmp.bed") || die "I can't open $in.$arr[1]\_$prefix.tmp.bed\n";
				my $end=$arr[3]+1;
				my $start = $arr[3] -1;
				print TMP "$arr[2]\t$start\t$end\n";
				close(TMP);
				my $base = `bedtools getfasta -fi ~/human_g1k_v37_decoy.fasta -bed $in.$arr[1]\_$prefix.tmp.bed | tail -1 `;
				system ("rm $in.$arr[1]\_$prefix.tmp.bed");
				#my @base= split(/\n/, $base);
				my $new_alt=substr ($base, 0, 1);
				chomp($base);
				$new_alt=~s/\t//g;
				#print "$arr[2]\t$arr[3]\t$arr[5]\t$arr[6]\t$start\t$base\t$new_alt\n";
				$arr[3]=$start;
				$arr[5]=$base;
				$arr[6]=substr ($base, 0, 1);
				$arr[8]="FIX1";
				#next;
			}


			# Change alternatives with gaps which have gaps
			if ($arr[6]=~/\-/) {
				my $old_ref=$arr[5];
				my $old_alt= $arr[6];
				$arr[6]=~s/\-//;
				my $new_ref= $arr[5] . $arr[6];
				my $new_alt=$arr[5];
				my $start = $arr[3] -1;
				#print "$arr[2]\t$arr[3]\t$old_ref\t$old_alt\t$new_ref\t$new_alt\n";
				$arr[3]=$start;
				$arr[5]=$new_ref;
				$arr[6]=$new_alt;
				$arr[8]="FIX2";
			}

			# No whitespace in info fields
			$arr[7]=~s/\s+/\_/g;
			$arr[8]=~s/\s+/\_/g;
			$arr[0]=~s/\s+/\_/g;
			$arr[13]=~s/\s+/\_/g;
			$arr[9]=~s/\s+/\_/g;




			# Fail samples where alternative <10%
			if ($alt/$tot > 0.1) {
				$status="PASS";
			}
			if ($alt>1){
				$halt=1;
			}
			else {
				$status="PASS";
			}
			# Create a header in the file if it doesnt have one
			unless (exists $seen{"$arr[1].$prefix"}) {
				# system `cat $head > $arr[1].$prefix.vcf ` ;
				open (OUT, ">$arr[1]\_$prefix.vcf") || die "I can't open $arr[1].$prefix.vcf\n";
				print OUT "##fileformat=VCFv4.1\n";
				print OUT "##FILTER=<ID=PASS,Description=\"All filters passed\">\n";
				print OUT "##FILTER=<ID=FAIL,Description=\"Alternative allele less than 10% frequency\">\n";
				print OUT "##contig=<ID=1,length=249250621>\n";
				print OUT "##contig=<ID=2,length=243199373>\n";
				print OUT "##contig=<ID=3,length=198022430>\n";
				print OUT "##contig=<ID=4,length=191154276>\n";
				print OUT "##contig=<ID=5,length=180915260>\n";
				print OUT "##contig=<ID=6,length=171115067>\n";
				print OUT "##contig=<ID=7,length=159138663>\n";
				print OUT "##contig=<ID=8,length=146364022>\n";
				print OUT "##contig=<ID=9,length=141213431>\n";
				print OUT "##contig=<ID=10,length=135534747>\n";
				print OUT "##contig=<ID=11,length=135006516>\n";
				print OUT "##contig=<ID=12,length=133851895>\n";
				print OUT "##contig=<ID=13,length=115169878>\n";
				print OUT "##contig=<ID=14,length=107349540>\n";
				print OUT "##contig=<ID=15,length=102531392>\n";
				print OUT "##contig=<ID=16,length=90354753>\n";
				print OUT "##contig=<ID=17,length=81195210>\n";
				print OUT "##contig=<ID=18,length=78077248>\n";
				print OUT "##contig=<ID=19,length=59128983>\n";
				print OUT "##contig=<ID=20,length=63025520>\n";
				print OUT "##contig=<ID=21,length=48129895>\n";
				print OUT "##contig=<ID=22,length=51304566>\n";
				print OUT "##contig=<ID=X,length=155270560>\n";
				print OUT "##contig=<ID=Y,length=59373566>\n";
				print OUT "##contig=<ID=MT,length=16569>\n";
				print OUT "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total read depth all samples\">\n";
				print OUT "##INFO=<ID=ALT,Number=1,Type=Integer,Description=\"Read depth of alternative allele\">\n";
				print OUT "##INFO=<ID=CSQR,Number=1,Type=String,Description=\"Hugo_Symbol,fake EnsemblID, annotation from Annovar; intergenic/exonic function of variant\">\n";
				print OUT "##INFO=<ID=ID,Number=1,Type=String,Description=\"Mutation ID from TRACERx\">\n";
				print OUT "##INFO=<ID=ITHState,Number=1,Type=Integer,Description=\"1: Variant ubiquitous in all regions; 2: Variant is heterogeneous, but found in multiple regions; 3: Variant is heterogeneous, only found in one region\">\n";
				print OUT "##INFO=<ID=EFF,Number=1,Type=String,Description=\"Exonic annotation from Annovar\">\n";
				print OUT "##INFO=<ID=FREQ,Number=1,Type=Float,Description=\"Frequency alternative/total\">\n";
				print OUT "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n";
				print OUT "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Total read depth\">\n";
				print OUT "##FORMAT=<ID=FQ,Number=.,Type=String,Description=\"Frequency of alternative allele\">\n";
				print OUT "##FORMAT=<ID=QU,Number=.,Type=String,Description=Quality>\n";

				print OUT "#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	$arr[1]\_$prefix\n";
				close (OUT);
				$seen{"$arr[1].$prefix"}=1;
			}
			open (OUT, ">>$arr[1]\_$prefix.vcf") || die "I can't open $arr[1].$prefix.vcf\n";
			print OUT "$arr[2]\t$arr[3]\t.\t$arr[5]\t$arr[6]\t.\t$status\tDP=$tot;ALT=$alt;CSQR=1|$arr[7]|ENSXXXX|$arr[8];ID=$arr[0];ITHState=$arr[13];EFF=$arr[9]\tGT:DP:FQ:QU\t$href/$halt:$tot:$freq:$status\n";
			close(OUT);
		}
		

	}
}



__END__

cat TableS3.sing.pos |  awk -F'\t' '{print "chr"$3"\t"$4"\t\.\t"$6"\t"$7"\t\.\tPASS\t"}' > TableS3.sing.pos.vcf
cat TableS3.sing.pos |  awk -F'\t' '{print "SOMATIC;CSQR=1|"$8"|ENSXXXX|"$9";ID="$1}' >> TableS3.sing.pos.vcf
cat TableS3.sing.pos |  awk -F'\t' '{print "SOMATIC;CSQR=1|"$8"|ENSXXXX|"$9";ID="$1"\tDP:FDP:SDP:SUBDP:AU:CU:GU:TU\t"}' >> TableS3.sing.pos.vcf
cat TableS3.sing.pos |  awk -F'\t' '{print "SOMATIC;CSQR=1|"$8"|ENSXXXX|"$9";ID="$1";ITHState="$14"\tDP:FDP:SDP:SUBDP:AU:CU:GU:TU\t"}' >> TableS3.sing.pos.vcf



