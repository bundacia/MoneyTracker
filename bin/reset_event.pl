#! /usr/bin/perl

use strict;
use DBI;
use lib '/home/tlittle/codebase/MoneyTracker/lib/perl';
use MoneyTracker::Session;
use MoneyTracker::User;
use MoneyTracker::EntryEvent;
use Data::Dumper;

# Connect to the database. 
my $dbh = DBI->connect(
                   'dbi:mysql:money_tracker_00',
                   'root', 
                   'myb1gsh0w',
                   { RaiseError => 1, AutoCommit => 1 }
                   ) or die "Error connecting to database $!";

my $s = MoneyTracker::Session->new( dbh => $dbh );

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
my $now = sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;

my $o = MoneyTracker::EntryEvent->new();
$o->retrieve(ID => 7,session => $s);
$o->event_time($now);
$o->save();

my $oo = MoneyTracker::EntryEvent->new(
                                   budget_id => 1,
                                   fund_id   => 2,
                                   type      => 'rollover',
                                   event_time => $now,
                                   name       => 'Food Rollover',
                                   recurrence => 'month',
                                   frequency  => 1,
                                   active     => 1,
                                  );
$oo->save(session => $s);

#tjl#print Dumper $o;
#tjl#print Dumper $o->get_budget();
#tjl#print Dumper $o->get_fund();
#print Dumper $o->get_entries_by_date(start => '2006-09-26 00:00:00', end => '2010-01-01 00:00:00');

#TJL#$user->set_password('foobar2');
#TJL#print "foobar:  ".$user->check_password('foobar') ."\n";
#TJL#print "foobar2: ".$user->check_password('foobar2') ."\n";

