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

my $o = MoneyTracker::Fund->new();
$o->retrieve(ID => 2,session => $s);
$o->budget_id(1);
$o->rollover(0);
print Dumper $o;
$o->save();


#tjl#print Dumper $o;
#tjl#print Dumper $o->get_budget();
#tjl#print Dumper $o->get_fund();
#print Dumper $o->get_entries_by_date(start => '2006-09-26 00:00:00', end => '2010-01-01 00:00:00');

#tjl#my $user = MoneyTracker::User->new(user_name => 'test');
#tjl#$user->retrieve(session => $s);
#tjl#$user->set_password('test');
#tjl#print $user->get_xml();
#TJL#print "foobar:  ".$user->check_password('foobar') ."\n";
#TJL#print "foobar2: ".$user->check_password('foobar2') ."\n";

