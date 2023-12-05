#!/usr/bin/perl
use strict;
#use Clone qw(clone);
#
#use DateTime;
#use DateTime::Format::Duration;
use Time::ParseDate qw(parsedate);
use Time::Piece;
use Date::Calc qw(Add_Delta_Days);
use DateTimeX::Auto qw(:auto);
use Time::ParseDate;
use Time::CTime;
use Time::Seconds;

unless (@ARGV == 5) {
        &USAGE;
}

sub USAGE {

die ' 

perl ~/bin/perl/calculate_payments.pl <days> <start> <cost> <advance> <weekly>



Days:       duration of stay (number of days)
Start date: start date for the stay
Cost:       total cost of the stay
Advance:    the amount payable in advance (set to 0 if not)
Weekly:     payment every 1/2/4 weeks



';

}



# check that DESeq ran okay

my $days = shift;
my $start = shift;
my $cost = shift;
my $adv = shift;
my $week = shift;

print "\n\n";
print "The stay will be for $days days\n";
print "The start day will be $start\n";
print "The total cost is $cost\n";
print "The advance payable is $adv\n";
print "The cost will be paid every $week weeks\n";

my $daycost = $cost/$days;
my $weekcost =  $daycost*7;
print "Cost per day is $daycost and per week is $weekcost\n";

my $payoff = $weekcost * $week;

my $end = $start+$days;

print "Payable in advance $adv\n";
print "Payable at start $payoff\n";
print "End date $end\n";


my $d1=$start;
#$d1 = strftime("%d/%m/%Y",localtime($start));
#$d1 = DateTime::Format::Strptime->new( pattern => '%d/%m/%Y');


my $d1 = Time::Piece->strptime( $start, '%d/%m/%Y');

#my @d1 = split(/\//,$start);
#my $d2= Date::Calc::Add_Delta_Days($d1[2],$d1[1],$d1[0],$days);
#my $d2= $d1;
#$d2 -> add(days => $days);

my $newtime = parsedate($d1) + ($days * 24 * 60 * 60);
my $d2 = strftime("%d/%m/%Y",localtime($newtime));

#my $diff = delta_days($d2-$d1);

#$d1 = strftime('%d/%m/%Y');

printf "%d days difference D1: $start D2: $d2 \n", (parsedate($d2) - parsedate($d1)) / (60 * 60 * 24);


#my $date1 = 'Fri Aug 30 10:53:38 2013';
#my $date2 = 'Fri Aug 30 02:12:25 2013';

#my $format = '%a %b %d %H:%M:%S %Y';

#my $format = '%D';
#my $format = '%d/%B/%Y';







