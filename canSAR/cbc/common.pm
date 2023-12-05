package cbc::common;

use strict;
use warnings;
use Data::Dumper;
use Carp('confess');
use Capture::Tiny ':all';
use Digest::MD5 qw(md5_hex);
use FindBin qw($Script);
use PDL;
use Proc::ProcessTable;
use List::MoreUtils;
use File::Path qw( mkpath );
use JSON;
use Net::OpenSSH;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(system chdir chdir_to_script env_map schema_map get_schema remote_run remote_path_exists);


sub convert_env_into_target_list {
	my $schema = shift;
	my $env = shift;
	#print Dumper($schema);
	my $envs = [];
	
	if ($env eq 'all') {
		if ($schema eq 'expression') {
			$envs = [qw(dev-jtym prod)];
		}
		else {
			$envs = [qw(dev-jtym update staging prod)];
		}
	}
	else {
		$envs = [$env];
	}

	my @target_list = ();
	
	foreach my $env (@$envs) {
		my $hosts = cbc::common::env_map($env);

		foreach my $host (@$hosts) {
			my $schema_real = $schema;
			if ($schema ne 'expression') {
				$schema_real = cbc::common::schema_map($schema, $env);
			}
			push @target_list, [$host, $schema_real, $env];
		}
	}

	return \@target_list;
}

sub schema_map {
	my $schema = shift;
	my $env = shift;
	$schema = lc($schema);
	$env = lc($env);

	#dev => 'cansar3d_dev',
	my $data = {
		cansar3d => {
			'dev-jtym' => 'cansar3d_dev',
			'dev-pmicco' => 'cansar3d_dev',
			update => 'update_cansar3d',
			staging => 'staging_cansar3d',
			prod => 'cansar3d_user'
		},
		expression => {
			'dev-jtym' => 'expression',
			update => 'expression',
			staging => 'expression',
			prod => 'expression'
		},
		unichem => {
			'dev-jtym' => 'unichem',
			update => 'update_unichem',
			staging => 'staging_unichem',
			prod => 'unichem'
		},
		uniprot => {
			'dev-jtym' => 'uniprot',
			update => 'update_uniprot',
			staging => 'staging_uniprot',
			prod => 'uniprot'
		},
		cansar_internal => {
			'dev-jtym' => 'cansar_internal',
			update => 'update_cansar_internal',
			staging => 'staging_cansar_internal',
			prod => 'cansar_v2'
		},
		cansar_external => {
			'dev-jtym' => 'cansar_internal',
			update => 'update_cansar_external',
			staging => 'staging_cansar_external',
			prod => 'cansar_v2'
		},
		chembl => {
			'dev-jtym' => 'chembl_23'
		}
	};
	return $data->{$schema}->{$env} || die 'unrecognised input';;
}

sub env_map {
	my $input = shift;
	my $data = {
		'dev-jtym' => [qw(howl)],
		update => [qw(howl)],
		staging => [qw(howl)],
		prod => [qw(catbus canext3 canext4)]
	};
	return $data->{$input} || die 'unrecognised input';;
}

sub get_schema {
	if (!$ENV{env}) {
		die 'env environment variable needs to be set e.g. env=dev';
	}

	my $input = shift || die 'need input';
	return schema_map($input, $ENV{env});
}


# deprecated
sub get_latest_schema {
	my $key = shift;
	
	my $schemas = {
		'cansar3d_dev' => 'CANSAR3D_DEV',
		'cansar_internal_previous' => 'CANSAR_CHEMBL20I_1',
		'cansar_internal' => 'CANSAR_INTERNAL',
		'cansar_external' => 'CANSAR_EXTERNAL',
		'chembl' => 'CHEMBL_21'
	};

	die 'schema key is invalid '.$key if (!defined($schemas->{$key}));
	return $schemas->{$key};
}

sub get_dpdump_dir {
	my $host = shift || die 'need host';

	if (!defined($::dbhs->{$host})) {
		die 'invalid host';
	}
	
	my $sth = $::dbhs->{$host}->prepare("select * from dba_directories where directory_name like 'DATA_PUMP_DIR'");
	$sth->execute();
	if (my $row = $sth->fetchrow_hashref) {
		return $row->{DIRECTORY_PATH};
	}
}

sub get_path_for_env {
	my $input = shift || die 'blank input';
	#'dev' => '/san/data/pdb_data/env/dev-jtym',
	my $path = {
		'dev-jtym' => '/san/data/pdb_data/env/dev-jtym',
		'dev-pmicco' => '/san/data/pdb_data/env/dev-pmicco',
		'update' => '/san/data/pdb_data/env/update',
	}->{$input} || die 'unknown env';
}

sub get_dir {
	my $key = shift;
	
	my $dirs = {
		'cansar3d_pipeline' => '/san/USERS/KRISHNA/PDB/Scripts/LOAD_PDB_DATA/LOAD_DATA_SCRIPTS',
	};

	die 'dir key is invalid' if (!defined($dirs->{$key}));
	return $dirs->{$key};
}

sub get_target_host_list {
	my $key = shift || die 'need key';

	my $legacy_map = {
		'external' => 'production_external',
		'internal' => 'production_internal',
	};

	my $remapped_key = $legacy_map->{$key};

	if (defined($remapped_key)) {
		$key = $remapped_key;
	}

	my $lists = {
		'dev' => ['howl'],
		'all' => [ 'howl', 'catbus', 'canext4', 'canext3'],
		'production_all' => ['catbus', 'canext4', 'canext3'],
		'production_external' => ['canext4', 'canext3'],
		'production_internal' => ['catbus']
	};


	# assume host was passed if no match in groups
	if (!defined($lists->{$key})) {
		return [ $key ];
	}


	#if (!defined($lists->{$key})) {
	#	die "target host list key is invalid: $key";
	#}

	return $lists->{$key};
}















# move somewhere more generic
sub get_current_date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
	$year+=1900;
	$mon+=1;
	return sprintf("%02d-%02d-%02d %02d:%02d:%02d", ($year,$mon,$mday,$hour,$min,$sec));
}

sub fix_oracle_number {
	my $input = shift;
	if (!defined($input)) {
		die 'bad input '.$input;
	}

	$input =~ s/^\./0./;
	$input =~ s/^-\./-0./;
	return $input;
}









sub should_target_be_split_into_uniprots {
	my $target_type = shift;
	my $target = shift;
	my @exclude_list = ('TISSUE','PHENOTYPE','MACROMOLECULE','CELL-LINE','ORGANISM','SUBCELLULAR','UNKNOWN','SMALL MOLECULE','NUCLEIC-ACID');
	my @accessions = split(',', $target); 
	my $not_protein = grep { $_ eq $target_type } @exclude_list;

	# uniprot apparently have accessions which aren't 6 in length anymore
	if ((grep { length($_) != 6 } @accessions) || $not_protein) {
		return 0;
	}

	return 1;
}

sub get_best_compound_name {
	my $names = shift || die 'need names';
	my $data = {};

	foreach my $type (('CHEMICAL_PROBES_PORTAL', 'PREF_NAME', 'INN', 'TRADE_NAME', 'RESEARCH_CODE', 'USAN', 'SYNONYM', 'HET', 'OTHER', 'IUPAC')) {
		if (defined($names->{$type})) {
			my $preferred_name = $names->{$type}->[0];

			# names need cleaning whether they are preferred_names or not
			# PREF_NAME is sometimes also a research code so upper casing first letter isn't always advisable
			# a better approach here might be to only apply the upper casing if the string is all CAPS LETTERS
			if ((grep { $type eq $_ } ('PREF_NAME','INN','TRADE_NAME')) && $preferred_name !~ /[\d-]/) {
				$preferred_name = lc($preferred_name);
				$preferred_name =~ s/\b(\w)/\u$1/g;
			}
			
			$data->{'PREFERRED_NAME'} = $preferred_name;
			$data->{'PREFERRED_NAME_TYPE'} = $type;
			last;
		}
	}

	return $data;
}

sub get_host_list {
	my $hostname = `hostname -s`;
	chomp $hostname;


	my $hosts = {
		'canext' => ['canext'],
		'canext2' => ['canext2'],
		'calcifer' => [],
		'howl' => [
			'howl', 
			'catbus', 
			'canext3',
			'canext4'
			#need to add timeout
		],
		'catbus' => ['catbus']
	};

	return $hosts->{$hostname};
}

sub close_database_handles {
	my $hosts = get_host_list();

	foreach my $host (@$hosts) {
		if (defined($::dbhs->{$host})) {
			eval {
				$::dbhs->{$host}->disconnect or warn 'disconnect failed';
			};
		}
	}
	return;
}

sub setup_database_handles {
	my $hosts = get_host_list();

	foreach my $host (@$hosts) {
		#print Dumper($host);
		my $port = '1521';
		$port = '1523' if ($host eq 'canext2');

		my $connection_string = "dbi:Oracle:host=$host;sid=orcl;port=$port";
		$::dbhs->{$host} = DBI->connect( $connection_string, 'system', 'ore28gon',
		{  PrintError => 0, RaiseError => 1, AutoCommit => 1 } ) 
		|| die "Database connection not made: $DBI::errstr";

		$::dbhs->{$host}->{InactiveDestroy} = 1;
		$::dbhs->{$host}->{LongReadLen} = 1500000;
	}
	return;
}

sub cache_set {
	my $namespace = shift || die 'need namespace';
	my $key = shift || die 'need key';
	my $data = shift || die 'need data';
	my $internal = shift || die 'need internal';

	my $first_two = substr($key, 0, 2);

	if (length($key) le 2) {
		$first_two = 'le2';
	}

	my $cache_folder = "/san/TEMP/CANSAR/CACHE/$internal/$namespace/$first_two/";
	if (!-d $cache_folder) {
		mkpath($cache_folder);
	}

	my $path = $cache_folder.$key;

	#print Dumper($path);
	open (my $CACHE_FILE, ">", "$path") || die 'file error';

	if (!defined($::json)) {
		$::json = JSON->new->allow_nonref;
	}
	print $CACHE_FILE $::json->pretty->encode($data);
	close $CACHE_FILE;
}

sub get_and_cache {
	my $url = shift || die 'need url';
	my $option = shift || 'use_cache';
	my $url_hash = md5_hex($url);
	my $cache_path = '/san/data/jtym/url_cache/'.$url_hash;

	#print Dumper($cache_path);
	
	if (-e $cache_path && $option ne 'overwrite') {
		return `cat $cache_path`;
	}

	my $content = get_url($url);
	my $handle;
	open($handle, ">", "$cache_path") || die "file error $cache_path";
	print $handle $content;
	close $handle;
	return $content;
}

sub convert_target_type {
	my $input = shift;

	my $map = {
		'ADMET' => 'ADMET',
		'CHIMERIC PROTEIN' => 'PROTEIN',
		'PROTEIN COMPLEX' => 'PROTEIN',
		'PROTEIN COMPLEX GROUP' => 'PROTEIN',
		'PROTEIN FAMILY' => 'PROTEIN',
		'PROTEIN-PROTEIN INTERACTION' => 'PROTEIN',
		'SELECTIVITY GROUP' => 'PROTEIN',
		'SINGLE PROTEIN' => 'PROTEIN',
		'CHIMERIC PROTEIN' => 'PROTEIN',
		'CELL-LINE' => 'CELL_LINE',
		'ORGANISM' => 'ORGANISM'
	};

	if (defined($map->{$input})) {
		return $map->{$input};
	}
	else {
		return undef;
	}
}


=head1 get_target_key
	takes chembl result hashref as input
	returns target_key used to uniquely identify target in cansar
=cut

sub get_target_key {
	my $row = shift;
	my $target_key;
	my $target_key1;
	my $target_key2;
	my $cansar_target_type = convert_target_type($row->{TARGET_TYPE});


	if (!defined($cansar_target_type)) {
		return undef;
	}



	# might explain reduction in bioactivity count, alternative is we issue
	# non-specific tax_id and it can be associated accordingly
	#if ($cansar_target_type ne 'ADMET' && !defined($row->{TAX_ID})) {
	#	return undef;
	#}
	#
	#
	if (!defined($row->{TAX_ID})) {
		$row->{TAX_ID} = 9606;
	}


	if ($cansar_target_type eq 'CELL_LINE') {
		# call in passive mode
		my $result = cbc::common::match_sample2($row->{PREF_NAME}, 'cell-line', $row->{TAX_ID}, 0);
		# $match = $result->{result};
		#$target_key1 = $row->{TAX_ID};
		#print Dumper($result);
		$target_key1 = $row->{TAX_ID};
		$target_key2 = $result->{crushed_name};
	}
	elsif ($cansar_target_type eq 'PROTEIN') {
		$target_key1 = $row->{TAX_ID};
		$target_key2 = $row->{SEQUENCE_MD5SUM};
	}
	elsif ($cansar_target_type eq 'ORGANISM') {
		$target_key1 = $row->{TAX_ID};
		$target_key2 = $row->{ORGANISM};
	}
	elsif ($cansar_target_type eq 'ADMET') {
		$target_key1 = 1;
	}

	# catch unmappable targets
	if (!$target_key1) {
		return undef;
	}
	
	my @target_keys = ($target_key1);
	#print Dumper(\@target_keys);
	
	if ($target_key2) {
		push @target_keys, $target_key2;
	}
	
	return join('|', @target_keys);
}



sub get_target_id {
	my $schema = shift || die 'need schema';
	my $target_type = shift || die 'need target_type';
	my $target_key = shift || die 'need target_key';


	generic::datalayer->set_schema($schema);

	if (!defined($::targets)) {
		foreach my $table ('protein', 'target_other', 'experiment_subject') {
			my $where = $table;
			if ($table eq 'experiment_subject') {
				$where = "expression.experiment_subject where type like 'cell-line'";
			}


			my $sth = $::dbh->prepare("select * from $where");
			$sth->execute();

			while (my $row = $sth->fetchrow_hashref) {
				my $target_type = 'PROTEIN';
				#my $target_key = get_target_key($row);
				my $target_key;
	
				if (!defined($row->{TAX_ID})) {
					$row->{TAX_ID} = 9606;
				}

				if ($table eq 'protein') {
					$target_key = $row->{TAX_ID}.'|'.$row->{PROTEIN_MD5SUM};
					$target_type = 'PROTEIN';
				}
				elsif ($table eq 'target_other') {
					$target_key = $row->{TARGET_KEY1};
					if (defined($row->{TARGET_KEY2})) {
						$target_key.='|'.$row->{TARGET_KEY2};
					}
					$target_type = $row->{TARGET_TYPE};
				}
				elsif ($table eq 'experiment_subject') {
					$target_type = 'CELL_LINE';
					$target_key = $row->{TAX_ID}.'|'.$row->{PREFERRED_NAME};
				}

				$::targets->{$target_type}->{$target_key} = $row->{TARGET_ID};
			}
		}
	}

	return $::targets->{$target_type}->{$target_key};
}


sub process {
	my $index = shift;
	my $parent_id = shift;
	my $indent = shift;
	my $data = shift;


	my $list = $data->[$index]->{$parent_id};

	#print Dumper($list);
	foreach (@$list) {
		my ($x, $process_id, $parent_id, $y) = split(/\t/, $_);	
		my @values = split(/\t/, $_);
		$values[0] = '--' x $indent.$x;


		$values[0] = substr($values[0], 0, 32).'...' if (length($values[0]) > 32);


		# hack to add space lopped off start of line in e-mail
		#$values[0] = ' '.$values[0] if ($values[0] =~ /^ /);

		printf("%-35s %15s %15s %15s %15s\n", @values);
			
		#print Dumper(\@values, $index, $parent_id, $indent + 1); <STDIN>;
		process($index, $process_id, $indent + 1, $data);
	}
}

sub show_process_hierarchy_report {
	my $process_parent_id = getppid();	

	#print Dumper($parent_id);
	# to be moved to BEGIN,END block, if pid is either a shell, bash etc, or cron then:
	# a. reset all return code logging information at start
	# b. at the end print out a hierarchy of all the gathered information
	my $file;
	my $data;

	open($file, "<", $::process_file_handle_path) || return; # just means there are no further forks within process so do nothing

	my $index = 0;

	# separate by processes spawned at the root level
	while(<$file>) {
		chomp;
		my ($x, $process_id, $parent_id, $y) = split(/\t/, $_);	
		push @{$data->[$index]->{$parent_id}}, $_;
		$index++ if ($parent_id == $process_parent_id);
	}

	#print Dumper($data); exit;
	#print Dumper($data);

	print "\n\nPipeline Process Hierarchy & Stats:\n";
	printf("%-35s %15s %15s %15s %15s\n", ('cmd', 'pid', 'parent pid', 'return value', 'runtime'));
	foreach my $index (0..$#{$data}) {
		process($index, $process_parent_id, 0, $data);
	}

	close ($file);
	# remove file used to store process info
	unlink($::process_file_handle_path);
}



=head1 get_process_called_from_shell
	traverses process hierarchy of current process and returns the most senior process which was called from either shell or CRON
=cut
sub get_process_called_from_shell {
	my $FORMAT = "%-6s %-10s\n";
	my $t = new Proc::ProcessTable;

	my $process_info;

	foreach my $p ( @{$t->table} ) {
		$process_info->{$p->{pid}} = [$p->ppid, $p->{cmndline}];
	}

	my ($current, $cmd) = @{$process_info->{$$}};
	my $parent_cmd = $process_info->{$current}->[1];
	#print Dumper($current);

	while($current) {
		#print join("\t", ($current, $cmd, $parent_cmd))."\n";
		($current, $cmd) = @{$process_info->{$current}};
		$parent_cmd = $process_info->{$current}->[1];
		last if (grep { $cmd eq $_ } ('/bin/bash', 'CRON'));
	}

	return $current;
	#print Dumper($child_to_parent);
}

sub parent_is_shell {
	my $parent_id = getppid();
	
	foreach (`ps -ef`) {
		my @values = split;
		next if ($values[1] eq 'PID');
		my $pid =  int($values[1]);
		#print Dumper(\@values) if ($pid == $parent_id);
		if ($pid == $parent_id && $values[7] ne 'perl') {
			return 1;
		}
	}

	return 0;
}


sub map_month_name_to_numeric {
	my $input = shift || die 'need input';
	$input = uc($input);

	return {
		'JAN' => '01',
		'JANUARY' => '01',
		'FEB' => '02',
		'FEBRUARY' => '02',
		'MAR' => '03',
		'MARCH' => '03',
		'APR' => '04',
		'APRIL' => '04',
		'MAY' => '05',
		'JUN' => '06',
		'JUNE' => '06',
		'JULY' => '07',
		'JUL' => '07',
		'AUG' => '08',
		'AUGUST' => '08',
		'SEP' => '09',
		'SEPT' => '09',
		'SEPTEMBER' => '09',
		'OCT' => '10',
		'OCTOBER' => '10',
		'NOV' => '11',
		'NOVEMBER' => '11',
		'DEC' => '12',
		'DECEMBER' => '12',
	}->{$input} || die "unrecognised month name $input";
}


sub do_these_pairs_overlap {
	my $pair1 = shift || die 'need pair1';
	my $pair2 = shift || die 'need pair2';

	die 'pair1 arrayref expected' if (ref $pair1 ne 'ARRAY');
	die 'pair2 arrayref expected' if (ref $pair2 ne 'ARRAY');

	# add further checks

	my $pair1_length = $pair1->[1] - $pair1->[0] + 1;
	my $pair2_length = $pair2->[1] - $pair2->[0] + 1;

	my $long_one = $pair1;
	my $short_one = $pair2;

	if ($pair2_length > $pair1_length) {
		$long_one = $pair2;
		$short_one = $pair1;
	}


	#print Dumper($long_one, $short_one);

	return 1 if ($short_one->[0] >= $long_one->[0] && $short_one->[0] <= $long_one->[1]);
	return 1 if ($short_one->[1] >= $long_one->[0] && $short_one->[1] <= $long_one->[1]);
	return 0;
}

=head1
	find out whether any common members between two lists
=cut

sub calculate_intersect_elements {
	my $list1 = shift || die 'error';
	my $list2 = shift || die 'error';
	
	my $pdl1 = pdl($list1);
	my $pdl2 = pdl($list2);
	my $intersection = $pdl1->intersect($pdl2);
	my @elements = $intersection->list;
	return \@elements;
}

# no problems with this, apart from maybe the hardcoded path
sub get_list_of_pdb_paths_to_process {
	my @obsolete_files = split("\n", `find /san/wwPDB/MSD_EBI/DATA/pdb_obsolete/ -name '*.ent' -type f`);
	my @active_files = split("\n", `find /san/wwPDB/MSD_EBI/DATA/pdb/ -name '*.ent' -type f`);
	my @files = (@obsolete_files, @active_files);
	return \@files;
}


sub get_list_of_pdbs_to_process {
	my @files = split("\n", `ls /san/wwPDB/MSD_EBI/DATA/pdb/ | grep ^pdb`);
	return \@files;
}


sub get_list_of_chains_to_process {
	my $key = shift || 'all';
	my @files = ();
	my $sql;

	if ($key eq 'without_druggability') {
		$sql = "select c.pdbid_chain from struct3d s join chain c on (c.struct3d_id = s.struct3d_id) where chain_id not in (select chain_id from druggability_scores where chain_id is not null)";
	}
	elsif ($key eq 'without_druggability_and_recent') {
		$sql = "select c.pdbid_chain from struct3d s join chain c on (c.struct3d_id = s.struct3d_id) where date_added >= '2014-04-25' and chain_id not in (select chain_id from druggability_scores where chain_id is not null)";
	}
	elsif ($key eq 'without_druggability_attempt_and_recent') {
		$sql = "select c.pdbid_chain from struct3d s join chain c on (c.struct3d_id = s.struct3d_id) where date_added >= '2014-04-25' and pdbid_chain not in (select chain_name from cansar3d_dev.chematica_log)";
	}
	elsif ($key eq 'all') {
		# todo
		@files = split(/\n/, `find /san/wwPDB/MSD_EBI/DATA/pdb_chain/ -type f`);
	}
	else {
		die 'unrecognised key';
	}

	if (defined($sql)) {
		$::dbh->prepare("alter session set nls_date_format='yyyy-mm-dd'")->execute();
		generic::datalayer->set_schema('CANSAR3D_DEV');
		my $sth = $::dbh->prepare($sql);
		$sth->execute();
		while (my $row = $sth->fetchrow_hashref) {
			my $mid_two = substr($row->{PDBID_CHAIN}, 1, 2);	
			my $path = '/san/wwPDB/MSD_EBI/DATA/pdb_chain/'.$mid_two.'/'.$row->{PDBID_CHAIN}.'.pdb';
			push @files, $path;
		}	
	}

	return \@files;
}





sub execute_querys {
	my $querys = shift || die 'expected argument';
	die 'expected ref argument' if (ref $querys ne 'ARRAY');
	my $only_this_table = shift;


	foreach my $query (@$querys) {
		my $table = $query->[0];
		my $sql = $query->[1];
		next if ($only_this_table && $table ne $only_this_table);

		die 'table undef' if (!defined($table));
		die 'sql undef' if (!defined($sql));

		if ($sql) {
			eval {
				$::dbh->prepare("drop table $table")->execute();
			};

			# we want to know about if this fails, the above not so much
			print Dumper($sql);
			
			eval {
				$::dbh->prepare($sql)->execute();
			};


			if ($@) {
				print Dumper($@);
				print $DBI::errstr;
				die 'fatal database error';
			}
		}




	}
}


sub custom_sort {
	my $input = shift;
	if ($input =~ /[-\d]/) {
		return 1;
	}
	return 0;
}




sub compound_name {
	my $compound_id = shift || die;
	my @order = ('PREF_NAME', 'INN', 'USP', 'JAN', 'RESEARCH_CODE', 'USAN', 'SYNONYM', 'OTHER', 'TRADE_NAME', 'IUPAC');
	my $sth = $::dbh->prepare('select * from cansar_13.compound_identifiers where compound_id = ? order by type, value');
	my $names;

	$sth->execute($compound_id);

	while(my $row = $sth->fetchrow_hashref) {
		push @{$names->{$row->{TYPE}}}, $row->{VALUE};
	}

	#print Dumper($names);

	foreach my $type (@order) {
		if(defined($names->{$type})) {
			my @names = @{$names->{$type}};
			@names = sort {custom_sort($a) <=> custom_sort($b)} @names;
			return $names[0];
		}
	}

	return 'unknown compound name';
}




sub sequence_hash {
	my $input = shift || die 'need input';
	$input =~ s{[\W\d_]}{}g;
 	$input =~ s{[\n\r ]}{}g;
	$input = uc($input);
	return Digest::MD5::md5_hex($input);
}








=head1 parse_line
	takes a line + an optional tsv/csv parameter (default tsv)
	returns a list, or undef if error
=cut
sub parse_line {
	my $line = shift;
	my $sep_char = shift || 'tsv';
	my $quote_char = shift || undef;

	$sep_char = {
		'tsv' => "\t",
		'csv' => ','
	}->{$sep_char};

	die 'invalid sep_char argument passed to parse_line' if (!defined($sep_char));
	die 'global variable parser not defined' if (!defined($::parser));
	
	my $result = $::parser->sep_char($sep_char);
	# otherwise can't parse " within a field
	#$::parser->allow_loose_quotes(1);
	
	# quote characters off by default (this behaviour breaks stuff, needs paramterising
	if (defined($quote_char)) {
		$::parser->quote_char($quote_char);
	}

	my $status = $::parser->parse($line);

	if (!$status) {
		die "parse error on this input:\n".$::parser->error_input().$::parser->error_diag();
	}
	
	# list context
	return $::parser->fields();
}




# 1 to be removed
sub crush_cellline_name {
	my $name = shift || warn 'crush_cellline_name parameter expected';
	$name = uc($name);
	$name =~ s/[-_ ]//g;
	return $name;
}




# this one is the best
sub crush_name {
	my $name = shift || warn 'crush_cellline_name parameter expected';
	$name = uc($name);
	$name =~ s/[-_ ]//g;
	return $name;
}


sub convert_gi50um {
        my $input = shift || die 'value expected';
        return log($input/1000000) / log(10) * -1;
}


sub get_url {
	my $target = shift || die 'no target specified';
	my $params = shift || '';
	#my $user_agent = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';
	#my $user_agent = 'Mozilla/5.0 (X11; Linux i586; rv:31.0) Gecko/20100101 Firefox/31.0';
	#$params.= " -A '$user_agent' ";
	my $curlstring = "curl $params -m 28 -L  '$target' 2>/dev/null";
	return `$curlstring`;
}


sub residue_info {
	my $residue = shift || die 'residue expected';
	$residue =~ s/ //g; #remove any whitespace

	# 0 = known_unmodified, 1 = known_modified, 2 = known_exclude
	my $residue_info = {
		'ALA' => ['A',0],
		'VAL' => ['V',0],
		'LEU' => ['L',0],
		'ILE' => ['I',0],
		'PRO' => ['P',0],
		'TRP' => ['W',0],
		'PHE' => ['F',0],
		'MET' => ['M',0],
		'GLY' => ['G',0],
		'SER' => ['S',0],
		'THR' => ['T',0],
		'TYR' => ['Y',0],
		'CYS' => ['C',0],
		'ASN' => ['N',0],
		'GLN' => ['Q',0],
		'LYS' => ['K',0],
		'ARG' => ['R',0],
		'HIS' => ['H',0],
		'ASP' => ['D',0],
		'GLU' => ['E',0],
		'SEP' => ['S',1],
		'TPO' => ['T',1],
		'PTR' => ['Y',1],
		'CSW' => ['C',1],
		'CME' => ['C',1],
		'KCX' => ['K',1],
		'MSE' => ['M',1],
		'CSS' => ['C',1],
		'CSD' => ['A',1],
		'SCS' => ['C',1],
		'CSO' => ['C',1],
		'OCY' => ['C',1],
		'MHO' => ['M',1],
		#'DU' => ['',2],
		#'DG' => ['',2],
		#'DC' => ['',2],
		#'DT' => ['',2],
		#'DA' => ['',2],
		#'HOH' => ['',2],
	};

	return $residue_info->{$residue};
}


=head1 tee functions
	dep hierarchy

	print_tee
		run_tee2
		chdir
			chdir_to_script

=cut

sub print_tee {
	my $input = shift;
	tee { print $input; };
	$::tee_output.=$input;
	return '';
}



=head1 run_tee2
	
=cut

sub run_tee2 {
	my $cmd = shift || die 'need command';
	return run_tee3($cmd);
}


=head1 run_tee3

=cut

sub run_tee3 {
	my $start = time;
	my $cmd = shift || die 'need command';
	my $tolerate_errors = shift || 0;
	my $md5 = Digest::MD5::md5_hex($cmd);
	# not sure why we have this really, makes diagnosing problems a bit difficult
	#$cmd.=' 2>&1';
	#$cmd.=" 1> /home/jtym/tee/$md5.stdout 2>/home/jtym/tee/$md5.stderr";
	print "$cmd\n\n";

	#<STDIN>;
	my $return_code;
	# the eval here means the code keeps on running even if fatal error
	my $cmd_output = eval { tee_merged { $return_code = system($cmd) } };

	$cmd_output = 'empty' if (!$cmd_output);
	
	#print 'checkpoint1='.$cmd;
	# probably best to have this here, saves having to do it in each individual script
	if ($return_code) {
		# send an e-mail about the error
		send_mail_to_notify_list("$cmd RETURNED ERRORCODE [$return_code]", $cmd_output, 'joe');
	}
	
	#print 'checkpoint2='.$cmd;
	
	my $parent_id = getppid();
	$::run_tee_no++;

	print "\n\n";
	$::tee_output.="$cmd\n$cmd_output\n";
	my $duration = time - $start;
	push @{$::tee_runtimes}, [ $cmd, "$duration seconds", $return_code ];
	$::tee_runtime_total+=$duration;


	# should probably be rewritten to use shared memory, as this doesn't really work very well for parallel perl processes using run_tee

	# disabled causing error when run by another user
	#open FILE, ">> ".$::process_file_handle_path || die 'file error';
	#print FILE join("\t", ($cmd, $$, $parent_id, $return_code, $duration))."\n"; # consider json storage instead
	#close FILE;

	return $return_code;
}





=head1 run_tee4
	run_tee3 with output capturing disabled.. this is done in master wrapper
	remaining features: error tolerance, immediately send e-mail if positive error code, tracking of error codes grouped by parent process
	might be an idea to override system with this
=cut

sub run_tee4 {
	my $cmd = shift || die 'need command';
	my $start = time;
	print "$cmd\n\n";

	my $return_code;
	# the eval here means the code keeps on running even if fatal error
	my $cmd_output = eval { $return_code = system($cmd) };

	$cmd_output = 'empty' if (!$cmd_output);
	
	#print 'checkpoint1='.$cmd;
	# probably best to have this here, saves having to do it in each individual script
	if ($return_code) {
		# send an e-mail about the error
		send_mail_to_notify_list("$cmd RETURNED ERRORCODE [$return_code]", $cmd_output, 'joe');
	}
	
	
	my $parent_id = getppid();
	$::run_tee_no++;

	print "\n\n";
	my $duration = time - $start;


	# should probably be rewritten to use shared memory, as this doesn't really work very well for parallel perl processes using run_tee
	open my $FILE, ">>", $::process_file_handle_path || die 'file error';
	print $FILE join("\t", ($cmd, $$, $parent_id, $return_code, $duration))."\n"; # consider json storage instead
	close $FILE;

	return $return_code;
}






# legacy start
sub run_tee {
	my $cmd = shift || die 'need command';
	cbc::common::print_tee "$cmd\n\n";
	my $cmd_output = tee { system($cmd.' 2>&1') };
	cbc::common::print_tee($cmd_output);
	cbc::common::print_tee "\n\n";

	#$::tee_output.=$new_output;
	
	my $new_output = "$cmd\n\n$cmd_output\n\n";
	return $new_output;
}


sub system {
	my $cmd = shift || die 'need command';
	print "$cmd\n\n";
	my $return = system($cmd);
	if ($return) {
		print "$cmd : non-zero return code, hit any key to continue\n";
		<STDIN>;
	}
}

# legacy end




sub chdir {
	my $input = shift || die 'need input';
	cbc::common::print_tee "changing directory to $input\n";
	chdir($input) || die 'chdir failed';
	return;
}

sub chdir_to_script {
	my $base_dir = $FindBin::Bin;
	cbc::common::chdir($base_dir);
}

sub send_mail_to_notify_list {
	my $subject = shift || die 'error';
	my $content = shift || '';
	my $list_id = shift || 'cansar';



	my $notify_lists = {
		'cansar' => ['cansar@icr.ac.uk'],
		'joe' => ['joe.tym@icr.ac.uk']
	};

	my @notify_list = @{$notify_lists->{$list_id}}; 


	if (@notify_list) {
		open (my $MAIL, "| mail -s \"$subject\" ".join(' ', @notify_list));
		print $MAIL $content;
		close $MAIL;
	}
}




=head1
	0. ambiguous match with either: die, need a more sensible response, maybe namespaces
	1. unambiguous match with raw: update the uncrushed_name = input
	2. unambiguous match with crushed: add the new synonym, add the raw synonym and update uncrushed_name = input
	3. no match: insert new experiment_subject + 2xsynonyms + update uncrushed_name = input
	
	return subject_id

=cut



sub match_sample_name2 {
	my $input = shift;
	my $type = shift;
	return {};
}

sub match_sample_name1 {
	my $input = shift;
	my $type = shift;
	my $crushed_input = cbc::common::crush_name($input);

	my $sth = $::dbh->prepare('select e.subject_id, e.type, e.uncrushed_name from experiment_synonym es join experiment_subject e on (e.subject_id = es.subject_id) where es.value like ? escape \'\\\' and e.type like ?');
	my $matches;
	my $types = {};

	foreach my $name ($input, $crushed_input) {
		my $name_escaped = $name;
		$name_escaped =~ s/_/\\_/g;
		$sth->execute($name_escaped, $type);
		while (my $row = $sth->fetchrow_hashref) {
			$types->{$type} = 1;
			#print Dumper($row);
			$matches->{$row->{SUBJECT_ID}}->{$name} = $row->{UNCRUSHED_NAME};
		}
	}

	return {
		'types' => $types,
		'matches' => $matches
	};
}


# uses only child tables to get next target_id, will throw an error until all these tables have target_id field
sub get_next_target_id {
	if (!defined($::targets)) {

		my $duplicates;

		foreach my $table ('protein', 'experiment_subject', 'target_other') {
			if ($table eq 'experiment_subject') {
				generic::datalayer->set_schema('EXPRESSION');
			}
			else {
				generic::datalayer->set_schema('CANSAR_INTERNAL');
			}

			my $sth = $::dbh->prepare("select target_id from $table where target_id is not null");
			$sth->execute();
			while(my $row = $sth->fetchrow_hashref) {
				if (!defined($row->{TARGET_ID})) {
					print Dumper($table, $row); <STDIN>;
				}

				if (defined($::targets->{$row->{TARGET_ID}})) {
					$duplicates->{$table}->{$row->{TARGET_ID}}++;
				}

				$::targets->{$row->{TARGET_ID}} = 1;
			}
		}

		if (defined($duplicates)) {
			print Dumper('duplicates detected', $duplicates);
			exit;
		}

		#print Dumper($::targets); exit;		
	}

	my $target_id = 1;

	while(defined($::targets->{"$target_id"})) {
		$target_id++;
	}

	$::targets->{$target_id} = 1;
	return $target_id;
}


=head1 match_sample2
	1) to replace match_sample
	2) has much more usable return data structure
	3) still needs namespace/species
	4) still need to think about ambiguous synonyms
=cut

sub match_sample2 {
	my $input = shift || die 'need input';
	my $type = shift || die 'need type';
	my $tax_id = shift || die 'need tax_id';
	my $insert_mode = shift;


	if (!defined($insert_mode)) {
		$insert_mode = 0;
	}

	my $crushed_input = cbc::common::crush_name($input);

	# caching
	if (!defined($::all_experiment_synonyms)) {
		generic::datalayer->set_schema('EXPRESSION');

		my $sth = $::dbh->prepare("
			select distinct e.type, value, tax_id, preferred_name, e.subject_id, e.uncrushed_name
			from experiment_subject e 
			join experiment_synonym s on (e.subject_id = s.subject_id) 
		");
		#where e.type like 'cell-line'
		$sth->execute();

		while(my $row = $sth->fetchrow_hashref) {
			#print Dumper($row);
			if (!defined($row->{TAX_ID})) {
				$row->{TAX_ID} = 9606;
			}

			$::all_experiment_synonyms->{$row->{TYPE}}->{$row->{TAX_ID}}->{$row->{VALUE}}->{$row->{PREFERRED_NAME}} = 1;
			$::all_experiment_subjects->{$row->{TYPE}}->{$row->{TAX_ID}}->{$row->{PREFERRED_NAME}}->{crushed_name} = $row->{PREFERRED_NAME};
			$::all_experiment_subjects->{$row->{TYPE}}->{$row->{TAX_ID}}->{$row->{PREFERRED_NAME}}->{uncrushed_name} = $row->{UNCRUSHED_NAME};
			$::all_experiment_subjects->{$row->{TYPE}}->{$row->{TAX_ID}}->{$row->{PREFERRED_NAME}}->{subject_id} = $row->{SUBJECT_ID};
			push @{$::all_experiment_subjects->{$row->{TYPE}}->{$row->{TAX_ID}}->{$row->{PREFERRED_NAME}}->{synonyms}}, $row->{VALUE};
		}
	}

	$::experiment_subjects = $::all_experiment_subjects->{$type}->{$tax_id};
	$::experiment_synonyms = $::all_experiment_synonyms->{$type}->{$tax_id};

	my @input_matches;
	my @crushed_input_matches;

	if (defined($::experiment_synonyms->{$input})) {
		@input_matches = keys(%{$::experiment_synonyms->{$input}});
	}

	if (defined($::experiment_synonyms->{$crushed_input})) {
		@crushed_input_matches = keys(%{$::experiment_synonyms->{$crushed_input}});
	}

	my $hash;
	my $input_match = 0;


	my $insert_subject = $::dbh->prepare('insert into expression.experiment_subject (subject_id, preferred_name, uncrushed_name, type, target_id, tax_id) values(?,?,?,?,?,?)');
	my $insert_synonym = $::dbh->prepare('insert into expression.experiment_synonym (synonym_id, value, subject_id) values(?,?,?)');


	# 1. input matches synonym
	if (@input_matches) {
		my ($crushed_name) = @input_matches;
		# 1a. input matches synonym non-ambiguous, return info (e.g. )
		if (@input_matches == 1) {
			$hash = $::experiment_subjects->{$crushed_name};
			$hash->{result} = 'input match (non-ambiguous)';
		}
		# 1b. input matches synonym ambiguous, return info for 1st and warning (e.g. )
		else {
			$hash = $::experiment_subjects->{$crushed_name};
			$hash->{result} = 'input match (ambiguous)';
		}
	}


	# 2. only crushed input matches a synonym only, add a new synonym, return info (e.g. ), 
	# re-assign best synonym in another script/function which also verifies 
	elsif(@crushed_input_matches) {
		my ($crushed_name) = @crushed_input_matches;
		$hash = $::experiment_subjects->{$crushed_name};
		my $subject_id = $hash->{subject_id};
		if ($insert_mode) {
			$insert_synonym->execute($input, $subject_id);
		}

		$hash->{result} = 'input match after crushing, new synonym added';
	}

	# 3. matches nothing, insert experiment_subject, insert synonym (e.g. )
	else {
		if ($insert_mode) {
			$::experiment_synonyms->{$input}->{$crushed_input} = 1;
			$::experiment_synonyms->{$crushed_input}->{$crushed_input} = 1;
		
			my @synonyms = ($input, $crushed_input);
			@synonyms = List::MoreUtils::uniq(@synonyms);

			# both of these should be datalayer and in the same function ideally
			my $new_subject_id = generic::datalayer::get_max('EXPRESSION', 'EXPERIMENT_SUBJECT', 'SUBJECT_ID');
			my $new_target_id = cbc::common::get_next_target_id();

			# set global cache & return value
			$::experiment_subjects->{$crushed_input} = {
				'crushed_name' => $crushed_input,
				'uncrushed_name' => $input,
				'subject_id' => $new_subject_id,
				'target_id' => $new_target_id,
				'synonyms' => \@synonyms
			};
		
			$hash = $::experiment_subjects->{$crushed_input};

			$insert_subject->execute($new_subject_id, $crushed_input, $input, $type, $new_target_id, $tax_id);
			
			foreach my $value (@synonyms) {
				my $new_synonym_id = generic::datalayer::get_max('EXPRESSION', 'EXPERIMENT_SYNONYM', 'SYNONYM_ID');
				$insert_synonym->execute($new_synonym_id, $value, $new_subject_id);
			}

			#print Dumper($input); <STDIN>;
		}
		$hash->{result} = 'no match, new subject and synonym added';
	}

	$hash->{input} = $input;

	# highlighted 2 cell lines where the synonyms aren't consistent with crushed name
	if (!defined($hash->{crushed_name})) {
		$hash->{crushed_name} = $crushed_input;
	}
	
	return $hash;
}


=head1 match_sample
	attempts to match with database, if no match, or new synonym records are added updated appropriately\
	replaced by match_sample2 *phase out*
=cut

sub match_sample {
	my $input = shift || die 'need input';
	my $type = shift || die 'need type/namespace';
	my $insert_mode = shift || 0;


	if ($insert_mode) {
		#print "WARNING: NEW CELLLINES WILL BE INSERTED\n";
		#sleep 10;
	}


	# edit this so it only does it if not already there
	generic::datalayer->set_schema('EXPRESSION');


	my $crushed_input = cbc::common::crush_name($input);

	#print Dumper($crushed_input); exit;

	my $new_subject_id = generic::datalayer::get_max('EXPRESSION', 'EXPERIMENT_SUBJECT', 'SUBJECT_ID');
	my $new_synonym_id = generic::datalayer::get_max('EXPRESSION', 'EXPERIMENT_SYNONYM', 'SYNONYM_ID');

	#print Dumper($input, $crushed_input);


	

	my $sth = $::dbh->prepare('select e.subject_id, e.type, e.uncrushed_name from experiment_synonym es join experiment_subject e on (e.subject_id = es.subject_id) where es.value like ? escape \'\\\' and e.type like ?');
	

	
	my $data = match_sample_name1($input, $type);
	my $matches = $data->{matches};
	my $types = $data->{types};
	my $no_types = keys(%$types);


	


	my $insert_synonym = $::dbh->prepare('insert into experiment_synonym (synonym_id, value, subject_id) values(?,?,?)');
	my $insert_subject = $::dbh->prepare('insert into experiment_subject (subject_id, type, preferred_name, uncrushed_name) values(?,?,?,?)');
	my $update_uncrushed = $::dbh->prepare('update experiment_subject set uncrushed_name = ? where subject_id = ?');


	my @subjects = sort {$a <=> $b} keys(%{$matches});
	my ($subject_id) = @subjects;	


	my $raw_match;
	my $crushed_match;

	if (defined($subject_id)) {
		$raw_match = defined($matches->{$subject_id}->{$input});
		$crushed_match = defined($matches->{$subject_id}->{$crushed_input});
	}



	if (@subjects > 1) {
		warn 'ambiguous needs consolidation';
		<STDIN>;
		# 1. get the subject_ids, pick the one to keep
		my $subject_id_to_keep = shift @subjects;
		#print Dumper(\@subjects); exit;


		#print Dumper(\@subjects);



		print Dumper('no types', $no_types);
		exit if ($no_types > 1);




		# 2. iterate through the rest and remap data
		foreach my $subject_id (@subjects) {
			foreach my $table ('EXPERIMENT_SYNONYM', 'EXPERIMENT_SUBJECT_METADATA', 'COSMIC_SAMPLES','RESULTSET','MUTATION', 'ICGC_EXPRESS') {
				my $sql = "select count(*) c from $table where subject_id = ?";
				my $sth = $::dbh->prepare($sql);
				$sth->execute($subject_id);
				if (my $row = $sth->fetchrow_hashref) {
					print Dumper($table, $row->{C});
				}

				# needed to avoid unique constraint errors
				if ($table eq 'EXPERIMENT_SYNONYM') {
					$::dbh->prepare("delete from experiment_synonym where subject_id = ? and value in (select value from experiment_synonym where subject_id = ?)")->execute($subject_id, $subject_id_to_keep);
				}

				$::dbh->prepare("update $table set subject_id = ? where subject_id = ?")->execute($subject_id_to_keep, $subject_id);
				$::dbh->prepare("delete from experiment_subject where subject_id = ?")->execute($subject_id);
			}
		}

		# 3. delete the other subjects



		# do nothing
	}
	elsif($raw_match && $crushed_match) {
		# update uncrushed_name
		if ($input ne $matches->{$subject_id}->{$input} && length($input) > length($matches->{$subject_id}->{$input})) {
			print "updating uncrushed name $input $subject_id \n"; sleep 1;
			$update_uncrushed->execute($input, $subject_id);
		}
	}
	elsif($crushed_match) {
		print "inserting new synonym $input\n"; sleep 1;
		$insert_synonym->execute($new_synonym_id, $input, $subject_id);
		$new_synonym_id++;
		# insert new synonym (there is no match)
		
		# update uncrushed_name if raw is better
		if ($input ne $matches->{$subject_id}->{$crushed_input} && length($input) > length($matches->{$subject_id}->{$crushed_input})) {
			print "updating uncrushed name $input $subject_id \n"; sleep 1;
			$update_uncrushed->execute($input, $subject_id);
		}

	}
	else {
		if ($insert_mode) {
			print 'insert experiment_subject';
			$insert_subject->execute($new_subject_id, $type, $crushed_input, $input);
			$subject_id = $new_subject_id;
			$new_subject_id++;		


			print 'insert new synonym(s)';
			my @unique_synonyms = List::MoreUtils::uniq(($crushed_input, $input));		
			print Dumper(\@unique_synonyms); 
			#exit;
			#
			foreach my $value (@unique_synonyms) {
				$insert_synonym->execute($new_synonym_id, $value, $subject_id);
				$new_synonym_id++;
			}

			# refresh matches
			$data = match_sample_name1($input, $type);
			$matches = $data->{matches};


		}
		else {
			print "\nnot in database, please enable insert mode to enable insertion of this new record\n";
		}
	}

	return $matches;
}


sub show_and_run {
	my $cmd = shift || die 'need cmd';
	my $host = shift || 'howl';

	print "running on remote host $host: $cmd\n";

	if ($host eq 'howl') {
		return CORE::system($cmd);
	}
	else {
		if (!defined($::ssh->{$host})) {
			$::ssh->{$host} = Net::OpenSSH->new($host);
			#$::ssh->{$host}->system('source /etc/profile');
		}

		return $::ssh->{$host}->system($cmd);
	}
}


1;

