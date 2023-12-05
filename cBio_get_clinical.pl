#!/usr/local/bin/perl -w

use strict;

unless (@ARGV <3) {
        &USAGE;
}


sub USAGE {

die 'Usage: cBio_get_clinical.pl 


'
}



# Get a list of all studies

#system "curl \"http://www.cbioportal.org/webservice.do?cmd=getCancerStudies\" > cBio.all.studies";


open (IN, "< cBio.all.studies") || die "Cannot find file cBio.all.studies\n";


my @studies;

while (<IN>) {


my @arr = split(/\s+/, $_);

my $allpat = "$arr[0]" . "_all";

push (@studies, $allpat);

#system "curl \"http://www.cbioportal.org/webservice.do?cmd=getClinicalData&case_set_id=$allpat\" > $allpat.clinical\n";


#http://www.cbioportal.org/webservice.do?cmd=getClinicalData&case_set_id=ov_tcga_all
#http://www.cbioportal.org/webservice.do?cmd=getClinicalData&case_set_id=cscc_dfarber_2015_all

}

close (IN);


# Go through the data.clinical files
# save it as a hash
#



my %h;

foreach my $file (@studies) {

	if ( -e  "$file.clinical") {
		open (IN, "<$file.clinical") || die "Cannot find $file.clinical\n";

		my $header = <IN>;
		chomp $header;

		#print "HEADER:$header:\n";
	      my @head = split(/\t/, $header); 
	
	       # Go through the file, and pick out all values associated with particular values
		while (<IN>) {
			chomp;
			#print "$_\n";
			my @arr= split(/\t/, $_);
			my $i=0;


			foreach my $elem (@head) {
				if (defined($arr[$i])) {
					#print ":$file\t$elem\t$arr[0]\t$arr[$i]:\n";
					$h{$elem}{$file}{$arr[0]}=$arr[$i];
				}
				$i++;
			}


		
		}

	}
	else {
		#print "Missing file $file.clinical\n";
	}

}



# and pick out patients under the age of 19
my $age = "AGE";

my %old;

foreach my $study (keys $h{$age}) {

	my $study_id=$study;
	my $total_pat_with_age=0;
	my $total_pat_les_20=0;
	my $max=0;
	my $min=10000;

	#print "$cat\t$study\t$h{$cat}{$study}\n";
	foreach my $patient (keys $h{$age}{$study}) {

		my $ages = $h{$age}{$study}{$patient};
		if ($ages=~/\d+/) {
			#print "$age\t$study\t$patient\t$h{$age}{$study}{$patient}\n";
			$total_pat_with_age++;



			if ($ages=~/-/) {
				#print "$age\t$study\t$patient\t$h{$age}{$study}{$patient}\n";
			}
			else {
				if ($ages>$max) {$max=$ages;}
				if ($ages<$min) {$min=$ages;}

				if  ($ages<20) {
					#print "$age\t$study\t$patient\t$h{$age}{$study}{$patient}\n";
					$total_pat_les_20++;
				}
			}
		}
		else {
			#print "ELSE\t$ages\n";
		}

	}

	print "$study_id\t$total_pat_with_age\t$total_pat_les_20\t$max\t$min\n";
}


__END__



#my $var=scalar keys %{$gene{$root}};
# Total number of categories recorded
my $hash_count1 = scalar keys %h;
#print "1 $hash_count1\n";
#SF#print "StudyFrequency\tCategory\n";

foreach my $cat (keys %h) {

		my $hash_count2 = scalar keys %{$h{$cat}};
		#SF#print "$hash_count2\t$cat\n";

	foreach my $study (keys $h{$cat}) {

		#print "$cat\t$study\t$h{$cat}{$study}\n";
		foreach my $patient (keys $h{$cat}{$study}) {

			#print "$cat\t$study\t$patient\t$h{$cat}{$study}{$patient}\n";

		}
	}

}




exit;
