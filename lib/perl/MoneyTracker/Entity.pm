package MoneyTracker::Entity;

use strict;
use lib '/home/tlittle/codebase/MoneyTracker/lib/perl';
use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { 
    budget_id   => 'int',
    name        => 'string',
    description => 'string',
    address1    => 'string',
    address2    => 'string',
    city        => 'string',
    state       => 'string',
    zipcode     => 'int',
    country     => 'string',
    phone       => 'string',
};

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'entity' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
   ];
sub get_budget
{
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Budget', $self->budget_id);
}

1;   
