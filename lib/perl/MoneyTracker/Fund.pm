package MoneyTracker::Fund;

use strict;

use MoneyTracker::Entry;
use MoneyTracker::Budget;
use MoneyTracker::Session;

use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => {
                                'name'      => 'string',
                                'value'     => 'string',
                                'budget_id' => 'int',
                                'rollover'  => 'int',
                              };
use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'fund' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
   ];

sub get_entries_by_date
{
    my $self    = shift;
    my $class   = ref $self;
    my $session = $self->session();
    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh   = $self->session()->dbh();
    my %args  = @_;
    my $start = $args{start};
    my $end   = $args{end};

    my $entry_table = MoneyTracker::Entry->DB_TABLE();
    my $fund_table  = MoneyTracker::Fund->DB_TABLE();
    my $ID = $self->ID();

    my @bind = ($ID, $start, $end);
    my $sql  = <<"SQL";
    SELECT ${entry_table}.ID FROM $entry_table 
    JOIN $fund_table ON ($entry_table.${fund_table}_id = fund.ID)
    WHERE fund_id = ?
    AND date >= ?
    AND date <= ?
    ORDER BY date
SQL

    my $sth = $session->dbh()->prepare($sql);
    $sth->execute(@bind);
 
    my @entries = ();
    while (my $entry_id = $sth->fetchrow_array())
    {
        my $entry = MoneyTracker::Entry->new(ID => $entry_id);
        $entry->retrieve(session => $self->session());
        push @entries, $entry;
    }
    return \@entries;
}
sub get_events
{
    my $self = shift;
    return $self->_get_associated_objects('MoneyTracker::EntryEvent');
}
sub get_budget
{
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Budget', $self->budget_id);
}
sub get_balance
{
    my $self = shift;
    my $balance = $self->value();
    my %args  = @_;
    my $month = $args{month};
    my $year  = $args{year};
    
    my $entries = $self->get_entries_by_date(
                                              start => $year .'-'.  $month      .'-01 00:00:00', 
                                              end   => $year .'-'. ($month + 1) .'-00 00:00:00'
                                            );
    for my $entry (@{$entries})
    {
        $balance += $entry->amount();
    }

    return $balance;
}
sub get_entities {
    my $self  = shift;
    my %args  = @_;
    my $like  = $args{like};
    my $recent_days = $args{recent_days};

    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh     = $self->session()->dbh();
    my $sql_abs = $self->sql_abs();

    my $date_limit = "AND date > now() - interval $recent_days day" if ($recent_days =~ /^\d+$/);

    my $sql = <<"SQL";
    SELECT entity, count(*)
    FROM entry
    WHERE 
        fund_id = ?
        AND LOWER(entity) like ?
        $date_limit
    GROUP BY entity 
    HAVING count(*) > 1
SQL

    my @bind = ($self->ID(), lc($like).'%');
    warn "$sql".join(', ',@bind)."\n";#DEBUG#

    my $matches = $dbh->selectcol_arrayref($sql, {}, @bind);

    return $matches;
}

################################################
# _post_save
################################################
sub _post_save
{
    my $self = shift;
    $self->_save_rollover();
}
################################################
# _save_rollover
################################################
sub _save_rollover
{
    my $self = shift;
    my $rollover = $self->rollover();
    my $s = $self->session();
    my @rollover_events;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    my $events = $self->get_events();

    # get a list of all the rollover_events
    for my $event (@$events)
    {
        push @rollover_events, $event if( $event->type() eq 'rollover' && $event->active() );
    }
    if ($#rollover_events > -1)                        # If there are rollover events...
    {
        if ($rollover =~ /false|0|/)                   #    but if you're removing a rollover...
        {
            for (@rollover_events)
            {
                $_->delete(session => $s)              #    remove them.
            }
        }
    }
    else                                               # If there are NOT rollover events...
    {
        if ($rollover =~ /true|1/)                     #    and you are trying to add a rollover...
        {
                                                       #    add one.
            my $ro_event = MoneyTracker::EntryEvent->new(session => $s);
            $ro_event->budget_id($s->budget_id());
            $ro_event->fund_id($self->ID());
            $ro_event->budget_id($self->budget_id());
            $ro_event->type('rollover');
            $ro_event->recurrence('month');
            $ro_event->frequency(1);
            $ro_event->name('Rollover from last month');
            my $next_month = ($year + 1900).'-'.($mon + 2).'-01 00:00:01';
            $ro_event->event_time($next_month);
            $ro_event->active(1);
            $ro_event->save();

        }
    }

    my $sql = 'UPDATE fund SET rollover = '.($rollover =~ /true|1/ ? '1' : '0').' WHERE ID = ?';
    # Do the SQL
    my $sth = $s->dbh()->prepare($sql);
    $sth->execute($self->ID) or die $!;

    $self->{rollover} = $rollover;
}
1;
