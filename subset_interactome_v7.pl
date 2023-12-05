#!/usr/bin/perl


# 09 October 2014: 	hid the xml header generation as a function and added network
#                  	types (in between, first neighbour, matrix) in the network name
# 09 October 2014:	Implemented generation of matrix interactomes
# 18 November 2014:	Fixed edge duplication in matrix networks
# 20 November 2014:	Added graphml functionality
# 24 November 2014:	Added weights in graphml
# 16 July 2015:		Revision to include protein names and replace predefined node_names
# 						(no longer provided) with on the fly generated node_names 
# 29 July 2015:		Revision to add PTM information on the nodes					

use warnings;
use strict;
use Getopt::Long;

sub init();
sub usage();
sub generate_node_label($$$);
sub generateXmlHeader($$);
sub generateGraphmlHeader($);
sub printNodeXml($$$$$$$$$$$$);
sub printNodeGraphml($$);
sub printEdgeXml($$$$$$$$$$$$$$$$$$$$$$);
sub printEdgeGraphml($$);


my $input_interactome_file;
my $input_interactor_file;
my $input_interactor_list;
my $all_interactors_flag;
my $interactor_type;
my $interaction_types;
my $out_file;
my $networkName;
my $help;
my $labels;
my $protein_node_names;
my $no_loops;
my $produce_graphml;
my $weights_file;
my $node_annotation_file;

my $currentTime = localtime();

my %interaction_definitions = 
(
	'reactome' => 'Reactome-FI',
	'trx' => 'transcriptional',
	'direct' => 'direct',
	'reaction' => 'reaction',
	'complex' => 'complex',
	'complex_low' => 'complex_low',
);

GetOptions (
		"help"					=> \$help,					
		"interactome_file=s"	=> \$input_interactome_file,
		"interactor_file=s"		=> \$input_interactor_file,
		"interactor_list=s"		=> \$input_interactor_list,
		"interactor_type=s"		=> \$interactor_type,
		"interaction_types=s"	=> \$interaction_types,
		"out_file=s"			=> \$out_file,
		"name=s"				=> \$networkName,
		"labels=s"				=> \$labels,
		"no_loops"				=> \$no_loops,	
		"graphml"				=> \$produce_graphml,
		"weight=s"				=> \$weights_file,	
		"node_annotation=s"		=> \$node_annotation_file,
		);
		
##########################################################################################

# Initialise options:
init();

##########################################################################################
# Parse interactors list from input:
# Note that if neither of these have been defined, we are still going to process the 
# interactome using all interactors in the interactome file.  
# We are just checking that if any of the --interactor_file or --interactor_list 
# flags are defined, we are processing them
# Note that we are not using an elsif structure so that both flags can be used

my %input_interactors = ();
if($input_interactor_file)
{
	open(IN, $input_interactor_file) or die "Could not access $input_interactor_file\n";
	my $counter = 0;
	while(defined(my $line = <IN>))
	{
		chomp($line);
		my ($interactor) = $line;# =~ /^([a-zA-Z0-9]+).*/;
		if($interactor_type eq 'pac' && $interactor =~/^([^-]+)/)
		{
			$interactor = $1;
		}
		# Ignore duplicate entries
		next if (exists $input_interactors{$interactor});
		$input_interactors{$interactor}++;
		$counter++;
	}
	close(IN);
	# Exit unless we have some input:
	unless($counter)
	{
		print "No entries found in the provided interactor file. Exiting...\n";
		&usage;
		exit(0);
	}
}
if($input_interactor_list) # $input_interactor_list is defined
{
	chomp($input_interactor_list);
	my @input = split(/,/, $input_interactor_list);
	if(@input)
	{
		foreach my $interactor (@input)
		{
			# handle isoforms for pac
			if($interactor_type eq 'pac' && $interactor =~/^([^-]+)/)
			{
				$interactor = $1;
			}
			next if (exists $input_interactors{$interactor});
			$input_interactors{$interactor}++; 
		}
	}
	else
	{
		print "Please supply a comma-separated list of interactors using the " . 	
				"--interactor_list flag. Exiting...\n";
		&usage;
		exit(0);
	}
}

##########################################################################################
# Parse desired interactions from input
my %interaction_types;

my @input_interactions = split(/,/, $interaction_types);
foreach my $input_interaction_type ( @input_interactions)
{
	if($input_interaction_type eq 'all')
	{
		foreach my $key (keys %interaction_definitions)
		{
			$interaction_types{$interaction_definitions{$key}}++;
		}
		last;
	}
	elsif(exists $interaction_definitions{$input_interaction_type})
	{
		$interaction_types{$interaction_definitions{$input_interaction_type}}++;
	}
}

unless( %interaction_types)
{
	print "No acceptable interaction types found. Please use one or more from:\n" .
		  "all, reactome, psite, trx, direct, reaction, complex, complex_low\n";
	&usage;
	exit(0);
}

##########################################################################################
# Process node annotation file if provided:
my %node_mapper = ();
if($node_annotation_file)
{
	open(NODE, $node_annotation_file) or die "Could not access node annotation file " . 
		$node_annotation_file . "\n";
	my $first_line;	
	
	while(defined(my $line = <NODE>))
	{
		chomp($line);
		my @cols = split(/\t/, $line);
		unless($first_line)
		{
			$node_mapper{'header'} = \@cols;
			$first_line++;
			next;
		}
		$node_mapper{'map'}{$cols[0]} = \@cols;
	}	
	close(NODE);	
}


##########################################################################################
# Process interactions

open(INT, $input_interactome_file) or 
		die "Could not access $input_interactome_file\n";
		
open(XML, ">", $out_file . ".first_neighbours.xml") or 
		die "Could not create file $out_file" . ".first_neighbours.xml";
open(BETWXML, ">", $out_file . ".in_between.xml") or 
		die "Could not create file $out_file" . ".in_between.xml";
open(MATRIXXML, ">", $out_file . ".matrix.xml") or 
		die "Could not create file $out_file" . ".matrix.xml";
		
if( $produce_graphml )
{		
	print STDERR "Creating files for R...\n";
	open(GRAPHML, ">", $out_file . ".first_neighbours.graphml") or 
		die "Could not create file $out_file" . ".first_neighbours.graphml";
	open(BETWGRAPHML, ">", $out_file . ".in_between.graphml") or 
		die "Could not create file $out_file" . ".in_between.graphml";
	open(MATRIXGRAPHML, ">", $out_file . ".matrix.graphml") or 
		die "Could not create file $out_file" . ".matrix.graphml";				
}	

$networkName = "Network" unless ($networkName);

print BETWXML generateXmlHeader($networkName . ".in_between", $currentTime);
print XML generateXmlHeader($networkName . ".first_neighbours", $currentTime);
print MATRIXXML generateXmlHeader($networkName . ".matrix", $currentTime);

if( $produce_graphml )
{
	print STDERR "Writing headers for R files...\n";
	print BETWGRAPHML generateGraphmlHeader($networkName . ".in_between");
	print GRAPHML generateGraphmlHeader($networkName . ".first_neighbours");
	print MATRIXGRAPHML generateGraphmlHeader($networkName . ".matrix");
}

# Cytoscape related:
my $nodeXml = "";
my $edgeXml = "";
my $nodeBetweenXml = "";
my $edgeBetweenXml = "";
my $edgeMatrixXml = "";

# R igraph related:
my $nodeGraphml = "";
my $edgeGraphml = "";
my $nodeBetweenGraphml = "";
my $edgeBetweenGraphml = "";
my $edgeMatrixGraphml = "";


my %interactor_unique_ids = ();
my $unique_id_counter = 0;
my %interactor_between_unique_ids = ();
my $unique_between_id_counter = 0;

my %established_interactions_graphml = ();

while(defined(my $line = <INT>))
{
	chomp($line);
	my @cols = split(/\t/, $line);
	
	my $colA;
	my $colB;
	
	
	# Filter out interaction types we are not interested in
	my ($type) = $cols[0];
	next unless(exists $interaction_types{$type});
	
	# Define what columns the identifiers interrogate based on interactor_type input
	if ($interactor_type eq 'pac') # This is the default
	{
		($colA) = $cols[3];
		($colB) = $cols[4];
	}
	elsif ($interactor_type eq 'uniprot_id')
	{
		($colA) = $cols[17];
		($colB) = $cols[18];
	}
	else # interactor_type is gene
	{
		($colA) = $cols[7];
		($colB) = $cols[8];
	}
	
	# Continue only if BOTH identifiers for the specified interactor_type exist
	# in the interaction line
	next unless($colA && $colB);
	
	# Continue only if at least one of the two interactors is in the interactor_list
	# or if we are processing the entire interactome:
	next unless((exists $input_interactors{$colA}) || 
				(exists $input_interactors{$colB}) || 
				$all_interactors_flag);
	# Avoid self loops if prompted to do so (handles cytoscape havoc):
	if ($no_loops)
	{
		next unless ($colA ne $colB);
	}
	
	# Handle in between interactions if exist
	if((exists $input_interactors{$colA}) && (exists $input_interactors{$colB}))
	{
		if (not exists $interactor_between_unique_ids{$cols[3]})
		{
			my $is_source = ($input_interactors{$colA} ? "y" : "n");
			my $node_label = generate_node_label(\@cols, $labels, $cols[3]);
			
			$unique_between_id_counter++;
			$interactor_between_unique_ids{$cols[3]} = $unique_between_id_counter;
			# Columns:
			# id, pacA, proteinA, geneA, isoformsA, node_labelA, 
			# uniprot_idA, uniprot_geneA, short_nameA, long_nameA, is source
			$nodeBetweenXml .= 
					printNodeXml($interactor_between_unique_ids{$cols[3]}, $cols[3], 
					$cols[5], $cols[7], $cols[15], $node_label, $cols[17], $cols[19], 
					$cols[21], $cols[23], $is_source, \%node_mapper);		
			if( $produce_graphml )
			{					
				$nodeBetweenGraphml .= 
					printNodeGraphml($unique_between_id_counter, $cols[3]);
			}
		}	
		# register new node (right hand) if not seen before
		if (not exists $interactor_between_unique_ids{$cols[4]})
		{
			my $is_source = ($input_interactors{$colB} ? "y" : "n");
			my $node_label = generate_node_label(\@cols, $labels, $cols[4]);
			
			$unique_between_id_counter++;
			$interactor_between_unique_ids{$cols[4]} = $unique_between_id_counter;
			# Columns:
			# id, pacB, proteinB, geneB, isoformsB, node_labelB, uniprot_idB, 
			# uniprot_geneB, short_nameB, long_nameB, is source
			$nodeBetweenXml .= 
					printNodeXml($interactor_between_unique_ids{$cols[4]}, $cols[4], 
					$cols[6], $cols[8], $cols[16], $node_label, $cols[18], $cols[20], 
					$cols[22], $cols[24], $is_source, \%node_mapper);	
			if( $produce_graphml )
			{					
				$nodeBetweenGraphml .= 
					printNodeGraphml($unique_between_id_counter, $cols[4]);
			}								
		}
		# at this stage we need to create a new id for the interaction we are parsing
		$unique_between_id_counter++;
		my $edge_id = $unique_between_id_counter;
	
	
		# Handle xml edge record				
		my $source_id = $interactor_between_unique_ids{$cols[3]};
		my $target_id = $interactor_between_unique_ids{$cols[4]};
		
		
		# edge_id, source_id, target_id, 
		# interaction_type, interaction, edge_type,
		# edge_tooltips, edge_methods, edge_classes, 
		# edge_evidence, edge_evidence_other, edge_providers, 
		# pacA, proteinA, geneA, uniprot_idA, uniprot_geneA, 
		# pacB, proteinB, geneB, uniprot_idB, uniprot_geneB
		$edgeBetweenXml .= 
				printEdgeXml(	$edge_id, $source_id, $target_id, 
								$cols[0], $cols[1], $cols[2], 
								$cols[9], $cols[10], $cols[11], 
								$cols[12], $cols[13],  $cols[14],
					 			# interactorA attributes
								$cols[3], $cols[5], $cols[7], $cols[17], $cols[19],
								 # interactorB attributes
								$cols[4], $cols[6], $cols[8], $cols[18], $cols[20]
					);
					
		if( $produce_graphml )
		{					
			next if (exists $established_interactions_graphml{$cols[3] . "_" . $cols[4]});
			$established_interactions_graphml{$cols[3] . "_" . $cols[4]}++;	
			$established_interactions_graphml{$cols[4] . "_" . $cols[3]}++;	
			$edgeBetweenGraphml .= 
					printEdgeGraphml($source_id, $target_id);
					
		}				
	}
	
	# Handle first neighbour interaction
	if (not exists $interactor_unique_ids{$cols[3]})
	{
		my $is_source = ($input_interactors{$colA} ? "y" : "n");
		my $node_label = generate_node_label(\@cols, $labels, $cols[3]);
			
		$unique_id_counter++;
		$interactor_unique_ids{$cols[3]} = $unique_id_counter;
		# Columns:
		# id, pacA, proteinA, geneA, isoformsA, node_labelA, uniprot_idA, uniprot_geneA, 
		# short_nameA, long_nameA, is source
		$nodeXml .= 
				printNodeXml($interactor_unique_ids{$cols[3]}, $cols[3], $cols[5], 
							$cols[7], $cols[15], $node_label, $cols[17], $cols[19], 
							$cols[21], $cols[23], $is_source, \%node_mapper);					
		if( $produce_graphml )
		{					
			$nodeGraphml .= 
				printNodeGraphml($unique_id_counter, $cols[3]);
		}						
	}
	# register new node (right hand) if not seen before
	if (not exists $interactor_unique_ids{$cols[4]})
	{
		my $is_source = ($input_interactors{$colB} ? "y" : "n");
		my $node_label = generate_node_label(\@cols, $labels, $cols[4]);
		
		$unique_id_counter++;
		$interactor_unique_ids{$cols[4]} = $unique_id_counter;
		# Columns:
		# id, pacB, proteinB, geneB, isoformsB, node_nameB, uniprot_idB, uniprot_geneB, 
		# short_nameB, long_nameB, is source
		$nodeXml .= 
				printNodeXml($interactor_unique_ids{$cols[4]}, $cols[4], $cols[6], 
							$cols[8], $cols[16], $node_label, $cols[18], $cols[20], 
							$cols[22], $cols[24], $is_source, \%node_mapper);
		if( $produce_graphml )
		{					
			$nodeGraphml .= 
				printNodeGraphml($unique_id_counter, $cols[4]);
	
		}										
	}
	# at this stage we need to create a new id for the interaction we are parsing
	$unique_id_counter++;
	my $edge_id = $unique_id_counter;
		
	# Handle xml edge record				
	my $source_id = $interactor_unique_ids{$cols[3]};
	my $target_id = $interactor_unique_ids{$cols[4]};
	
	# edge_id, source_id, target_id, 
	# interaction_type, interaction, edge_type,
	# edge_tooltips, edge_methods, edge_classes, 
	# edge_evidence, edge_evidence_other, edge_providers, 
	# pacA, proteinA, geneA, uniprot_idA, uniprot_geneA, 
	# pacB, proteinB, geneB, uniprot_idB, uniprot_geneB
	$edgeXml .= 
				printEdgeXml(	$edge_id, $source_id, $target_id, 
								$cols[0], $cols[1], $cols[2], 
								$cols[9], $cols[10], $cols[11], 
								$cols[12], $cols[13],  $cols[14],
					 			# interactorA attributes
								$cols[3], $cols[5], $cols[7], $cols[17], $cols[19],
								 # interactorB attributes
								$cols[4], $cols[6], $cols[8], $cols[18], $cols[20]
		);
	
	if( $produce_graphml )
	{			
		next if (exists $established_interactions_graphml{$cols[3] . "_" . $cols[4]});
		$established_interactions_graphml{$cols[3] . "_" . $cols[4]}++;
		$established_interactions_graphml{$cols[4] . "_" . $cols[3]}++;
		$edgeGraphml .= 
					printEdgeGraphml($source_id, $target_id);

	}					
}

# scan interactome for matrix interactions:
unless($all_interactors_flag)
{
	# reset filehandle:
	seek INT, 0, 0;
	my %established_interactions_xml = ();
	while(defined(my $line = <INT>))
	{
		chomp($line);
		my @cols = split(/\t/, $line);
	
		my $colA;
		my $colB;
	
	
		# Filter out interaction types we are not interested in
		my ($type) = $cols[0];
		next unless(exists $interaction_types{$type});
	
		# Define what columns the identifiers interrogate based on interactor_type input
		if ($interactor_type eq 'pac') # This is the default
		{
			($colA) = $cols[3];
			($colB) = $cols[4];
		}
		elsif ($interactor_type eq 'uniprot_id')
		{
			($colA) = $cols[17];
			($colB) = $cols[18];
		}
		else # interactor_type is gene
		{
			($colA) = $cols[7];
			($colB) = $cols[8];
		}
	
		# Continue only if BOTH identifiers for the specified interactor_type exist
		next unless($colA && $colB);
	
		#we have already encountered this interaction:
		next if(exists $established_interactions_xml{$colA . 
											" (" . $type . ") " . $colB});
		
	
		# Skip lines where either or both interactors are in the --interactor_list or
		# the --interactor_file, as these have been processed already: 
		next if( ( exists $input_interactors{$colA} )  || 
						( exists $input_interactors{$colB} ) );
		
		# Continue only if both interactors have been identified as first
		# neighbours of the user input interactor list/file:	
		next unless(exists $interactor_unique_ids{$cols[3]} && 
							exists $interactor_unique_ids{$cols[4]});
	
		if ($no_loops)
		{
			next unless ( $interactor_unique_ids{$cols[3]} ne 
									$interactor_unique_ids{$cols[4]});
		}
		
		# at this stage we need to create a new id for the interaction we are parsing
		$unique_id_counter++;
		my $edge_id = $unique_id_counter;
		
		# Handle xml edge record				
		my $source_id = $interactor_unique_ids{$cols[3]};
		my $target_id = $interactor_unique_ids{$cols[4]};
		
		# edge_id, source_id, target_id, 
		# interaction_type, interaction, edge_type,
		# edge_tooltips, edge_methods, edge_classes, 
		# edge_evidence, edge_evidence_other, edge_providers, 
		# pacA, proteinA, geneA, uniprot_idA, uniprot_geneA, 
		# pacB, proteinB, geneB, uniprot_idB, uniprot_geneB
		$edgeMatrixXml .= 
				printEdgeXml(	$edge_id, $source_id, $target_id, 
								$cols[0], $cols[1], $cols[2], 
								$cols[9], $cols[10], $cols[11], 
								$cols[12], $cols[13],  $cols[14],
					 			# interactorA attributes
								$cols[3], $cols[5], $cols[7], $cols[17], $cols[19],
								 # interactorB attributes
								$cols[4], $cols[6], $cols[8], $cols[18], $cols[20]
			);
		$established_interactions_xml{$colA . " (" . $type . ") " . $colB}++;	
		
		if( $produce_graphml )
		{			
			next if ($established_interactions_graphml{$cols[3] . "_" . $cols[4]});
			$established_interactions_graphml{$cols[3] . "_" . $cols[4]}++;
			$established_interactions_graphml{$cols[4] . "_" . $cols[3]}++;
			$edgeMatrixGraphml .= 
				printEdgeGraphml($source_id, $target_id);	
		}				
	}	

	close(INT);
}
# Print generated networks:
print XML $nodeXml;
print XML $edgeXml;
print XML "</graph>\n";
close(XML);

print BETWXML $nodeBetweenXml;
print BETWXML $edgeBetweenXml;
print BETWXML "</graph>\n";
close(BETWXML);

print MATRIXXML $nodeXml;
print MATRIXXML $edgeXml;
print MATRIXXML $edgeMatrixXml;
print MATRIXXML "</graph>\n";
close(MATRIXXML);

if ( $produce_graphml )
{
	print GRAPHML $nodeGraphml;
	print GRAPHML $edgeGraphml;
	print GRAPHML "</graph>\n</graphml>\n";
	close(GRAPHML);

	print BETWGRAPHML $nodeBetweenGraphml;
	print BETWGRAPHML $edgeBetweenGraphml;
	print BETWGRAPHML "</graph>\n</graphml>\n";
	close(BETWGRAPHML);

	print MATRIXGRAPHML $nodeGraphml;
	print MATRIXGRAPHML $edgeGraphml;
	print MATRIXGRAPHML $edgeMatrixGraphml;
	print MATRIXGRAPHML "</graph>\n</graphml>\n";
	close(MATRIXGRAPHML);
}

##########################################################################################
#
#	FUNCTIONS
#
##########################################################################################

sub printEdgeGraphml($$)
{
	my ($source_id, $target_id) = @_;
			
	
	my $edgetext = "\t<edge source=\"" . $source_id . 
			"\" target=\"" . $target_id . "\"/>\n";
	return $edgetext;
}		


sub printEdgeXml($$$$$$$$$$$$$$$$$$$$$$)
{
	my ($edge_id, $source_id, $target_id, 
		$interaction_type, $interaction, $edge_type,
		$edge_tooltips, $edge_methods, $edge_classes, 
		$edge_evidence, $edge_evidence_other, $edge_providers, 
		$pacA, $proteinA, $geneA, $uniprot_idA, $uniprot_geneA, 
		$pacB, $proteinB, $geneB, $uniprot_idB, $uniprot_geneB) = @_;
			
	

	#xmlise
	$edge_tooltips =~ s/&/&amp;/g;
	$edge_methods =~ s/&/&amp;/g;
	$edge_classes =~ s/&/&amp;/g;
	$edge_evidence =~ s/&/&amp;/g;
	$edge_evidence_other =~ s/&/&amp;/g;
	$edge_providers =~ s/&/&amp;/g;
	$edge_type =~ s/&/&amp;/g;		
	$edge_tooltips =~ s/"/&quot;/g;
	$edge_methods =~ s/"/&quot;/g;
	$edge_classes =~ s/"/&quot;/g;
	$edge_evidence =~ s/"/&quot;/g;
	$edge_evidence_other =~ s/"/&quot;/g;
	$edge_providers =~ s/"/&quot;/g;
	$edge_type =~ s/>/&gt;/g;
	$edge_type =~ s/</&lt;/g;
	$interaction =~ s/>/&gt;/g;
	$interaction =~ s/</&lt;/g;
	my $edgetext = "";
	
	my $isdirected = 1;
	if ($interaction_type eq 'direct' || 
		$interaction_type eq 'complex' || 
		$interaction_type eq 'complex_low')
	{
		$isdirected = 0;
	}
	
	my ($interaction_description) =  $interaction =~ /^\S+\s+(.*)\s+\S+$/;
	
	# Construct a gene interactor descriptor
	my $interaction_gene;
	if ($uniprot_geneA)
	{
		$interaction_gene = $uniprot_geneA;
	}
	elsif($geneA)
	{
		$interaction_gene = $geneA;
	}
	elsif($uniprot_idA)
	{
		$interaction_gene = $uniprot_idA;
	}
	else 
	{
		$interaction_gene = $pacA;
	}
	$interaction_gene .= " $interaction_description ";
	if ($uniprot_geneB)
	{
		$interaction_gene .= $uniprot_geneB;
	}
	elsif($geneB)
	{
		$interaction_gene .= $geneB;
	}
	elsif($uniprot_idB)
	{
		$interaction_gene .= $uniprot_idB;
	}
	else 
	{
		$interaction_gene .= $pacB;
	}
	
	# Construct a protein interaction descriptor
	my $interaction_protein;
	
	if ($proteinA)
	{
		$interaction_protein = $proteinA;
	}
	elsif($uniprot_idA)
	{
		$interaction_protein = $uniprot_idA;
	}
	else 
	{
		$interaction_protein = $pacA;
	}
	$interaction_protein .= " $interaction_description ";
	if ($proteinB)
	{
		$interaction_protein .= $proteinB;
	}
	elsif($uniprot_idB)
	{
		$interaction_protein .= $uniprot_idB;
	}
	else 
	{
		$interaction_protein .= $pacB;
	}
		
	# Make sure that we don't have udefined values:
	$geneA = "" unless($geneA);
	$proteinA = "" unless($proteinA);
	$uniprot_geneA = "" unless($uniprot_geneA);
	$uniprot_idA = "" unless($uniprot_idA);
	
	$geneB = "" unless($geneB);
	$proteinB = "" unless($proteinB);
	$uniprot_geneB = "" unless($uniprot_geneB);
	$uniprot_idB = "" unless($uniprot_idB);
	
	
	$edgetext .= "\t<edge id=\"" . $edge_id . "\" label=\"" . $interaction . 
				"\" source=\"" . $source_id . "\" target=\"" . $target_id . 
				"\" cy:directed=\"" . $isdirected . "\">\n";
	$edgetext .="\t\t<att name=\"name\" value=\"" . $interaction .
				 "\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"selected\" value=\"0\" type=\"boolean\"/>\n";
	$edgetext .="\t\t<att name=\"interaction_pac\" value=\"" . $interaction .
				 "\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"interaction_gene\" value=\"" . $interaction_gene .
				 "\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"interaction_protein\" value=\"" . $interaction_protein .
				 "\" type=\"string\"/>\n";			 			 
	$edgetext .="\t\t<att name=\"EDGE_TYPE\" value=\"". $edge_type .
				"\" type=\"string\"/>\n";
				
	$edgetext .="\t\t<att name=\"PAC_A\" value=\"". $pacA .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"Protein_A\" value=\"". $proteinA .
				"\" type=\"string\"/>\n";			
	$edgetext .="\t\t<att name=\"Gene_A\" value=\"". $geneA .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"UniProtID_A\" value=\"". $uniprot_idA .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"UniProtGene_A\" value=\"". $uniprot_geneA .
				"\" type=\"string\"/>\n";
				
	$edgetext .="\t\t<att name=\"PAC_B\" value=\"". $pacB .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"Protein_B\" value=\"". $proteinB .
				"\" type=\"string\"/>\n";	
	$edgetext .="\t\t<att name=\"Gene_B\" value=\"". $geneB .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"UniProtID_B\" value=\"". $uniprot_idB .
				"\" type=\"string\"/>\n";
	$edgetext .="\t\t<att name=\"UniProtGene_B\" value=\"". $uniprot_geneB .
				"\" type=\"string\"/>\n";			
				
													
	$edgetext .="\t\t<att name=\"edge_tooltip\" type=\"list\">\n";
	my @edge_tooltip_array = split(/\|/, $edge_tooltips);
	if (@edge_tooltip_array)
	{
		foreach my $edge_tooltip (@edge_tooltip_array)
		{
			$edgetext .= "\t\t\t<att name=\"edge_tooltip\" value=\"" . $edge_tooltip . 
						"\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"edge_tooltip\" value=\"\" type=\"string\"/>\n";
	}

	$edgetext .= "\t\t</att>\n";

	$edgetext .= "\t\t<att name=\"method\" type=\"list\">\n";
	my @method_array = split(/\|/, $edge_methods);
	if (@method_array)
	{
		foreach my $method (@method_array)
		{
			$edgetext .= "\t\t\t<att name=\"method\" value=\"" . $method . 
						"\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"method\" value=\"\" type=\"string\"/>\n";
	}
	$edgetext .= "\t\t</att>\n";
	
	my @class_array = split(/\|/, $edge_classes);
	$edgetext .= "\t\t<att name=\"class\" type=\"list\">\n";
	if (@class_array)
	{
		foreach my $class (@class_array)
		{
			$edgetext .= "\t\t\t<att name=\"class\" value=\"" . $class .
						 "\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"class\" value=\"\" type=\"string\"/>\n";
	}
	$edgetext .="\t\t</att>\n";


	my @evidence_array = split(/\|/, $edge_evidence);
	$edgetext .= "\t\t<att name=\"evidence\" type=\"list\">\n";
	if (@evidence_array)
	{
		foreach my $evidence (@evidence_array)
		{
			$edgetext .= "\t\t\t<att name=\"evidence\" value=\"" . $evidence . 
							"\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"evidence\" value=\"\" type=\"string\"/>\n";
	}
	$edgetext .="\t\t</att>\n";
	
	
	my @evidence_other_array = split(/\|/, $edge_evidence_other);
	$edgetext .= "\t\t<att name=\"evidence_other\" type=\"list\">\n";
	if (@evidence_other_array)
	{
		foreach my $evidence (@evidence_other_array)
		{
			$edgetext .= "\t\t\t<att name=\"evidence_other\" value=\"" . $evidence . 
							"\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"evidence_other\" value=\"\" type=\"string\"/>\n";
	}
	$edgetext .="\t\t</att>\n";
	
	my @provider_array = split(/\|/, $edge_providers);
	$edgetext .= "\t\t<att name=\"provider\" type=\"list\">\n";
	if (@provider_array)
	{
		foreach my $provider (@provider_array)
		{
			$edgetext .= "\t\t\t<att name=\"provider\" value=\"" . $provider . 
						"\" type=\"string\"/>\n";
		}
	}
	else
	{
		$edgetext .=
			"\t\t\t<att name=\"provider\" value=\"\" type=\"string\"/>\n";
	}
	$edgetext .="\t\t</att>\n\t</edge>\n";	
	#print $edgetext . "\n\n";
	return $edgetext;
}		

sub printNodeGraphml($$)
{
	my ($node_id, $pac) = @_;
	my $nodetext = "\t<node id=\"" . $node_id . "\">\n" .
    			"\t\t<data key=\"pac\">" . $pac . "</data>\n" .
    			"\t\t<data key=\"weight\">1.0</data>\n" .		#modify to add real value
    			"\t</node>\n";

	return $nodetext;
}

sub printNodeXml($$$$$$$$$$$$)
{
	my ($node_id, $pac, $protein, $gene, $isoforms, $node_label, 
		$uniprot_id, $uniprot_gene, $short_name, $long_name, 
		$is_source, $node_mapper) = @_;
		
	
	my $nodetext = "";
	
	my @isoform_array = split(/\|/, $isoforms); 
	my @protein_shorts = split(/\|/, $short_name);

	$nodetext = "\t<node id=\"" . $node_id . "\" label=\"" . $pac . "\">\n";
	
	$nodetext .="\t\t<att name=\"pac\" value=\"" . $pac . "\" type=\"string\"/>\n";
	
	$nodetext .="\t\t<att name=\"selected\" value=\"0\" type=\"boolean\"/>\n";
	
	$nodetext .="\t\t<att name=\"protein\" value=\"" . 
				($protein ? $protein : "") . "\" type=\"string\"/>\n";
				
	
		$nodetext .="\t\t<att name=\"gene\" type=\"list\">\n";
		my @genes = split(/\|/, $gene);
		if (@genes)
		{
			foreach my $gene_name (@genes)
			{
				$nodetext .="\t\t\t<att name=\"gene\" value=\"" . 
						$gene_name . "\" type=\"string\"/>\n";
			}
		}
		else
		{
			$nodetext .="\t\t\t<att name=\"gene\" value=\"\" type=\"string\"/>\n";
		}			
		$nodetext .= "\t\t</att>\n";
					
				
	if(exists $node_mapper->{'map'})
	{	
		$nodetext .="\t\t<att name=\"EntrezGene\" type=\"list\">\n";
		my @entrezs = split(/\|/, $node_mapper->{'map'}{$pac}[2]);
		if (@entrezs)
		{
			foreach my $entrez (@entrezs)
			{
				$nodetext .="\t\t\t<att name=\"EntrezGene\" value=\"" . 
						$entrez . "\" type=\"string\"/>\n";
			}
		}
		else
		{
			$nodetext .="\t\t\t<att name=\"EntrezGene\" value=\"\" type=\"string\"/>\n";
		}			
		$nodetext .= "\t\t</att>\n";
	}	
				
	$nodetext .="\t\t<att name=\"node_label\" value=\"" . 
				$node_label . "\" type=\"string\"/>\n";
				
	$nodetext .="\t\t<att name=\"uniprot_id\" value=\"" . 
				($uniprot_id ? $uniprot_id : "") . "\" type=\"string\"/>\n";
				
	$nodetext .="\t\t<att name=\"uniprot_gene\" value=\"" . 
				($uniprot_gene ? $uniprot_gene : "") . "\" type=\"string\"/>\n";
				

	$nodetext .="\t\t<att name=\"long_name\" value=\"" . 
				($long_name ? $long_name : "") . "\" type=\"string\"/>\n";
				
	$nodetext .="\t\t<att name=\"is_source\" value=\"" . 
				($is_source ? $is_source : "n") .  "\" type=\"string\"/>\n";
				
	if(exists $node_mapper->{'map'})
	{	
		$nodetext .="\t\t<att name=\"SAC\" type=\"list\">\n";
		my @sacs = split(/\|/, $node_mapper->{'map'}{$pac}[3]);
		if (@sacs)
		{
			foreach my $sac (@sacs)
			{
				$nodetext .="\t\t\t<att name=\"SAC\" value=\"" . 
						$sac . "\" type=\"string\"/>\n";
			}
		}
		else
		{
			$nodetext .="\t\t\t<att name=\"SAC\" value=\"\" type=\"string\"/>\n";
		}			
		$nodetext .= "\t\t</att>\n";
	}	
	
	if(exists $node_mapper->{'map'})
	{	
		$nodetext .="\t\t<att name=\"EC_code\" type=\"list\">\n";
		my @ec_codes = split(/\|/, $node_mapper->{'map'}{$pac}[4]);
		if (@ec_codes)
		{
			foreach my $ec_code (@ec_codes)
			{
				$nodetext .="\t\t\t<att name=\"EC_code\" value=\"" . 
						$ec_code . "\" type=\"string\"/>\n";
			}
		}
		else
		{
			$nodetext .="\t\t\t<att name=\"EC_code\" value=\"\" type=\"string\"/>\n";
		}			
		$nodetext .= "\t\t</att>\n";
	}
	
	if(exists $node_mapper->{'map'})
	{
		$nodetext .="\t\t<att name=\"enzyme_type\" type=\"list\">\n";
		my @enzyme_types = split(/\|/, $node_mapper->{'map'}{$pac}[5]);
		if (@enzyme_types)
		{
			foreach my $enzyme_type (@enzyme_types)
			{
				$nodetext .="\t\t\t<att name=\"enzyme_type\" value=\"" . 
						$enzyme_type . "\" type=\"string\"/>\n";
			}
		}
		else
		{
			$nodetext .="\t\t\t<att name=\"enzyme_type\" value=\"\" type=\"string\"/>\n";
		}			
		$nodetext .= "\t\t</att>\n";
	}
		
							
	$nodetext .="\t\t<att name=\"Synonyms\" type=\"list\">\n";
	if (@protein_shorts)
	{
		foreach my $synonym (@protein_shorts)
		{
			$nodetext .="\t\t\t<att name=\"Synonyms\" value=\"" . 
						$synonym . "\" type=\"string\"/>\n";
		}
	}
	else
	{
		$nodetext .="\t\t\t<att name=\"Synonyms\" value=\"\" type=\"string\"/>\n";
	}			
	$nodetext .= "\t\t</att>\n";			
			
	$nodetext .="\t\t<att name=\"isoforms\" type=\"list\">\n";
	if (@isoform_array)
	{
		foreach my $isoform (@isoform_array)
		{
			$nodetext .="\t\t\t<att name=\"isoforms\" value=\"" . 
						$isoform . "\" type=\"string\"/>\n";
		}
	}
	else
	{
		$nodetext .="\t\t\t<att name=\"isoforms\" value=\"\" type=\"string\"/>\n";
	}
	$nodetext .= "\t\t</att>\n\t</node>\n";
	#print $nodetext . "\n\n";
	return $nodetext;
}

sub generateXmlHeader($$)
{
	my ($networkName, $currentTime) = @_;
	my $xml_header = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<graph id=\"1\" label=\"" . $networkName . "\" directed=\"1\" cy:documentVersion=\"3.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:cy=\"http://www.cytoscape.org\" xmlns=\"http://www.cs.rpi.edu/XGMML\">\n";
	$xml_header .="\t<att name=\"networkMetadata\">\n";
	$xml_header .="\t<rdf:RDF>\n";
	$xml_header .="\t\t<rdf:Description rdf:about=\"http://www.cytoscape.org/\">\n";
	$xml_header .="\t\t<dc:type>Protein-Protein Interaction</dc:type>\n";
	$xml_header .="\t\t<dc:description>N/A</dc:description>\n";
	$xml_header .="\t\t <dc:identifier>N/A</dc:identifier>\n";
	$xml_header .="\t\t <dc:date>" . $currentTime . "</dc:date>\n";
	$xml_header .="\t\t<dc:title>" . $networkName . "</dc:title>\n";
	$xml_header .="\t\t <dc:source>http://www.cytoscape.org/</dc:source>\n";
	$xml_header .="\t\t  <dc:format>Cytoscape-XGMML</dc:format>\n";
	$xml_header .="\t\t</rdf:Description>\n";
	$xml_header .="\t\t</rdf:RDF>\n";
	$xml_header .="\t</att>\n";
	$xml_header .="\t<att name=\"name\" value=\"" . $networkName .
					"\" type=\"string\"/>\n";
	$xml_header .="\t<att name=\"selected\" value=\"1\" type=\"boolean\"/>\n";
	$xml_header .="\t<att name=\"__Annotations\" type=\"list\">\n";
	$xml_header .="\t\t<att name=\"__Annotations\" value=\"\" type=\"string\"/>\n";
	$xml_header .="\t</att>\n";
	return $xml_header;
}

sub generateGraphmlHeader($)
{
	my ($networkName) = shift @_;
	my $xml_header ="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" .
		"<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"\n" .
    	"xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n" .
    	"xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns\n" .
    	"http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n" .
    	"\t<key id=\"pac\" for=\"node\" attr.name=\"pac\" attr.type=\"string\">\n" .
  		"\t\t<default>NA</default>\n" .
  		"\t</key>\n" .
  		"\t<key id=\"weight\" for=\"node\" attr.name=\"weight\" attr.type=\"float\">\n" .
  		"\t\t<default>1.0</default>\n" .
  		"\t</key>\n" .
  		"\t<graph id=\"" . $networkName . "\" edgedefault=\"undirected\">\n";

	return $xml_header;
}

sub generate_node_label($$$)
{
	my ($cols_ref, $nodes, $pac) = @_;
	#print join('|||-', @$cols_ref) . "\n";
	#print $nodes . "\n";
	my $node_label;
	
	if($nodes eq 'protein')
	{
		if($pac eq $cols_ref->[3])
		{
			if($cols_ref->[5] && $cols_ref->[5] ne '') # protein
			{
				$node_label = $cols_ref->[5];
			}
			elsif($cols_ref->[7] && $cols_ref->[7] ne '') # gene
			{
				$node_label = $cols_ref->[7];
			}
		}
		elsif($pac eq $cols_ref->[4])
		{
			if($cols_ref->[6] && $cols_ref->[6] ne '') # protein
			{
				$node_label = $cols_ref->[6];
			}
			elsif($cols_ref->[8] && $cols_ref->[8] ne '') # gene
			{
				$node_label = $cols_ref->[8];
			}
		}
			
	}
	elsif($nodes eq 'gene')
	{
		if($pac eq $cols_ref->[3])
		{
			if($cols_ref->[7] && $cols_ref->[7] ne '') # protein
			{
				$node_label = $cols_ref->[7];
			}
			elsif($cols_ref->[5] && $cols_ref->[5] ne '') # gene
			{
				$node_label = $cols_ref->[5];
			}
		}
		elsif($pac eq $cols_ref->[4])
		{
			if($cols_ref->[8] && $cols_ref->[8] ne '') # protein
			{
				$node_label = $cols_ref->[8];
			}
			elsif($cols_ref->[6] && $cols_ref->[6] ne '') # gene
			{
				$node_label = $cols_ref->[6];
			}
		}
	}
	unless($node_label) # fall back if neither protein or gene names defined
	{
		if($pac eq $cols_ref->[3])
		{
			if($cols_ref->[17] && $cols_ref->[17] ne '') # uniprot_id
			{
				$node_label = $cols_ref->[17];
			}
			else # pac
			{
				$node_label = $cols_ref->[3];
			}
		}	
		elsif($pac eq $cols_ref->[4])
		{
			if($cols_ref->[18] && $cols_ref->[18] ne '') # uniprot_id
			{
				$node_label = $cols_ref->[18];
			}
			else # pac
			{
				$node_label = $cols_ref->[4];
			}
		}	
	}
	#print $node_label . "\n\n";
	return $node_label;
}

sub init()
{
	# Validate input options

	# print usage message if requested
	if(defined($help)) 
	{
		&usage;
		exit(0);
	}

	# Check that interactome file was provided and that it exists:
	if(defined($input_interactome_file))
	{
		unless(-e $input_interactome_file)
		{
			print "Input interactome file does not exist.\n";
			&usage;
			exit(0);
		}
	}
	else
	{
		print "Input interactome file was not supplied.\n";
		&usage;
		exit(0);
	}

	unless(defined($out_file))
	{
		print "Output file was not supplied.\n";
		&usage;
		exit(0);
	}

	# Interactor list logic:
	unless(defined($input_interactor_file) || defined($input_interactor_list))
	{
		print "No --interactor_file or --interactor_list " .
				"specified: Using all interactors\n";
		$all_interactors_flag = 1;
	}

	# Interactor type logic:
	if($interactor_type)
	{
		unless($interactor_type eq 'pac' || $interactor_type eq 'uniprot_id' ||
				$interactor_type eq 'gene')
		{
			print "Please specify whether interactors are supplied as " . 
					"type gene, pac, or uniprot_id\n";
			&usage;
			exit(0);	
		}
	}
	else
	{
		print "Using primary accession identifiers for interactors\n";
		$interactor_type = 'pac';
	}

	# Node label logic:
	if($labels)
	{
		if($labels eq 'protein')
		{
			print "Using protein identifiers for node labels\n";
		}
		elsif($labels eq 'gene')
		{
			print "Using gene identifiers for node labels\n";
		}
		else
		{
			print "Please specify whether node labels will be gene" .
					" or protein names\n";
			&usage;
			exit(0);
		}
	}
	else
	{
		if($interactor_type eq 'pac' || $interactor_type eq 'uniprot_id')
		{
			$labels = 'protein';
			print "Using protein names for node labels\n";
		}
		elsif($interactor_type eq 'gene')
		{
			$labels = 'gene';
			print "Using gene names for node labels\n";
		}
	}

	# Interaction types logic:		
	unless(defined($interaction_types))
	{
		print "All types of interaction will be used (reactome, "
				. "trx, direct, reaction, complex and complex_low)\n";
		$interaction_types = 'all'; 
	}

	if($produce_graphml)
	{
		print "Will generate graphml files for R\n";
	}
}	
		
sub usage() 
{
	my $usage =<<END;
#------------------------------------#
# subset_interactome.pl  #
#------------------------------------#

By Costas Mitsopoulos (kmitsopoulos\@icr.ac.uk)

Usage:
perl subset_interactome.pl [arguments]

OPTIONS

--help                 Display this message and quit
--interactome_file     Interactions flat text file         [Required]
--out_file             File to write subset interactions   [Required]

--interactor_file       File containing interactors        
	or
--interactor_list      Comma separated list of interactors   
					   If neither are specified, use all nodes
         
--interactor_type       pac [default], uniprot_id or gene 

--labels					protein or gene
						If neither are specified:
							protein if interactor_type is pac or uniprot_id
							gene if interactor_type is gene                       

--interaction_types     Comma separated list of interaction types from:
						reactome, trx, direct, 
						reaction, complex, complex_low
						If not set, all types will be used  
						
--no_loops				flag to filter out self interactions 
						(due to Cytoscape 3 associated glitches)						
						
--name					name of network	
	
--graphml				if set, graphml networks will also be generated	

--weights				File containing weights for nodes
				          
END

	print $usage;
}
		
