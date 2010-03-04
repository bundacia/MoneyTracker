package MoneyTracker::Processor::ImportEntries;

use strict;
use Data::Dumper;

use MoneyTracker::Session;
use MoneyTracker::User;

use base 'MoneyTracker::Processor';

#########################################
# _run 
#########################################
sub _run { 
    my $self = shift;
     
    $self->{user} = MoneyTracker::User->new(
                        user_name => $self->{conf}{ImportEntries}{user},
                        session   => $self->{session},
                  );
    eval { 
        $self->{user}->retrieve(); 
    };
    unless($@)  {

        # FOR EACH BUDGET
        my $budgets = $self->{user}->get_budgets();
        BUDGET: for my $budget (@$budgets) {

            $self->_log('Importing entries into budget ['.$budget->ID.' "'.$budget->name().'"]');
           
            my $sources;
            eval  {
                $sources = $budget->get_external_entry_sources(); 

                $self->_log('Found ['. scalar @$sources .'] external entry sources for this budget');
            };
            unless($@) {

                for my $source (@{$sources}) {

                    eval  { 
                        $source->import_entries();
                    };
                    if($@){ chomp($@); $self->_log("ERROR trying to import entries: [$@]"); }
                }
            }
            else { 
                chomp($@);
                $self->_log("ERROR trying to get external entry sources for budget [".$budget->name()."]: [$@]."); 
                next BUDGET;
            }
        }#END FOR EACH BUDGET
    }
    else  { 
        chomp($@);
        $self->_log("ERROR: Can't retrieve user with username [".$self->{conf}{EventProcessor}{user}."]",
                    "error was \"$@\"",   
                    "Check to make sure this is a valid user.");   
    }
}

1;
