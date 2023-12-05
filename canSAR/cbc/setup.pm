package main;

use strict;
use warnings;

# cpan modules
use Carp::Always;
use Data::Dumper;
use DBI;
use IO::Handle;
use Math::Trig ();
use POSIX ();
use Statistics::LineFit;
use Statistics::Lite;
use Sys::Hostname;
use Sys::SigAction;
use Text::CSV;
use Time::HiRes;
use Capture::Tiny 'tee';


# internal modules
use generic::datalayer;
use cbc::common qw(get_schema);



=pod
	package declaration is main so that the imported modules are 
	accessible within the main name space and are accessible within the calling scripts

	current purpose:
	
	1. imports frequently used modules
	2. sets up database handles 

	exports 2 global variables to the main namespace
	dbh
	line_parse
=cut






$SIG{__WARN__} = sub {
	my $message = shift;
	print $message;
	my $user = $ENV{USER} || die 'could not determine user';
	my $warning_dir = "/san/data/warnings/$user";
	my $warning_path = "$warning_dir/$0";


	if (!-d $warning_dir) {
		cbc::common::system("mkdir -p $warning_dir");
	}

	if (!defined($::warning_file_handle)) {
		open($::warning_file_handle, '>', $warning_path) || die "could not open warning_file_handle $warning_path";
		#print $::warning_file_handle'open handle';
	}
	
	print $::warning_file_handle $message;
};




BEGIN {
	STDOUT->autoflush(1);
	STDERR->autoflush(1);
	my $hostname = `hostname -s`;
	chomp $hostname;
	

	# database connection
	eval {
		my $h = Sys::SigAction::set_sig_handler('INT', sub { exit; } );
		cbc::common::setup_database_handles();
		# integrate this into cbc::setup;
		$::dbhm = DBI->connect('dbi:mysql:database=mysql;host=calcifer','root','');
	};
	die $@ if $@; # if an error is encountered we need to die here

	# default database is dev calcifer/expression
	my $default_host = 'howl';
	$default_host = $hostname if ($hostname ne 'howl');

	$::dbh = $::dbhs->{$default_host};
	
	# expression is the default schema
	generic::datalayer->set_schema('EXPRESSION') if ($hostname eq 'howl');

	# global parsing object	
	$::parser = Text::CSV->new();

	# legacy code, now switching to using cbc::common::parse_line
	$::line_parse->{csv} = Text::CSV->new();
	$::line_parse->{tsv} = Text::CSV->new({sep_char => "\t", 'allow_loose_quotes' => 1});
	$::tee_output = '';
	$::tee_runtimes = [];
	$::tee_runtime_total = 0;

	# needs changing to a common path
	$::process_file_handle_path = "/home/jtym/process_tracking/".cbc::common::get_process_called_from_shell();

	# bit confused about this, 0002 seems to be group writable, not 0022 as we have been checking for?/
	# make sure group writable umask is set
	my $umask = umask;
	if ($umask != 18) {
		#die 'umask must be set to 0022, i.e. group writable in order to continue';
	}
}





END {



}

1;

