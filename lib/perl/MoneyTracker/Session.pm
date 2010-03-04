package MoneyTracker::Session;

use strict;

use Class::MethodMaker [ 
                         new    => [ -hash => 'new' ],
                         scalar => [qw(dbh user budget_id)]
                       ];
1;
