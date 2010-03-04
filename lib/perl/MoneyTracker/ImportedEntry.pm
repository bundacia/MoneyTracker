package MoneyTracker::ImportedEntry;

use strict;

use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { 
    budget_id   => 'int',
    fund_id     => 'int',
    date        => 'date',
    amount      => 'float',
    entity      => 'string', 
    description => 'string',
    source      => 'string',
    status      => 'string',
};

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -default => 'imported_entry'     }, 'DB_TABLE'         ], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'       ], 
      scalar => [{ -static => '1', -default => 1    }, 'IGNORE_DUPLICATES'], 
   ];
sub get_budget
{
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Budget', $self->budget_id);
}
sub get_fund
{
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Fund', $self->fund_id);
}
sub get_user
{
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::User', $self->user_id);
}
1;   
