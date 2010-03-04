package MoneyTracker::ExternalEntrySource;

use strict;

use base 'MoneyTracker::DBObject';

use MoneyTracker::ImportedEntry;

use constant CLASS_DB_ATTR => { 
    budget_id => 'int'   ,
    user_name => 'string', 
    password  => 'string',
    class     => 'string',
};

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -default => 'external_entry_source' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
   ];

sub get_budget {
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Budget', $self->budget_id);
}

sub import_entries {
    my $self = shift;

    ################################################
    # TODO: 
    # This block should eventually be moved 
    # into a plugin to allow for more external sources.
    require Finance::Card::Citibank;
    my @entries = Finance::Card::Citibank->get_activity(
        username => $self->user_name,
        password => $self->password ,
    );

    my $citi2mysql_date = sub {
        my ($m,$d,$y) = split '/', shift;
        "$y-$m-$d";
    };

    my %dupe;
    for my $entry (@entries) {
        $entry->{entity} = $entry->{description};
        $entry->{amount} =~ s/\$//;
        $entry->{amount} *= -1;
        $entry->{date}   = $citi2mysql_date->($entry->{date});
        $entry->{source} = 'Citi Card';

        my $key = $entry->{entity}.$entry->{amount}.$entry->{date};
        $entry->{description} = $dupe{$key} ? 'imported ('.($dupe{$key}+1).')' : 'imported';
        $dupe{$key}++;
    }

    ##############################################

    for my $entry (@entries) {
        my $imported = MoneyTracker::ImportedEntry->new(
                         %$entry                      , 
                         budget_id => $self->budget_id,
                         status    => 'new'           ,
                         session   => $self->session  ,
                     );
        $imported->save();
    }
}
1;   
