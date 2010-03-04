package MoneyTracker::EntryEvent;

use strict;
use Date::Calc qw/Add_Delta_DHMS Add_Delta_YM/;

use lib '/home/tlittle/codebase/MoneyTracker/lib/perl';
use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { 
    budget_id   => 'int',
    fund_id     => 'int',
    user_id     => 'int',
    type        => 'string',
    active      => 'int',
    name        => 'string',
    recurrence  => 'string',
    frequency   => 'int',
    event_time  => 'date',
    amount      => 'float',
    entity      => 'string', 
    description => 'string',
};

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'entry_event' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
      scalar => ['entry'], 
   ];

sub update_time
{
    my $self = shift;
    my @current = ($self->event_time() =~ /(\d*)-(\d*)-(\d*) (\d*):(\d*):(\d*)/);
    my ($y,$m,$d,$H,$M,$S) = @current; #initialize the new time with the current event time

    if($self->recurrence() eq 'day')
    {
        ($y,$m,$d,$H,$M,$S) = Add_Delta_DHMS(@current, $self->frequency(),0,0,0);
    }
    elsif($self->recurrence() eq 'month')
    {
        ($y,$m,$d) = Add_Delta_YM(@current[0..2], 0, $self->frequency());
    }
    elsif($self->recurrence() eq 'year')
    {
        ($y,$m,$d) = Add_Delta_YM(@current[0..2], $self->frequency(), 0);
    }
    $self->event_time("$y-$m-$d $H:$M:$S"); 
}
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
