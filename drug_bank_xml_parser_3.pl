#!/usr/bin/perl -w


use strict;


if (@ARGV < 0) {
        &USAGE;
}


sub USAGE {

die 'Usage: drug_bank_xml_parser.pl   drugbank.xml

Takes the xml download from drugbank and parses it




What can possibly go wrong...  :-)



'
}

my $in = shift;


        open (IN, "<$in") || die "I can't open $in\n";
        #   	my @in= <IN>;
#    	close (IN);

my %h;

my $id;
my $head;
my $seq;

        while (<IN>) {
		chomp;
		$_=~s/\</\>/g;
		#print "$_\n";
		my @a= split(/>/,$_);

		if (scalar(@a)>2) {
			#print "@a\n";
			print ":$a[1]:\t:$a[2]:\n";

			# if it is the ID
			if ($a[1]=~/drugbank-id primary="true"/) {
				$id = $a[1];
			}
			else {
				$h{$id}{$a[1]}{$a[2]}=1;
			}
		}
		else {
			print "ELSE:$_\n";
		}


	}

__END__


        while (<IN>) {



            if ($_ =~/drugbank-id/ ) {
#                print "$_";
                my @arr = split(/[\<\>]/, $_);
                my @arr2 = split(/[\<\>]/, <IN>);
#                print "$arr[2]\n";
#                print "$arr2[2]\n";
                $h{ $arr[2] }{"Name"} = "$arr2[2]";
                $id = $arr[2] ;
                $h{ $id }{"Group"} = "0";


            }
            
            
            elsif ($_ =~/<description>/ ) {
                    chomp $_;
                    $_=~s/<description>//;
                    $_=~s/<\/description>//;
                    $_=~s/  / /g;
                    $_=~s/  / /g;
                    $_=~s/  / /g;
                    $_=~s/^ //;
                    $_=~s/ /_/g;


                    $h{ $id }{"Desc"} = "$_";

            }

            elsif ($_ =~/<group>/ ) {
#                print "$_";
                my @arr = split(/[\<\>]/, $_);
#                print "$arr[2]\n";
                $h{ $id }{"Group"} = "$arr[2]";
            }

            elsif ($_ =~/<header>/ ) {
                    chomp $_;
                    $_=~s/<header>//;
                    $_=~s/<\/header>//;
                    $_=~s/        //;
                    $_=~s/\|\|/\|/g;
                    $_=~s/\|\|/\|/g;
                    $_=~s/\|\|/\|/g;
                    $_=~s/\|\|/\|/g;

                    $head = $_; 

#                my @arr3 = split(/\n/, $_);
                $h{ $id }{"Target"}{"$head"}=1;
#                print "$head\n";

            }

            elsif ($_ =~/<chain>/ ) {
                    chomp $_;
                    $_=~s/<chain>//;
                    $_=~s/<\/chain>//;
                    $_=~s/        //;
#                     print "$_";
                $h{ $id }{"Seq"}{"$head\n$_"}=1;


                $head="";
            }
            elsif ($_ =~/references>#/ ) {
                chomp $_;
#                     print "$_\n";
#
#
                if ($_=~/medicine.iupui.edu/) {
                    $_ = "www.medicine.iupui.edu";
                    $h{ $id }{"Ref"}{"$_"}=1;
                }
                elsif ($_=~/www.inchem.org/) {
                    $_ = "www.inchem.org";
                    $h{ $id }{"Ref"}{"$_"}=1;
                }
                elsif ($_=~/imgt.cines.fr/) {
                    $_ = "www.imgt.cines.fr";
                    $h{ $id }{"Ref"}{"$_"}=1;
                }


                elsif ($_=~/www\.ncbi\.nlm\.nih\.gov\/pubmed\//) {

                    my @arr5 = split(/www\.ncbi\.nlm\.nih\.gov\/pubmed\// , $_); 
                    $arr5[1]=~s/&#xD;//;
                    $arr5[1]=~s/<\/references>//;
#                    print "REF_PMID:$arr5[1]\n";
                }

                elsif ($_=~/http:\/\//) {
                    my @arr4 = split(/http:\/\// , $_); 
                    $arr4[1]=~s/<\/references>//;
                    $arr4[1]=~s/&#xD;//;
                    $arr4[1]=~s/www.inchem.org\/documents\/pims\/ph/www.inchem.org/g;
                    $arr4[1]=~s/imgt.cines.fr\/3Dstructure-DB\/cgi/imgt.cines.fr/g;



#                    $arr4[1]=~s/\///g;
#                    $arr4[1]=~s/\.//g;
#                    $arr4[1]=~s/\"//g;
#                    $arr4[1]=~s/medicineiupuieduclinpharmddistab/tab/g;

#                    $h{ $id }{"Ref"} = "$arr4[1]";
                    $h{ $id }{"Ref"}{"$arr4[1]"}=1;
#                  print "REF_$arr4[1]\n";
                }
                else {
                    $_=~s/<\/general-references>//;
                    $_=~s/<general-references>//;

                    $_=~s/<\/references>//;
                    $_=~s/<references>//;
                    $_=~s/\#//g;
                    $_=~s/&xAE;//g;
                    $_=~s/&xF6;//g;
                    $_=~s/&xD;//g;
                    $_=~s/&//g;
                    $_=~s/_//g;
                    $_=~s/  / /g;
                    $_=~s/  / /g;
                    $_=~s/  / /g;
                    $_=~s/  / /g;
                    $_=~s/^ //;

                    $h{ $id }{"Ref"}{"$_"}=1;
#                     print "$_\n";
                }

            }
           
    # empty hash
    #           elsif ($_ =~/<drug type="/ {

#                }


        }



open (OUT, ">$in.approved.fas") || die "I can't open $in.approved.fas\n";
open (OUT2, ">$in.approved.txt") || die "I can't open $in.approved.txt\n";

foreach my $ids ( keys %h ) {

    if ( $h{$ids}{"Group"} =~/approved/ ) {
    my $index="1";

#    if (exists )
#        print "$ids\t" . $h{$ids}{"Name"} . "\t" . $h{$ids}{"Desc"}  . "\n";

        foreach my $sequ ( keys %{$h{$ids}{"Seq"}} ) {
            print OUT ">$ids.$index\t";

            print OUT2 "\nID_$ids.$index\t"    . "\tNM_"  . $h{$ids}{"Name"} . "\tDSC_" . $h{$ids}{"Desc"}  . "\t";

            print OUT "$sequ\n";
            $index++;

#            print "$sequ\n";
        }


        foreach my $tar ( keys %{$h{$ids}{"Target"}} ) {
            print OUT2 "TAR_$tar\t";
        }
        if (exists $h{$ids}{"Ref"}  ) {
            foreach my $ref ( keys %{$h{$ids}{"Ref"}} ) {
                $ref=~s/_/\//g;
                print OUT2 "REF_$ref\t";
            }
        }


        $index="1";
    }
    #   print "\n";
}



close (IN);
close (OUT);
close (OUT2);

exit;

