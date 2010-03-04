package MoneyTracker::Budget;

use strict;

use Data::Dumper;
use MoneyTracker::Fund;
use MoneyTracker::User;
use MoneyTracker::EntryEvent;
use MoneyTracker::ExternalEntrySource;
use MoneyTracker::ImportedEntry;
use MoneyTracker::Session;

use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { name => 'string' };

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'budget' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'name' }, 'UNIQUE_KEY'], 
   ];
sub get_events_by_date
{
    my $self    = shift;
    my %args    = @_;
    my $class   = ref $self;
    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh     = $self->session()->dbh();
    my $sql_abs = $self->sql_abs();
    my $start   = $args{start};
    my $end     = $args{end};
    my $window  = $args{window};
    my $active  = $args{active};
   
    my $event_table = MoneyTracker::EntryEvent->DB_TABLE();
    my $budget_table = $self->DB_TABLE();
    my $ID = $self->ID();

    # Require exactly 2 of start, end and window args
    die 'Invalid params to '.$class.'->get_events_by_date()' 
        if ( scalar( grep {defined $_} ($window, $start, $end) ) != 2 );

    my @bind = ($ID);
    my $sql  = <<"SQL";
        SELECT ${event_table}.ID FROM $event_table 
        WHERE ${budget_table}_id = ?
SQL

    if(!$window)
    {
        push @bind, ($start, $end);
        $sql .= <<'SQL'
        AND event_time >= ?
        AND event_time <= ?
SQL
    }
    elsif($start)
    {
        my ($x, $unit) = _win_to_sql($window);

        push @bind, ($start, $start);
        $sql .= <<"SQL";
        AND event_time >= ?
        AND event_time <= DATE_ADD(?, INTERVAL $x $unit) 
SQL
    }
    elsif($end)
    {
        my ($x, $unit) = _win_to_sql($window);

        push @bind, ($end, $end);
        $sql .= <<"SQL";
        AND event_time >= DATE_SUB(?, INTERVAL $x $unit) 
        AND event_time <= ?
SQL
    }
    else
    {   # Sanity Check
        die 'Invalid params to '.$class.'->get_events_by_date()';
    }

    if (defined $active) {
        push @bind, $active;
        $sql .= "AND active = ?\n";
    }

    $sql .= 'ORDER BY event_time';

    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
 
    my @events = ();
    while (my $event_id = $sth->fetchrow_array())
    {
        my $event = MoneyTracker::EntryEvent->new(ID => $event_id);
        $event->retrieve(session => $self->session());
        push @events, $event;
    }
    return \@events;
}
sub _win_to_sql
{
    my $window = shift;
    my ($n, $unit) = ($window =~ /(\d*)(\w*)/);
    $unit = 'MINUTE' if $unit eq 'm';
    $unit = 'HOUR'   if $unit eq 'h';
    $unit = 'DAY'    if $unit eq 'd';
    $unit = 'YEAR'   if $unit eq 'y';
    return ($n, $unit);
}

sub get_users
{
    my $self  = shift;
    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh  = $self->session()->dbh();
    my %args  = @_;

    my $user_table   = MoneyTracker::User->DB_TABLE();
    my $budget_table = MoneyTracker::Budget->DB_TABLE();

    my $sql   = <<SQL;
    SELECT ${user_table}.ID FROM ${user_table} 
    JOIN budget_user_assoc as assoc 
    ON (${user_table}.ID = assoc.${user_table}_id) 
    WHERE assoc.${budget_table}_id = ?
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute($self->ID);
 
    my @users = ();
    while (my $user_id = $sth->fetchrow_array())
    {
        my $user = MoneyTracker::User->new(ID => $user_id);
        $user->retrieve(session => $self->session());
        push @users, $user;
    }
    return \@users;
}
sub get_external_entry_sources
{
    my $self = shift;
    return $self->_get_associated_objects('MoneyTracker::ExternalEntrySource');
}
sub get_imported_entries
{
    my $self = shift;
    return $self->_get_associated_objects('MoneyTracker::ImportedEntry', {status => 'new'});
}
sub get_funds
{
    my $self = shift;
    return $self->_get_associated_objects('MoneyTracker::Fund');
}

1;   
