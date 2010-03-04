package MoneyTracker::Entry;

use strict;

use base 'MoneyTracker::DBObject';

use constant CLASS_DB_ATTR => { 
    fund_id     => 'int',
    user_id     => 'int',
    date        => 'date',
    amount      => 'float',
    entity      => 'string', 
    description => 'string',
};

use Class::MethodMaker [
    scalar => [keys %{&CLASS_DB_ATTR}],
    scalar => [{ -default => 'entry' }, 'DB_TABLE'], 
    scalar => [{ -static => '1', -default => 'ID' }, 'UNIQUE_KEY'], 
];

sub get_fund {
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::Fund', $self->fund_id);
}

sub get_user {
    my $self = shift;
    return $self->_get_object_by_id('MoneyTracker::User', $self->user_id);
}

sub _post_delete {
    my $self = shift;
    $self->_adjust_later_rollovers( - $self->amount );
}

sub _post_save {
    my $self = shift;

    my $adjust_amount;
    if ($self->_before_save) {
        $adjust_amount = $self->amount - $self->_before_save->amount;
        $self->_before_save(undef);
    }
    else {
        $adjust_amount = $self->amount;
    }

    $self->_adjust_later_rollovers($adjust_amount);
}

sub _adjust_later_rollovers {
    my $self    = shift;
    my $class   = ref $self;
    my $amount  = shift;
    my $sql_abs = $self->sql_abs();
    my $session = $self->session();
 
    my($sql, @bind) = $sql_abs->update(
        # Table
        $class->DB_TABLE(), 
        # Fields
        { amount => ['amount + '.int($amount)] }, 
        # Where
        {
            fund_id  => $self->fund_id                      ,
            date     => { '>', $self->_format_attr('date') },
            entity   => 'ROLLOVER'                          ,
        },
    );

    $session->dbh()->do($sql, {}, @bind);
}
1;   
