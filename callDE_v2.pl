#!/usr/local/bin/perl -w
#
# Run DESeq or EdgeR (or others?) based on a table of read counts for multiple conditions
# and replicates
#
# Run topGO to get GO term overrepresentation

use strict;
use Getopt::Long;

my $help;
my $outdir = 'out';

# DESeq hardcore options
my $locfit = 0;

my $r_prog = '/software/R-2.15.2/bin/R';
#my $r_prog = '/software/R-3.0.0/bin/R';
my $topgo_wrap = '/nfs/users/nfs_a/ar11/scripts/run_topGO2.pl';

# Genes must be at least this unique to enter analysis
# q-value cutoffs for DE results
my $exp_cutoff = 0.01;

my $topgo = '';
my $ignore = '';
my %ignore = ();
my @go_types = ('BP', 'MF', 'CC');

my $ann_file = '';

my $cpmfilt = 3;

# Fold change cut-off for DE genes
my $fc_cut = 1;

GetOptions
(
	"h|help"	=> \$help,
	"o|outdir:s"	=> \$outdir,
	"a|ann:s"	=> \$ann_file,
	"e|exp_cut:f"	=> \$exp_cutoff,
	"t|topgo:s"	=> \$topgo,
	"ignore:s"	=> \$ignore,
	"locfit"	=> \$locfit,
	"c|cpmfilt:f"	=> \$cpmfilt,
	"f|fc_cut:f"	=> \$fc_cut
);

if($help)
{
	print_usage();
	exit;
}

# Get other arguments
my($mode, $exp_file, $cond1, $cond2) = @ARGV;

if(!defined $cond2)
{
	print_usage("Missing arguments!\n");
	exit;
}

if(!-e $outdir)
{
        mkdir $outdir;
}

# Get annotation
my ($desc, $go);

if(defined $ann_file && $ann_file ne '')
{
        ($desc) = get_ann($ann_file);
}

# Check mode and run appropriate analysis
if($mode eq 'erc' || $mode eq 'erglm_all' || $mode eq 'erglm')
{
	run_edgeR($exp_file, $exp_cutoff, $cond1, $cond2, $outdir, $mode, $cpmfilt, $fc_cut);

	my($scores, $uplist, $downlist)  = ();

	if($mode eq 'erc' || $mode eq 'erglm')
	{
		($scores, $uplist, $downlist) = analyse_edgeR("res.dat", $desc, $exp_cutoff, $cond1, $cond2, $outdir, $mode, $fc_cut);
	}
	elsif($mode eq 'erglm_all' || $mode eq 'erglm')
	{
		($scores, $uplist) = analyse_edgeR_glmall("res.dat", $exp_cutoff, $desc, $outdir);
	}

	if($topgo && $ann_file)
	{
	        runTopGO($uplist, $downlist, $topgo);
	}

	exit;
}
elsif($mode eq 'deseq')
{
	# cool
}
else
{
	print STDERR "Inappropriate mode specified!\n";
	print_usage();
	exit;
}


if($ignore)
{
	open(IG, "<$ignore") or die "$!";
	
	while(<IG>)
	{
		chomp;
	
		$ignore{$_} = 1;
	}
	close IG;
}

my $input_file = 'input.dat';
my $ma_plot = 'ma_plot.png';
my $deseq_scores = 'scores.dat';
my $cons_dat = 'cons.dat';
my $lib_dat = 'lib.dat';
my $logged_file = 'logged_input.dat';

# Extract data from expression files
my($exp_dat, $all_ids, $headers) = get_exp($exp_file, $cond1, $cond2);

# Create tabular file of expression values for DESeq
open(OUT, ">$outdir/$input_file") or die "$!";

# Do we have reps of both? If not, can't do ecdf plot
my $full_reps = 0;
if(scalar keys %{$headers->{$cond1}} >= 2 && scalar keys %{$headers->{$cond2}} >=2)
{
        $full_reps = 1;
}

my @header = ("gene");

# For deseq
my @conds = ();

foreach my $cond ($cond1, $cond2)
{
	foreach my $rep (sort {$a<=>$b} keys %{$headers->{$cond}})
	{
		push @header, "$cond\.$rep";
		push @conds, $cond;
	}
}

my $header = join "\t", @header;

print OUT "$header\n";

foreach my $id (sort keys %{$all_ids})
{
	my @row = ($id);

	foreach my $cond ($cond1, $cond2)
	{
		foreach my $rep (sort {$a<=>$b} keys %{$headers->{$cond}})
	        {
			if(!exists $exp_dat->{$id}->{$cond}->{$rep})
			{
				$exp_dat->{$id}->{$cond}->{$rep} = 0;
			}	

			push @row, $exp_dat->{$id}->{$cond}->{$rep};
		}
	}

	my $row = join "\t", @row;

	print OUT "$row\n";
}

# Log input data for drawing plots and normalisation
log_data("$outdir/$input_file", "$outdir/$logged_file");

runDESeq("$outdir/$input_file", \@conds, $locfit);

my($scores, $uplist, $downlist) = analyseDESeq($exp_cutoff, $fc_cut);

if($topgo && $ann_file)
{
	runTopGO($uplist, $downlist, $topgo);
}

sub runTopGO
{
	my($uplist, $downlist, $go) = @_;

	open(UP, ">$outdir/topgo_uplist.dat") or die "$!";

	foreach my $id (@$uplist)
	{
		print UP "$id\n";
	}
	close UP;

	open(DOWN, ">$outdir/topgo_downlist.dat") or die "$!";

	foreach my $id (@$downlist)
	{
		print DOWN "$id\n";
	}
	close DOWN;

	my $topgo_file = "$outdir/topgo.res";

	open(OUT, ">$topgo_file") or die "$!";

	foreach my $type (@go_types)
	{
		chomp(my @res = `$topgo_wrap $outdir/topgo_uplist.dat $go $type`);
	
		foreach my $line (@res)
		{
			print OUT "UP\t$type\t$line\n";
		}
	}

	foreach my $type (@go_types)
        {
                chomp(my @res = `$topgo_wrap $outdir/topgo_downlist.dat $go $type`);

                foreach my $line (@res)
                {
                        print OUT "DOWN\t$type\t$line\n";
                }
        }

	
	close OUT;
}

sub runDESeq
{
        my($dat_file, $conds, $locfit) = @_;

        my $cond_string = join "\",\"", @$conds;

        # Need to set this if there are no replicates
        my $pool_string = '';

        if(scalar @$conds == 2)
        {
                $pool_string = ',method="blind", sharingMode="fit-only"';
        }

	my $fit_type = '';

	if($locfit)
	{
		$fit_type = ', fitType = c( "local")';
	}

        open(OUT, ">$outdir/temp.R") or die "$!";

        print OUT <<R_CODE;

        library(DESeq, lib.loc="~ar11/R/library/")
        countsTable <- read.delim("$dat_file", header=TRUE, stringsAsFactors=TRUE)
        rownames(countsTable) <- countsTable\$gene
        countsTable <- countsTable[ , -1]
        conds <- c("$cond_string")
        cds <- newCountDataSet(countsTable, conds)
        cds <- estimateSizeFactors(cds $fit_type)
        sizeFactors(cds)
        cds <- estimateDispersions(cds $pool_string)

R_CODE

        print OUT <<R_CODE;

        res <- nbinomTest(cds, "$cond1", "$cond2")
        write.table(res, "$outdir/$deseq_scores")
        png("$outdir/$ma_plot")
        plot(res\$baseMean, res\$log2FoldChange, log="x", col=ifelse(res\$padj < $exp_cutoff, "red", "black"))

R_CODE

        close OUT;

        my @result = `$r_prog --no-save < $outdir/temp.R`;
}

sub analyseDESeq
{
	my($cutoff, $fc_cut) = @_;

        open(IN, "<$outdir/$deseq_scores") or die "$!: $outdir/$deseq_scores";

        my @up = ();
        my @down = ();

	my %scores = ();

        while(<IN>)
        {
                chomp;

                next if /^\"id/;

		s/"//g;

                my($row, $id, @fields) = split / /;

                next if !defined $fields[6] || $fields[6] eq 'NA';

		$scores{$id} = {	"baseMeanA" => $fields[1],
					"baseMeanB" => $fields[2],
					"foldChange" => $fields[3],
					"log2FoldChange" => $fields[4],
					"pval" => $fields[5],
					"padj" => $fields[6]			
		};

		my $log_fc_up = log($fc_cut)/log(2);
		my $log_fc_down = 0 - $log_fc_up;

                if($fields[6] <= $cutoff)
                {
                        if($fields[4] <= $log_fc_down)
                        {
                                push @down, $id;
                        }
                        if($fields[3] >= $log_fc_up)
                        {
                                push @up, $id;
                        }
                }
        }
        close IN;

	my $up_count = scalar @up;
	my $down_count = scalar @down;

	open(RES, ">$outdir/res_$cutoff\.dat") or die "$!";

	print RES "$up_count genes up and $down_count genes down between $cond1 and $cond2 with q-value <= $cutoff and fold change > $fc_cut\n\n";

	foreach my $id (sort {$scores{$a}->{'padj'}<=>$scores{$b}->{'padj'}} @up)
	{
		my $ann = exists $desc->{$id} ? $desc->{$id} : '';

		print RES "UP\t$id\t$scores{$id}->{'padj'}\t$scores{$id}->{'baseMeanA'}\t$scores{$id}->{'baseMeanB'}\t$scores{$id}->{'foldChange'}\t$ann\n";
	}

	foreach my $id (sort {$scores{$a}->{'padj'}<=>$scores{$b}->{'padj'}} @down)
	{
		my $ann = exists $desc->{$id} ? $desc->{$id} : '';

		print RES "DOWN\t$id\t$scores{$id}->{'padj'}\t$scores{$id}->{'baseMeanA'}\t$scores{$id}->{'baseMeanB'}\t$scores{$id}->{'foldChange'}\t$ann\n";
	}

	close RES;

	return(\%scores, \@up, \@down);
}


sub get_ann
{
	my($file) = @_;

	my %desc = ();
	my %go = ();

	open(F, "<$file") or die "$!";

	while(<F>)
	{
		chomp;

		my($gene, $desc) = split /\t/;

		$desc{$gene} = $desc;
	}
	close F;

	return(\%desc);
}

sub runR
{
	my $code = shift;

	 print STDERR "Running R with $code\n";

	open(R, ">$outdir/r.temp") or die "$!";

	print R $code;
	close R;

	my $res = `R --no-save < $outdir/r.temp`;

	#unlink "$outdir/r.temp";

	return $res;
}

sub get_exp
{
	my ($dat, $a, $b) = @_;

	my %results = ();
	my %all_ids = ();
	my %header_info = ();

	open(DAT, "<$dat") or die "$!";

	my %headers = ();

	while(<DAT>)
	{
		chomp;

		if(/^id/)
		{
			my ($junk, @header) = split /\t/;

			my $h = 0;

			foreach my $col (@header)
			{
				$h++;

				my($cond, $rep) = split /\./, $col;
			
				next unless $cond1 eq $cond || $cond2 eq $cond;

				$headers{$h} = [$cond, $rep];

				$header_info{$cond}->{$rep} = 1;

			}
		}
		else
		{
			my(@a) = split /\t/;

			# Ignore any ids we want to exclude e.g. in mixtures of species
			next if exists $ignore{$a[0]};

			foreach my $index (keys %headers)
			{
				$results{$a[0]}->{$headers{$index}->[0]}->{$headers{$index}->[1]} = $a[$index];

				$all_ids{$a[0]} = 1;
			}
		}
	}
	close DAT;

	return (\%results, \%all_ids, \%header_info);
}

sub log_data
{
        my($file_in, $file_out) = @_;

        open(IN, "<$file_in") or die "$!";
        open(OUT, ">$file_out") or die "$!";

        while(<IN>)
        {
                chomp;
                my($id, @cols) = split /\t/;

                my @new_cols = ();

                if($id eq 'gene')
                {
                          print OUT "$_\n";
                }
                else
                {
                        foreach my $col (@cols)
                        {
                                $col = log2($col + 1);

                                push @new_cols, $col;
                        }

                        my $row = join "\t", @new_cols;
                        print OUT "$id\t$row\n";
                }

        }

        close IN;
}

sub log2
{
	return log($_[0])/log(2);
}

sub run_edgeR
{
        my($input, $cutoff, $cond1, $cond2, $outdir, $mode, $cpmfilt, $fc_cut) = @_;

	# Log fold change cut-offs for plotting
	my $log_fc_up = log($fc_cut)/log(2);
        my $log_fc_down = 0 - $log_fc_up;

        # Get conditions
        open(IN, "<$input") or die "$!";

        chomp(my $head = <IN>);
        $head=~s/HYMtophat//g;

        close IN;

        my($id, @head) = split /\t/, $head;

        my %samples = ();

        open(OUT, ">$outdir/targ.dat") or die "$!";

        print OUT "Sample\tTreatment\tReplicate\n";

	my @ord_cond = ();

	# This is for translating conditions into coefs for the pairwise GLM mode
	my %index = ();

        foreach my $sample (@head)
        {
                my ($cond, $rep) = split /\./, $sample;

		# Get condition order to setup design matrix
                if(!exists $samples{$cond})
                {
                        push @ord_cond, $cond;
			$index{$cond} = scalar @ord_cond;
                }

                $samples{$cond} = $rep;

                print OUT "$sample\t$cond\t$rep\n";
        }

        close OUT;



        open(OUT, ">$outdir/edge.R") or die "$!";

        print OUT <<R;

        library(edgeR)

        # setup experiment design
        targets <- readTargets("$outdir/targ.dat")

        targets

        #Read in counts
        x <- read.delim("$input", , row.names=1, stringsAsFactors=FALSE)

        head(x)

        y <- DGEList(counts=x, group=targets\$Treatment)

        colnames(y) <- targets\$Sample

        dim(y)

        # Exclude genes with counts below x per million
        keep <- rowSums(cpm(y)>$cpmfilt, na.rm=TRUE) >= 3

        y <- y[keep,]

        dim(y)

        # Recompute library sizes
        y\$samples\$lib.size <- colSums(y\$counts)

        # TMM normalisation
        y <- calcNormFactors(y)

        y\$samples

	# MDS plot on biological coefficient of variation
        pdf("$outdir/plotMDS.pdf")
        plotMDS(y, pch = 21, cex = 0.5)
        dev.off()

        y <- estimateCommonDisp(y, verbose=TRUE)
        y <- estimateTagwiseDisp(y)

        pdf("$outdir/plotBCV.pdf")
        plotBCV(y)
        dev.off()

R
        # Order groups so reference is the first by input file not alphabet
        foreach my $cond (reverse @ord_cond)
        {
                print OUT "y\$samples\$group <-relevel(y\$samples\$group, ref=\"$cond\")\n";
        }

        my $last_coef = scalar @ord_cond;
	
	if($mode eq 'erc')
	{
	        print OUT <<R;
	
	
	        # Get p/q values
	        et <- exactTest(y, pair=c("$cond1", "$cond2"))
	        tt <- topTags(et, n=nrow(et\$table))
	
	        # Print out CPMs
	         write.table(cpm(y), "$outdir/cpm.dat")
	
		# Print out pseudo counts
		write.table(y\$pseudo.counts, "$outdir/pseudo_counts.dat", sep="\\t")

	        #print OUT fc, q values
	        write.table(tt, "$outdir/res.dat")
	
	        # MA plot
	        de <- decideTestsDGE(et, p.value=$cutoff)
	        detags <- rownames(y)[as.logical(de)]
	        pdf("$outdir/ma_plot.pdf")
	        plotSmear(et, de.tags=detags)
	        abline(h=c($log_fc_down, $log_fc_up), col="blue")
	        dev.off()

R
	}
	elsif($mode eq 'erglm_all')
	{
		print OUT <<R;

		# Setup design matrix
	        design <- model.matrix(~group, data=y\$samples)
	
	        fit <- glmFit(y, design)
	        lrt <- glmLRT(fit, coef=2:$last_coef)
	
	        tt <- topTags(lrt, n=nrow(lrt\$table))
	
	        # Print out CPMs
	         write.table(cpm(y), "$outdir/cpm.dat")
	
	        #print OUT fc, q values
	        write.table(tt, "$outdir/res.dat")

R
	}
	elsif($mode eq 'erglm')
	{
		print OUT <<R;

                # Setup design matrix
                design <- model.matrix(~0+group, data=y\$samples)

                fit <- glmFit(y, design)

		newContrast <- makeContrasts(group$cond2-group$cond1, levels=design)

		newContrast

		lrt <- glmLRT(fit, contrast=newContrast)

		tt <- topTags(lrt, n=nrow(lrt\$table))

		# Print out CPMs
                write.table(cpm(y), "$outdir/cpm.dat")

                #print OUT fc, q values
                write.table(tt, "$outdir/res.dat")

		pdf("$outdir/ma_plot.pdf")
                plotSmear(lrt)
                abline(h=c($log_fc_down, $log_fc_up), col="blue")
                dev.off()
R
	}

        print("$r_prog --no-save < $outdir/edge.R > $outdir/r.stdout") == 0 or die "$!";
}

sub analyse_edgeR_glmall
{
	my($output, $cutoff, $desc, $outdir) = @_;

        $cutoff = 0.05 unless defined $cutoff;

        open(IN, "<$outdir/$output") or die "$!: $output";

        my @de = ();

        my %scores = ();

        while(<IN>)
        {
                chomp;

                s/"//g;

                my @comps = ();

                if (/^logFC/)
                {
                        my @head = split /\s/;

                        foreach my $name (@head)
                        {
                                push @comps, $name if $name =~ /logFC\./;
                        }

                        next;
                }

                my($id, @fields) = split / /;

                $scores{$id} = {
                                        "logCPM" => $fields[-4],
                                        "LR"    => $fields[-3],
                                        "Pval" => $fields[-2],
                                        "FDR" => $fields[-1]
                };

                if($scores{$id}->{'FDR'} <= $cutoff)
                {
                        push @de, $id;
                }
        }
        close IN;

        my $de_count = scalar @de;

        open(RES, ">$outdir/res_$cutoff\.dat") or die "$!";

        print RES "$de_count genes differentially expressed across conditions with FDR <= $cutoff\n\n";

        print RES "Direction\tId\tFDR\tlogCPM\tLR\tDesc\n";

        foreach my $id (sort {$scores{$a}->{'FDR'}<=>$scores{$b}->{'FDR'}} @de)
        {
                my $ann = exists $desc->{$id} ? $desc->{$id} : '';

                print RES "NA\t$id\t$scores{$id}->{'FDR'}\t$scores{$id}->{'logCPM'}\t$scores{$id}->{'LR'}\t$ann\n";
        }

        close RES;

        return(\%scores, \@de);
}

sub analyse_edgeR
{
	my($output, $desc, $cutoff, $cond1, $cond2, $outdir, $mode, $fc_cut) = @_;

        $cutoff = 0.05 unless defined $cutoff;

        open(IN, "<$outdir/$output") or die "$!: $output";

        my @up = ();
        my @down = ();
	my @de = ();

        my %scores = ();

        while(<IN>)
        {
                chomp;

                next if /^\"logFC/;

                s/"//g;

                my($id, @fields) = split / /;

		if($mode eq 'erglm')
		{
			$scores{$id} = {
                                                "logFC" => $fields[0],
                                                "logCPM" => $fields[1],
						"LR"	=> $fields[2],
                                                "Pval" => $fields[3],
                                                "FDR" => $fields[4]
                        };

		}
		else
		{
                	$scores{$id} = {
                	                        "logFC" => $fields[0],
                	                        "logCPM" => $fields[1],
                	                        "Pval" => $fields[2],
                	                        "FDR" => $fields[3]
                	};
		}

		my $log_fc_up = log($fc_cut)/log(2);
                my $log_fc_down = 0 - $log_fc_up;

                if($scores{$id}->{'FDR'} <= $cutoff)
                {
                        if($scores{$id}->{'logFC'} <= $log_fc_down)
                        {
                                push @down, $id;
                        }
                        if($scores{$id}->{'logFC'} >= $log_fc_up )
                        {
				push @up, $id;
                        }
                }
        }
        close IN;

        my $up_count = scalar @up;
        my $down_count = scalar @down;

        open(RES, ">$outdir/res_$cutoff\.dat") or die "$!";

        print RES "$up_count genes up and $down_count genes down between $cond1 and $cond2 with FDR <= $cutoff and fold change > $fc_cut\n\n";

        print RES "Direction\tId\tFDR\tlogCPM\tlogFC\tDesc\n";

        foreach my $id (sort {$scores{$a}->{'FDR'}<=>$scores{$b}->{'FDR'}} @up)
        {
                my $ann = exists $desc->{$id} ? $desc->{$id} : '';

                print RES "UP\t$id\t$scores{$id}->{'FDR'}\t$scores{$id}->{'logCPM'}\t$scores{$id}->{'logFC'}\t$ann\n";
        }

        foreach my $id (sort {$scores{$a}->{'FDR'}<=>$scores{$b}->{'FDR'}} @down)
        {
                my $ann = exists $desc->{$id} ? $desc->{$id} : '';

                print RES "DOWN\t$id\t$scores{$id}->{'FDR'}\t$scores{$id}->{'logCPM'}\t$scores{$id}->{'logFC'}\t$ann\n";
        }

        close RES;

        return(\%scores, \@up, \@down);
}


sub print_usage
{
	my $err_msg = shift;

	print <<USAGE;

	Read count data file format:
	- Tab separated with integer read counts
	- Header line with "id" as first column
	- Each column header thereafter is <condition>.<rep> e.g. naive.1, naive.2, infected.1 etc.

	Annotation file format:
	<id>\t<desc>

	GO term format:
	<id>\t<GO:1,GO:2,GO:3>

	MODES: 	deseq 	 	pairwise comparison with DESeq
		erc 		pairwise comparison with EdgeR classic (not GLM), 
				all samples normalised together
		erglm		pairwise comparison with EdgeR GLM,
				all samples normalised together
		erglm_all	Use EdgeR GLM to determine genes differentially
				expressed across all samples

	USAGE: [options] <mode> <expression_file> <cond1> <cond2>

        -h | -help		help
        -o | -outdir		outdir (out)
        -a | -ann		ann_file
        -e | -exp_cut		DESeq q-value cutoff (0.01)
        -t | -topgo		File of GO terms for running topGO
	-ignore			File with list of ids to ignore (e.g. in mixtures of species)
	-c | -cpmfilt		Exclude genes in EdgeR analysis below x counts per million (3)
	-f | -fc_cut		Fold change cutoff for DE genes (1)

	# More serious options
	-locfit			Set fitType = local in DESeq estimatedispersion

	n.b. MA plot shows genes passing p-value cutoff in red and fold-change thresholds in blue
	
USAGE

	print "$err_msg\n" if defined $err_msg;
}
