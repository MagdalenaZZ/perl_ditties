#!/usr/local/bin/perl -w	use strict;	use Getopt::Long;		my $clust_num = 20;	my $outfile = 'out';		my $go_cut = 0.01;	my $skip_clustering = 0;	my $save = 0;		my @go_class = ('BP', 'MF', 'CC');		my($help, $data, $rpkms, $go_file, $go_res) = ();		GetOptions	(										);		if($help || !$data || !$rpkms || !$go_file)	{			}	if(!$go_res)	{		}		open(DAT, "<$data") or die "$!";		my @treatment = ();	my %treatments = ();	my %data = ();	my @ids = ();		my %samples = ();	my @samples = ();		while(<DAT>)	{																																											}	close DAT;		open(RPKM, "<$rpkms") or die "$!";		my %rpkms = ();	my @rpkm_cond = ();		while(<RPKM>)	{																																							}	close RPKM;		#print "@treatment\n";	my $treat_string = join ",", @treatment;		unless($skip_clustering)	{		}		open(CLUST, "<$outfile") or die "$!";		my %clusters = ();		my $row_num = 0;		while(<CLUST>)	{								}	close CLUST;		open(RES, ">$go_res\n") or die "$!";;		foreach my $n (sort {$a<=>$b} keys %clusters)	{																																																																														}		close RES;		sub go_enrichment	{																											}		sub profile_plot	{																																			        {	                if($_ == 1)	                {	                        print R_CODE "par(xaxt=\"n\")\n";	                        print R_CODE "plot(x[,1], type = 'l', col=(rgb(1,0,0,1)), ylim=g_range, ylab=\"Mean-normalised log2 RPKM\", xlab=\"Stage\")\n";	                        print R_CODE "text(x = seq(1, 10, by=1), par(\"usr\")[3] - 0.2, labels = row.names(x), pos = 1, xpd = TRUE)\n";	                }	                else	                {	                        print R_CODE "lines(x[,$_], col=(rgb(1,0,0,1)))\n";	                }		        }	        print R_CODE "dev.off()\n";							}		sub cluster	{																																R				}		sub print_usage	{																																USAGE	}
																	"h|help"	"c|counts:s"	"r|rpkms:s"	"g|go:s"	"o|out:s"	"nclust:i"	"t|gocut:f"	"s|skip_clust"	"save"					print_usage();	exit;				$go_res = "results.dat";															chomp;		my($id, @cols) = split /\t/;		if(/^id/)	{																															}	else	{			}											chomp;		if(/^id/)	{			}	else	{																													}									cluster($data, $treat_string, $clust_num, $outfile);											chomp;		$clusters{$_}->{$ids[$row_num]} = 1;		#print "$ids[$row_num]\t$_\n";		$row_num++;								#print "$n\n";		open(OUT, ">cluster$n\.prof") or die "$!";		my @header = ();		foreach my $treatment (sort {$a<=>$b} keys %treatments)	{		}		#my $header = "id\t". join "\t", @header;		#print OUT "$header\n";		my @matrix = ();		foreach my $id (sort keys %{$clusters{$n}})	{								}		my $c = 0;		foreach my $row (@matrix)	{															}	close OUT;		profile_plot("cluster$n\.prof");		my @ids = @{$matrix[0]};		my $ids = join "\n", @ids;		my $cluster_size =  scalar @ids;		#print "IDS: $ids\n";		open(OUT, ">cluster$n\.list") or die "$!";	print OUT "$ids\n";	close OUT;		print RES "Cluster $n\t$cluster_size members\n";		foreach my $class (@go_class)	{							}		print "\n";								my($file, $type) = @_;		my @dat = ();		print STDERR "Running ~mz3/bin/perl/run_topGO.pl $file $go_file $type\n";	system("~mz3/bin/perl/run_topGO.pl $file $go_file $type") == 0 or die "$!";		open(IN, "<clust1") or die "$!";		while(<IN>)	{												}	close IN;		return \@dat;					my($file) = @_;		open(IN, "<$file") or die "$!";		my @cols = split /\t/, <IN>;	my $ncols = scalar @cols - 1;		close IN;		open(R_CODE, ">$file\.R") or die "$!";		print R_CODE "x<-read.table(\"$file\", header=TRUE, row.names=1)\n";	print R_CODE "g_range <- range(0, x)\n";	print R_CODE "png(\"$file\.png\")\n";		for(1..$ncols)	{												}	print R_CODE "dev.off()\n";		print R_CODE "pdf(\"$file\.pdf\")\n";		for(1..$ncols)																	close R_CODE;	close IN;		system("R-3.0.0 --no-save < $file.R") == 0 or die "$!";					my ($dat, $treat_string, $clusters, $outfile) = @_;		my $save_string = "";		if($save)	{		}		open(R_CODE, ">temp.R") or die "$!";		print R_CODE <<R;		library(MBCluster.Seq)		Count<-read.table("$dat", header=TRUE, row.names=1)	GeneID=row.names(Count)		Treatment=c($treat_string)	Normalizer=rep(1,ncol(Count))	mydata=RNASeq.Data(Count,Normalize=NULL,Treatment,GeneID)	c0=KmeansPlus.RNASeq(mydata,nK=$clusters)\$centers	cls2=Cluster.RNASeq(data=mydata,model="nbinom",centers=c0,method="EM")	cls=cls2\$cluster	$save_string	tr=Hybrid.Tree(data=mydata,cluste=cls,model="nbinom")	pdf("clustering.pdf")	plotHybrid.Tree(merge=tr,cluster=cls,logFC=mydata\$logFC,tree.title=NULL)	dev.off()		write(cls, file="$outfile",sep="\\n")		close R_CODE;		system("R --no-save < temp.R") == 0 or die "$!";					print <<USAGE;		# cluster_expression.pl		Mandatory:	"c|counts:s"	"r|rpkms:s"	"g|go:s"		Optional:	"h|help"	"o|out:s"	"nclust:i"	"t|gocut:f"	"s|skip_clust"	"save"		# Read count/RPKM file format	n.b. Header format for count/RPKM data should include timecourse/treatment	info in the following format: <treatment>.<unique_id> e.g. J2.1234_1 where	J2 is the treatment and 1234_1 is the lane id. So J2.1234_1 and J2.4321_1	will be interpreted as biological replicates. this line should also begin	"id" for the gene id column:		id	GeneA	GeneB		# Go annotation file format	<Id>\t<go1,go2,go3,go4...>			
																	=> \$help,	=> \$data,	=> \$rpkms,	=> \$go_file,	=> \$go_res,	=> \$clust_num,	=> \$go_cut,	=> \$skip_clustering,																																my $c = 1;		my $col_num = 1;		my %seen = ();		foreach my $col (@cols)	{																						}				$data{$id} = \@cols;	push @ids, $id;																my($id, @cols) = split /\t/;	my @rpkm_cond = @cols;					my($id, @cols) = split /\t/;		my $c = 0;		my $total = 0;		my @logs = ();		foreach my $col (@cols)	{						}		my $mean_of_logs = $total / scalar @cols;		foreach my $log (@logs)	{						}																																											push @header, $treatments{$treatment};											push @{$matrix[0]}, $id;		for(0..scalar @{$rpkms{$id}} - 1)	{		}								my $data = join "\t", @$row;		if(!exists $treatments{$c})	{		}		#print "$c\t$treatments{$c}\n";		$data = $treatments{$c} . "\t" . $data;		print OUT "$data\n";		$c++;																						my $res = go_enrichment("cluster$n\.list", $class);		foreach my $term (@$res)	{		}																						chomp;	#"GO.ID" "Term"  "Annotated"     "Significant"   "Expected"      "topGO"	next unless /^"\d/;	s/\"//g;		my($n, $id, $term, $ann, $sig, $exp, $score) = split /\t/;		if($score <= $go_cut)	{		}																										if($_ == 1)	{				}	else	{		}																																						$save_string = "save(cls2, file=\"cls.RData\")";																																						Read counts for each gene (see below for format)	RPKMs for each gene (see below for format)	GO annotations (see below for format)			Help	Outfile for cluster descriptions	Number of clusters (20)	Cutoff q-value for go term enrichment (default: 0.05)	Skip clustering										J2.1234_1	12	45						
																									=> \$save																																							$col =~ /(.*)\./;		my $treatment = $1;		$samples{$col_num} = $col;	push @samples, $col;		if(exists $seen{$treatment})	{		}	else	{						}		$col_num++;																																						my $log = log($col + 1) / log(2);		push @logs, $log;		$total += $log;							my $norm_log = $log - $mean_of_logs;		#print "$log\t$mean_of_logs\t$norm_log\n";		push @{$rpkms{$id}}, $norm_log;																																																											push @{$matrix[$_+1]}, $rpkms{$id}->[$_];													$treatments{$c} = "";																																			print RES "$term\n";																																push @dat, "$id\t$type\t$term\t$ann\t$sig\t$score";																													print R_CODE "par(xaxt=\"n\")\n";	print R_CODE "plot(x[,1], type = 'l', col=(rgb(1,0,0,1)), ylim=g_range, ylab=\"Mean-normalised log2 RPKM\", xlab=\"Stage\")\n";	print R_CODE "text(x = seq(1, 10, by=1), par(\"usr\")[3] - 0.2, labels = row.names(x), pos = 1, xpd = TRUE)\n";				print R_CODE "lines(x[,$_], col=(rgb(1,0,0,1)))\n";																																																																																							Save clustering object as cls.RData									J2.4321_1	43	90						
																																																																									push @treatment, $seen{$treatment};				$seen{$treatment} = $c;	push @treatment, $seen{$treatment};		$treatments{$c} = $treatment;	$c++;																																																																																																																																																																																																																																																																																																																																						J4.2345_2	1000	3						
																																																																																																																																																																																																																																																																																																																																																																																																																							J4.5432_1	2000	1						
