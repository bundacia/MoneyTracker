package MoneyTracker::DBObject;

use strict;
use Data::Dumper;
use Date::Parse;
use SQL::Abstract;

use MoneyTracker::Session;

use constant CLASS_DB_ATTR => { }; 
use constant CLASS_DYNAMIC_ATTR => { }; 

use Class::MethodMaker
   [
      new    => [ -hash => -init => 'new' ],
      scalar => [qw/ID DB_TABLE UNIQUE_KEY IGNORE_DUPLICATES/],
      scalar => [qw/session sql_abs _before_save/],
   ];


##########################################
# init
##########################################
sub init
{
    my $self = shift;

    $self->sql_abs(SQL::Abstract->new());

    return $self->_init(@_);
}
##########################################
# retrieve
##########################################
sub retrieve
{
    my $self = shift;

    $self->_pre_retrieve(@_);
    $self->_do_retrieve(@_);
    $self->_post_retrieve(@_);
}
##########################################
# _do_retrieve
##########################################
sub _do_retrieve
{
    my $self = shift;
    my $class = ref $self;
    my %args = @_;
    my $sql_abs = $self->sql_abs();

    # Get session from args or object, or thow an error
    $self->session($args{session}) if defined $args{session};
    my $session = $self->session();
    unless( ref $session eq 'MoneyTracker::Session')
    {
        die $class.'->retrieve() called with no session available!';
    } 

    # Generate the where clause that will find the row for this object in the table
    my $where = 
        defined $args{$class->UNIQUE_KEY()}   ?  { $class->UNIQUE_KEY() => $args{$class->UNIQUE_KEY()}   } :
        defined $args{ID}                     ?  { ID                   => $args{ID}                     } :
        defined $self->{$class->UNIQUE_KEY()} ?  { $class->UNIQUE_KEY() => $self->{$class->UNIQUE_KEY()} } :
        defined $self->ID()                   ?  { ID                   => $self->ID()                   } :
                                                 die "No key or ID available to $class->retrieve"          ;

    # Generate the sql and bind vals
    my ($sql, @bind) = $sql_abs->select($class->DB_TABLE(), '*', $where);

    # Do the Query
    my $sth = $session->dbh()->prepare($sql);
    $sth->execute(@bind) or die $!;

    # Get the results
    my $hr = $sth->fetchrow_hashref();

    # Die if there were no results
    die 'No ['.$class.'] with '.(keys(%$where))[0].' ['.(values(%$where))[0].'] '
       .'was found in the database using the following sql query ['.$sql.']' 
       if ! $hr->{ID};

    # Otherwise, update object with the data from the db
    for my $k ('ID', keys %{$class->CLASS_DB_ATTR})
    {
        $self->$k($hr->{$k});
    }
}

##########################################
# save
##########################################
sub save
{
    my $self = shift;
    $self->_pre_save(@_);
    $self->_do_save(@_);
    $self->_post_save(@_);
}
##########################################
# _do_save
##########################################
sub _do_save
{
    my $self    = shift;
    my $class   = ref $self;
    my %args    = @_;
    my $sql_abs = $self->sql_abs();

    # Get session from args or object, or thow an error
    $self->session($args{session}) if defined $args{session};
    my $session = $self->session();
    unless( ref $session eq 'MoneyTracker::Session')
    {
        die $class.'->save() called with no session available!';
    } 

    # The where clause...
    my $where_row_is_for_this_object = 
        $self->ID 
         ? { ID                 => $self->ID                               } 
         : { $class->UNIQUE_KEY => $self->_format_attr($class->UNIQUE_KEY) }
        ;

    # Generate the sql and bind vals
    my ($sql, @bind) = $sql_abs->select($class->DB_TABLE(), ['*'], $where_row_is_for_this_object);

    # Do the Query
    my $ck_sth = $session->dbh()->prepare($sql);
    $ck_sth->execute(@bind) or die $!;
    my $existing = $ck_sth->fetchrow_hashref();

    my @k = keys %{$class->CLASS_DB_ATTR};

    # Update an existing record
    if ($existing && ($self->ID || $self->{$class->UNIQUE_KEY}) )
    {
        ## Save the old version
        $self->_before_save( $class->new(%$existing) );

        ## Build the SQL

        # The fields to update...
        my $fields;
        for(my $i=0; $i <= $#k; $i++)
        {
            my $isset = $k[$i].'_isset';
            next unless $self->$isset;
            $fields->{ $k[$i] } = $self->_format_attr($k[$i]);
        }
        
        # Generate the sql and bind vals
        my ($sql, @bind) = $sql_abs->update($class->DB_TABLE(), $fields, $where_row_is_for_this_object);

        # Do the Query
        my $sth = $session->dbh()->prepare($sql);
        $sth->execute(@bind) or die $!;
    }
    # Insert a new record
    else
    {
        ## Build the SQL
        push @k, 'ID';
        $sql  = 'INSERT'.($class->IGNORE_DUPLICATES ? ' IGNORE ' : ' ').'INTO ' . $self->DB_TABLE() . ' ';
        $sql .= '('.join(', ',@k).')';
        $sql .= ' VALUES ('.
            join( ',', map {'?'} @k )
        .')';

        # Get the bind values
        my @bind = map{ $self->_format_attr($_)} @k;

        # Do the Query
        my $sth = $session->dbh()->prepare($sql);
        $sth->execute(@bind) or die $!;

        # Get the ID of the new record and store in the Object
        $self->ID( $session->dbh()->last_insert_id(undef,undef,$self->DB_TABLE(),'ID') );
    }
}
##########################################
# _format_attr
##########################################
sub _format_attr
{
    my $self = shift;
    my $class = ref $self;
    my $a = shift;

    my %attr  = %{$class->CLASS_DB_ATTR};

    if ($attr{$a} eq 'date'  ) { 
        my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($self->$a);
        return ($year+1900)."-".($month+1)."-$day 12:00:00"; 
    }
    else{ 
        return $self->$a;   
    }
}
##########################################
# get_xml
##########################################
sub get_xml
{
    my $self = shift;
    my $class = ref $self;
    my $class_tag = $class;
    $class_tag =~ s/::/_/g;
    my $xml = "<$class_tag ";

    for my $attr ('ID', keys %{$class->CLASS_DB_ATTR})
    {
        $xml .= " $attr='".$self->_xml_format_attr($attr)."'";    
    }  
    $xml .= ">\n</$class_tag>\n";

    return $xml;
}
##########################################
# _xml_format_attr
##########################################
sub _xml_format_attr
{
    my $self = shift;
    my $class = ref $self;
    my $a = shift;

    my %attr  = %{$class->CLASS_DB_ATTR};

    if    (! defined $self->$a)  { return ''; }
    else
    { 
        my $fa = $self->$a;
        $fa =~ s/&/&amp;/g;
        $fa =~ s/'/&apos;/g;
        $fa =~ s/"/&quot;/g;
        return $fa; 
    }
}
##########################################
# _get_associated_objects
##########################################
sub _get_associated_objects
{
    my $self        = shift;
    my $assoc_class = shift;
    my $conditions  = shift || {};

    my $class       = ref $self;
    my $assoc_table = $assoc_class->DB_TABLE;
    my $session     = $self->session();
    my $sql_abs     = $self->sql_abs();

    unless( ref $session eq 'MoneyTracker::Session')
    {
        die $class.'->get_associated_objects() called with no session available!';
    } 

    my ($where_sql, @bind) = $sql_abs->where({
                               %$conditions, 
                               $self->DB_TABLE.'_id' => $self->ID
                           });

    my $sql = "SELECT * FROM $assoc_table $where_sql ORDER BY ID";

    my $sth = $session->dbh()->prepare($sql);
    $sth->execute(@bind) or die $!;

    my @kids = ();
    while (my $rec = $sth->fetchrow_hashref)
    {
        push @kids, $assoc_class->new(%$rec, session => $session);
    } 
    return \@kids;
}
##########################################
# _get_object_by_id
##########################################
sub _get_object_by_id
{
    my $self = shift;
    my $class  = ref $self;
    my ($assoc_class, $assoc_id) = @_;
    my $session = $self->session();
    die 'No session found!' unless( ref $self->session() eq 'MoneyTracker::Session' );
    my $dbh  = $self->session()->dbh();

    my $obj = $assoc_class->new(ID => $assoc_id);
    $obj->retrieve(session => $self->session());
    return $obj;
}
##########################################
# delete
##########################################
sub delete
{
    my $self = shift;
    $self->_pre_delete(@_);
    $self->_do_delete(@_);
    $self->_post_delete(@_);
}
##########################################
# _do_delete
##########################################
sub _do_delete
{
    my $self    = shift;
    my %args    = @_;
    my $class   = ref $self;
    my $table   = $class->DB_TABLE(); 
    my $ID      = $self->ID();
    my $sql_abs = $self->sql_abs();
    my $sth;

    # Get session from args or object, or thow an error
    $self->session($args{session}) if defined $args{session};
    my $session = $self->session();

    die $class.'->delete() called with no session available!'
        if ! ref $session eq 'MoneyTracker::Session';

    die 'Tried to delete a ['.$class.'] with no ID or '.$class->UNIQUE_KEY 
        if ! defined $self->ID() && ! defined $self->{$class->UNIQUE_KEY};

    my $where_row_is_for_this_object = 
        $self->ID 
         ? { ID                 => $self->ID                               } 
         : { $class->UNIQUE_KEY => $self->_format_attr($class->UNIQUE_KEY) }
        ;

    my ($sql, @bind) = $sql_abs->delete( $class->DB_TABLE(), $where_row_is_for_this_object );

    $sth = $session->dbh()->prepare($sql);
    return $sth->execute(@bind);
}

# These methods are just hooks for child classes
sub _init{}
sub _pre_save{}
sub _post_save{}
sub _pre_retrieve{}
sub _post_retrieve{}
sub _pre_delete{}
sub _post_delete{}

1;

