package MoneyTracker::Processor::EventProcessor;

use strict;
use Date::Calc qw/Add_Delta_DHMS Add_Delta_YM/;
use Data::Dumper;

use MoneyTracker::Session;
use MoneyTracker::User;
use MoneyTracker::EntryEvent;

use base 'MoneyTracker::Processor';

#########################################
# _run 
#########################################
sub _run 
{ 
    my $self = shift;
     
    $self->{user} = MoneyTracker::User->new(user_name => $self->{conf}{EventProcessor}{user},
                                            session   => $self->{session},
                                           );
    eval
    { 
        $self->{user}->retrieve(); 
    };
    unless($@)  
    {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        my $now = sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;

        # FOR EACH BUDGET
        my $budgets = $self->{user}->get_budgets();
        BUDGET: for my $budget (@$budgets)
        {
            $self->_log('Getting events for budget ['.$budget->ID.' "'.$budget->name().'"]');
           
            my $events;
            eval  
            {
                $events = $budget->get_events_by_date(
                                                      end    => $now, 
                                                      window => $self->{conf}{EventProcessor}{window},
                                                      active => 1,
                                                     ); 
                $self->_log('Found ['. scalar @$events .'] events for this budget');
            };
            unless($@)
            {
                for my $event (@{$events})
                {
                    $self->_process_entry_event($event)    if $event->type() eq 'entry';    
                    $self->_process_rollover_event($event) if $event->type() eq 'rollover';    

                    # Update and Save the event
                    eval  
                    { 
                        if ($event->recurrence())
                        {
                            $event->update_time(); 
                            $self->_log('Scheduling this event to run again at ['.$event->event_time().'].'); 
                        }
                        else
                        {
                            $event->active(0);
                            $self->_log('No recurrance for this event. De-activating'); 
                        }
                        $event->save();
                    };
                    if($@){ chomp($@); $self->_log("ERROR trying to save event: [$@]"); }
                }
            }
            else
            { 
                chomp($@);
                $self->_log("ERROR trying to get events for budget [".$budget->name()."]: [$@]."); 
                next BUDGET;
            }
        }#END FOR EACH BUDGET
    }
    else  
    { 
        chomp($@);
        $self->_log("ERROR: Can't retrieve user with username [".$self->{conf}{EventProcessor}{user}."]",
                    "error was \"$@\"",   
                    "Check to make sure this is a valid user.");   
    }
}
sub _process_entry_event
{
    my $self = shift;
    my ($event) = @_;

    my $new_entry   = MoneyTracker::Entry->new(session => $self->{session}); 
    $new_entry->fund_id    ( $event->fund_id()     );
    $new_entry->date       ( $event->event_time()  );
    $new_entry->user_id    ( $event->user_id()     );
    $new_entry->amount     ( $event->amount()      );
    $new_entry->entity     ( $event->entity()      );
    $new_entry->description( $event->description() );

    # Save the entry
    eval  
    { 
        $new_entry->save(); 
        $self->_log('Added new entry ['. $new_entry->description() .'] to fund ['. $new_entry->fund_id() .'].');
    };
    if($@){ chomp($@); $self->_log("ERROR trying to save new entry: [$@]."); }
}
sub _process_rollover_event
{
    my $self = shift;
    my ($event) = @_;
    
    
    # Retrieve the fund
    my $fund = MoneyTracker::Fund->new(ID => $event->fund_id(), session => $self->{session}); 
    eval $fund->retrieve();
    if($@){ chomp($@); $self->_log("ERROR trying to retrieve fund with ID [".$event->fund_id()."]: [$@]."); }
    
    # Get the year, month, and day of the event
    my @event_YMD = ($event->event_time() =~ /(\d*)-(\d*)-(\d*) \d\d:\d\d:\d\d/);
    # Get the year and month of "last month"
    my ($year,$month) = Add_Delta_YM(@event_YMD, 0, -1);
    # Get last month's remaining balance
    $self->_log('Getting remailing balance for month: ['.$month.'], year: ['.$year.']');
    my $rollover_amount = $fund->get_balance(year => $year, month => $month);   

    my $new_entry   = MoneyTracker::Entry->new(session => $self->{session}); 
    $new_entry->fund_id    ( $event->fund_id()                );
    $new_entry->date       ( $event->event_time()             );
    $new_entry->user_id    ( $self->{user}->ID()              );
    $new_entry->amount     ( $rollover_amount                 );
    $new_entry->entity     ( 'ROLLOVER'                       );
    $new_entry->description( 'AUTO ROLLOVER: '.$event->name() );

    # Save the entry
    eval  
    { 
        $new_entry->save(); 
        $self->_log('Added new entry ['. $new_entry->description() .'] to fund ['. $fund->name(). '].');
    };
    if($@){ chomp($@); $self->_log("ERROR trying to save new entry: [$@]."); }
}
1;
