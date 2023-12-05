#!/usr/bin/perl
# $Id: dbgap-aspera-download.pl,v 1.10 2012/06/22 15:37:42 deryd Exp $
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================
#
# Author:  Sergey Shevelev
#

use strict;

use URI::URL;
use LWP::UserAgent;
use LWP::Debug ();
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Request::Form;
use HTML::TreeBuilder 3.0;
use HTTP::Cookies;
use Term::ReadKey;
use Getopt::Std;

my $my_version = '1.0';

if ('$Id: dbgap-aspera-download.pl,v 1.10 2012/06/22 15:37:42 deryd Exp $' =~ /\$Id: dbgap-aspera-download.pl,v (\S+)/) {
  $my_version = $1;
}

sub HELP_MESSAGE() {
  print STDERR "Usage: dbgap-aspera-download.pl [-u username] [-p password] [-q] -r request-id [-a ascp-parameters]\n";
  print STDERR "  use -q (quiet) flag to skip checking for updates (default)\n";
  print STDERR "  use -a switch to define parameters to be passed to ascp utility (see ascp manual for details)\n";
}

sub VERSION_MESSAGE() {
  print STDERR "dbGaP Aspera download utility, version $my_version\n"; 
}

sub check_version
{
  my $ua = LWP::UserAgent->new;
  my $url = url "http://dbgap.ncbi.nlm.nih.gov/aa/dbgap-aspera-download.pl";
  print STDERR "Checking for updates...";
  my $res = $ua->request(GET $url);
  my $content = $res->content;
  my $current_version = '1.0';

  while ($content =~ m/\$Id: dbgap-aspera-download.pl,v (\S+)/gs) {
    $current_version = $1;
  }
  print STDERR "done\n";

  if ($my_version < $current_version) {
    print STDERR "Version $current_version is available (your version is $my_version)\n";
    print STDERR "http://dbgap.ncbi.nlm.nih.gov/aa/dbgap-aspera-download.pl\n";
  }
}

$| = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::OUTPUT_HELP_VERSION = 1;

my %opts;
getopts('p:u:r:l:qa:', \%opts);

check_version() unless $opts{"q"};

my $drid = $opts{"r"};

unless ($drid) {
  HELP_MESSAGE();
  exit(1);
}

my $wga_cgi='https://dbgap.ncbi.nlm.nih.gov/aa/wga.cgi';

my $ua = LWP::UserAgent->new;
my $login = qq(&_login=$opts{"l"}) if $opts{"l"};
my $url = url $wga_cgi."?page=dr_files&drid=$drid&filter=drid&login=NFL";
if ($login) {
  $url = url $wga_cgi."?page=dr_files&drid=$drid&filter=drid$login";
}
$ua->cookie_jar( {} );

my $res = $ua->request(GET $url);
my $rc = 0;

unless ($login) {

  for my $page ('nih.gov/login/dispatch/dispatch.cgi',
                 'nih.gov/CertAuth/forms/NIHPivOrFormLogin.aspx',
                 'nih.gov/login/dispatch/dispatch.cgi'
                 )
  {
    my $tree = HTML::TreeBuilder->new;

    die $res->message unless ($res->is_success);
    if (index($res->request->uri, $wga_cgi) != -1)
    {
       last;
    } 

    #check if correct redirect
    if (index($res->request->uri, $page) == -1)
    {
      print "failed: non-expected page ".$res->request->uri."\n";
      exit(2);
    }
    
    $tree->parse($res->content);
    $tree->eof();

    my @forms = $tree->find_by_tag_name('FORM');
    die "No forms found" unless @forms;
    my $f = HTTP::Request::Form->new($forms[0], $res->request->uri);
    if ($page == 'https://nihlogin.nih.gov/CertAuth/forms/NIHPivOrFormLogin.aspx') 
    # user/password needed
    {
      my $u = $opts{'u'} if $opts{"u"};

      unless ($u) {
        print "Login: ";
        ReadMode('normal');
        $u = ReadLine(0);
      chomp $u;
      }

      my $p = $opts{'p'} if $opts{"p"};

      unless ($p) {
        print "Password: ";
        ReadMode('noecho');
        $p = ReadLine(0);
        chomp $p;
      }


      ReadMode('normal');
      
      $f->field("PASSWORD", $p);
      $f->field("USER", $u);
    }

    push @{ $ua->requests_redirectable }, 'POST';

    my $rr = $f->press();
    $rr->content($rr->content);

    $res = $ua->request($rr);
  } # while  
} # unless

#check if correct redirect
if (index($res->request->uri, $wga_cgi) == -1)
{
  print "failed: sstop on non-expected page".$res->request->uri."\n";
  exit(1);
}
else 
{
  print "done\n";
}

my $content = $res->content;
my $u;

if ($res->base =~ /^([^?]+)\??/) {
  $u = $1;
  $u =~ s/https:/http:/;
}

my $server;
my $token;
my $file;

if ($content =~ /aspera-server-url\:\s*(\S+)/gs) {
  $server = $1;
  $server =~ s/:\d+$//;
  $server =~ s{^fasp://}{};
}

if ($content =~ /aspera-token\:\s*(\S+)/gs) {
  $token = $1;
}

if ($content =~ /aspera-file-path\:\s*(\S+)/gs) {
  $file = $1;
}

unless ($token)
{
 print " parse failed\n";
 exit(1);
}

# `ascp $opts{'a'} $server:$file -W $token .`;
my $cmd = sprintf("ascp %s %s:%s -W %s . ",  $opts{'a'}, $server, $file, $token );
# print($cmd);
my $rc = system($cmd);
exit $rc;




