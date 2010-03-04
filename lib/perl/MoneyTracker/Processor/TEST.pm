package MoneyTracker::Processor::TEST;

use strict;
use Data::Dumper;
use MoneyTracker::Budget;

use base 'MoneyTracker::Processor';

#########################################
# run 
#########################################
sub run 
{ 
   my $self = shift;
   my $obj = MoneyTracker::User->new(user_name=>'test'); 
   print "start\n";
   eval
   {
       $obj->retrieve();
       print Dumper $obj->get_budgets();
       #my $entries = $b->get_entries_by_date(start=>'06/09/23 12:00:00', end=>'06/09/24');
       #print Dumper $entries;
       #my $users = $b->get_users();
       #print Dumper $users;
   };
   if ($@)
   {
       print "ERROR: $@";
   }
}

1;

