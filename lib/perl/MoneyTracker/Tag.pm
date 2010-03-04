package MoneyTracker::Tag;

#
# For use in furture versions of MoneyTracker
#

use strict;
use lib '/home/tlittle/codebase/MoneyTracker/lib/perl';
use MoneyTracker::Session;
use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { 
                    budget_id   => 'int',
                    name        => 'string',
                    description => 'string',
                    };

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'tag' },  'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
   ];

1;   

