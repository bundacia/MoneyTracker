package MoneyTracker::User;

use strict;
use lib '/home/tlittle/codebase/MoneyTracker/lib/perl';
use base 'MoneyTracker::DBObject';
use MoneyTracker::Budget;
use MoneyTracker::Session;
use Data::Dumper;

use constant CLASS_DB_ATTR => {
           user_name   => 'string',
           email       => 'string',
           auth_email  => 'string',
           first_name  => 'string',
           last_name   => 'string',
           address1    => 'string',
           address2    => 'string',
           city        => 'string',
           state       => 'string',
           zipcode     => 'int',
           country     => 'string',
           phone       => 'string',
           gender      => 'string',
           type        => 'int',
         };

use constant SUPER_USER => '0';
use constant BASIC_USER => '1';

use Class::MethodMaker
   [
      scalar => [keys %{&CLASS_DB_ATTR}],
      scalar => [{ -static => '1', -default => 'user' }, 'DB_TABLE'], 
      scalar => [{ -static => '1', -default => 'user_name' }, 'UNIQUE_KEY'], 
   ];

sub _pre_retrieve {
    my $self    = shift;
    my $class   = ref $self;
    my %args    = @_;
    my $sql_abs = $self->sql_abs(); #TODO: actually use this

    # Get session from args or object, or thow an error
    $self->session($args{session}) if defined $args{session};
    my $session = $self->session();
    unless( ref $session eq 'MoneyTracker::Session')
    {
        die $class.'->retrieve() called with no session available!';
    } 

    # get an auth_email, bail if none, or if you have an id or user_name
	return if $self->ID();
	return if $self->user_name();
    my $auth_email = $args{auth_email} || $self->auth_email();
    return unless $auth_email;

    # Grab and set the username based on auth_email is present
    my $sth = $self->session()->dbh->prepare('SELECT user_name FROM '.$class->DB_TABLE.' WHERE LCASE(auth_email) = LCASE(?)');
    $sth->execute($auth_email);  
    my $row = $sth->fetchrow_hashref();

	die "$auth_email is not an authorized e-mail for any account\n" unless $row;

    $self->user_name( $row->{user_name} ) if $row;
}

sub set_password
{
    my $self = shift;

    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh  = $self->session()->dbh();
    my $pass = shift;
    my $salt = sprintf '%s%s', ((split //, time)[-2,-1]);
    my $crypt_pass = crypt($pass, $salt);
    my $sql = ' UPDATE '        .$self->DB_TABLE.
              ' SET password=\''.$crypt_pass.'\''.
              ' WHERE ID = '    .$self->ID;


    my $sth = $dbh->prepare($sql);
    $sth->execute();
}
sub check_password
{
    my $self = shift;

    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh  = $self->session()->dbh();
    my $test = shift;
    my $sql = ' SELECT password FROM '.$self->DB_TABLE.
              ' WHERE ID = '          .$self->ID;
    my $sth = $dbh->prepare($sql);
    $sth->execute();  
    my $crypt_pass = ${$sth->fetchrow_hashref()}{password}; return crypt($test, $crypt_pass) eq $crypt_pass;
}
sub password 
{
    # we have to put this here to keep
    # Class::MethodMaker happy. Otherwise it will
    # cause an error when MoneyTracker::DBObject
    # tries to new() a User in the get_children method
    # and passes in all the colums of the DB.  
}
sub get_budgets
{
    my $self = shift;
    my $class = ref $self;
    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh  = $self->session()->dbh();
    
    my $sql = 'SELECT ID FROM '. MoneyTracker::Budget->DB_TABLE;
    # Unless this is a super user (which will get all budgets)
    # add a WHERE clause to limit the select to this users 
    # associated budgets
    unless($self->type() eq SUPER_USER)
    {
       $sql .= ' WHERE ID IN (SELECT budget_id FROM budget_user_assoc WHERE user_id = '.$self->ID.' )';
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $!;

    # Create an array of MoneyTracker::Budget Objects
    my @budgets = ();
    while (my $budget_id = $sth->fetchrow_array)
    {
        my $budget = MoneyTracker::Budget->new(ID => $budget_id, session => $self->session());
        $budget->retrieve();
        push @budgets, $budget;
    } 
    return \@budgets;
}
1;
