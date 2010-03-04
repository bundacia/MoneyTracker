package MoneyTracker::API;

use base qw(CGI::Application);

use strict;

use MoneyTracker::User;
use MoneyTracker::Budget;
use MoneyTracker::Fund;
use MoneyTracker::Session;
use MoneyTracker::Error;
use MoneyTracker::Entry;
use MoneyTracker::Entity;
use MoneyTracker::Tag;
use MoneyTracker::EntryEvent;
use MoneyTracker::Entry;

use CGI::Carp qw(fatalsToBrowser);
use CGI::Application::Plugin::Config::YAML;
use DBI;
use Date::Format qw(time2str);
use Data::Dumper;
use English qw( -no_match_vars );
use XML::Simple;
use Log::Log4perl;

use constant PUBLIC_RUN_MODES  =>  {
                                    debug            => 'debug',
                                    login            => 'login',
                                    config           => 'config',
                                    run_event_proc   => 'run_event_proc',
                                    quick_entry      => 'quick_entry',
                                   };
use constant PRIVATE_RUN_MODES =>  {
                                    private      => 'debug',
                                    test_login   => 'debug',
                                    logout       => 'logout',
                                    list_budgets => 'list_budgets', 
                                    load_budget  => 'load_budget',

                                    get_entries           => 'get_entries',
                                    get_imported_entries  => 'get_imported_entries',
                                    get_funds             => 'get_funds',
                                    get_events            => 'get_entry_events',
                                    get_entry_events      => 'get_entry_events',
                                    create_object         => 'create_object',
                                    edit_object           => 'edit_object',
                                    delete_object         => 'delete_object',
                                    import_entry          => 'import_entry',

                                    ac_entity => 'autocomplete_entity',
                                   };

#########################################
# setup 
#########################################
sub setup 
{
    my $self = shift;
    my $base_dir = $self->param('base_dir');

    # Get the config
    eval
    {
        $self->config_file( $self->param('config_file') );
        $self->config_fold(base_dir => $base_dir);
        $self->{conf} = $self->config_param();
    }; die "Error occured getting the configuration. [$@]" if ($@);

    # Set defaults from the config
    $self->start_mode('debug');     
    $self->mode_param('m');

    # Force mode param into the param() hash even if this is a POST
    my $q = $self->query();
    $q->param('m', $q->url_param('m')) if $q->url_param('m');

    #$self->error_mode(sub {return "<error_mode_called>how'd you get here?</error_mode_called>";});
    $self->run_modes( %{&PUBLIC_RUN_MODES}, %{&PRIVATE_RUN_MODES} );

    Log::Log4perl::init(\$self->{conf}{LogConfig});

    $self->{log} = Log::Log4perl->get_logger();
}
#########################################
# cgiapp_prerun 
#########################################
sub cgiapp_prerun 
{
    my $self = shift;
    my $rm = $self->get_current_runmode();
    my $q  = $self->query();

    # Connect to the database and get the database handel  
    my $dbh = DBI->connect(
        'dbi:mysql:'.$self->{conf}{db}{db}.':'.$self->{conf}{db}{host},
        $self->{conf}{db}{user}, 
        $self->{conf}{db}{password},
        { RaiseError => 1, AutoCommit => 1 }
    ) 
    or die "Error connecting to database $!";

    $self->{session} = MoneyTracker::Session->new( dbh => $dbh );

    $self->header_type('header');
    $self->header_props(-type=>'application/xml');

    $self->_check_login();    

    if ($rm eq 'quick_entry') {
        $self->_quick_entry_prerun();
    }

}
#########################################
# debug
#########################################
sub debug
{
    my $self = shift;
    my $rm   = $self->get_current_runmode();

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    return $self->_prep_xml("1");

}
#######################################
# login
#######################################
sub login
{
    my $self = shift;
    my $rm   = $self->get_current_runmode();
    my $q    = $self->query();
    my $user_name = $q->param('user_name'); 
    my $password  = $q->param('password'); 
    my $user;
    my $login_err;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        $user = MoneyTracker::User->new(user_name => $user_name);
        $user->retrieve(session => $self->{session});

        if( $user->check_password($password) )
        {

            my $budget = @{$user->get_budgets()}[0];
            my $c = $q->cookie(-name    => $self->{conf}{cookie_name},
                               -value   => $user_name.'|'.$budget->ID(),
                               -expires => '+1d',
                               -path    => '/',
                               -domain  => $self->{conf}{domain},
                              );
            $self->header_props($self->header_props(),-cookie=>$c);

            $self->_log("[$user_name] logged in and was given cookie [".$self->{conf}{cookie_name}."][$c]");
            $self->_log("Password: [$password]");
            
        }
        else
        {
            # set error flag to a true value 
            $login_err = 'incorrect password';
        }
    };
    if($@ || $login_err)
    {
        chomp($@);
        $self->_log('Failed Login attempt ['.($user_name || '<none>').':'
                    .($password || '<none>').'] because "'.(($@)?$@:$login_err).'"');
        return $self->error( MoneyTracker::Error->new( msg => "Login Failed. Please double check your username and password and try again.", level => 5, code => 2,));
    }
    else
    {
        return $self->_prep_xml($user->get_xml());
    }
}
#########################################
# config
#########################################
sub config
{
    my $self = shift;
    my $config = '<MT_CODEBASE><![CDATA['. $ENV{MT_CODEBASE} .']]></MT_CODEBASE>'. 
                 '<MT_CONFIG><![CDATA['. $ENV{MT_CONFIG} .']]></MT_CONFIG>'; 
    return $self->_prep_xml($config);
}
#########################################
# logout
#########################################
sub logout
{
    my $self = shift;
    my $q = $self->query();

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    # Remove the cookie
    my $c = $q->cookie(-name=>  $self->{conf}{cookie_name},
                       -value=>'0',
                       -expires=>'-1d',
                       -path=>'/',
                       -domain=>$self->{conf}{domain},
                       );
    $self->header_props($self->header_props(),-cookie=>$c);

    return $self->_prep_xml('<success>1</success>');
}
#########################################
# list_budgets
#########################################
sub list_budgets
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $user = MoneyTracker::User->new(user_name => $s->user());  
        $user->retrieve(session => $s);
        $xml .= $_->get_xml() for @{$user->get_budgets()};
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while retrieving your information.', 
                                                       error => $@, 
                                                       level => 5, 
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }
}
#########################################
# load_budget
#########################################
sub load_budget
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $b_id = $q->param('b_id') || $s->budget_id();
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        # --------------------------------------------------------
        # save budget_id in cookie
        my $c = $q->cookie(-name    => $self->{conf}{cookie_name},
                           -value   => $s->user()->user_name().'|'.$b_id,
                           -expires => '+1d',
                           -path    => '/',
                           -domain  => $self->{conf}{domain},
                          );
        $self->header_props($self->header_props(),-cookie=>$c);
        $self->_log('['.$s->user().'] cookie set to ['.$c.']');
        # --------------------------------------------------------

        # --------------------------------------------------------
        # build xml data to return
        my $budget = MoneyTracker::Budget->new(ID => $b_id);
        $budget->retrieve(session => $s); 

        # get the budget_xml and split it into an array
        # we're splitting it so we can insert att the fund
        # objects in the middle
        my @budget_xml = split /\n/, $budget->get_xml();       

        # save the closing tag for the end
        my $budget_closing_tag = pop @budget_xml;

        # put it all together
        $xml = join "\n", @budget_xml;
        for my $fund (@{$budget->get_funds()})
        {
            $xml .= $fund->get_xml();        
        }
        $xml .= $budget_closing_tag;
        # --------------------------------------------------------
 
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while loading your budget.', 
                                                       error => $@, 
                                                       level => 5, 
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    } 

}
#########################################
# get_entry_events 
#########################################
sub get_entry_events
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $fund_id = $q->param('fund_id');
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $fund = MoneyTracker::Fund->new(ID => $fund_id);
        $fund->retrieve(session => $s); 
        
        # Check to make sure this fund is in the budget we're logged in to
        if ( $fund->budget_id() ne $s->budget_id() )
        {
            die 'The fund ['.$fund->name().'] (id: '.$fund->ID().') isn\'t in your budget (id: '.$s->budget_id().') it\'s in (id: '.$fund->budget_id().') !';
        }

        # get the fund_xml and split it into an array
        # we're splitting it so we can insert the event
        # objects in the middle
        my @fund_xml = split /\n/, $fund->get_xml();       

        # save the closing tag for the end
        my $fund_closing_tag = pop @fund_xml;

        my $events = $fund->get_events();

        # put it all together
        $xml .= join "\n", @fund_xml;
        my $event_xml;
        for my $event (@{$events})
        {
            $event_xml .= $event->get_xml() if $event->type() eq 'entry';       
        }
        $xml .= $event_xml;
        $xml .= $fund_closing_tag;
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured retrieving entry events.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# get_funds 
#########################################
sub get_funds
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $budget = MoneyTracker::Budget->new(ID => $s->budget_id());
        $budget->retrieve(session => $s); 
        
        for my $fund (@{$budget->get_funds()})
        {
            $fund->retrieve(session => $s);
            $xml .= $fund->get_xml();       
        }
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured retrieving the funds.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# get_entries
#########################################
sub get_entries
{
    my $self = shift;
    my $s    = $self->{session};

    my $q    = $self->query();
    my $f_id = $q->param('fund_id');
    my $m    = $q->param('month');
    my $y    = $q->param('year');

    my $xml = '';

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $budget = MoneyTracker::Budget->new(ID => $s->budget_id());
        $budget->retrieve(session => $s); 
      
        # If no fund_id provided use all the funds for this budget.
        my @fund_ids = $f_id ? ($f_id) : map {$_->ID} @{$budget->get_funds()};

        for my $fund_id (@fund_ids) {
            my $fund = MoneyTracker::Fund->new( ID => $fund_id );
            $fund->retrieve(session => $s);

            # get the fund_xml and split it into an array
            # we're splitting it so we can insert the entry
            # objects in the middle
            my @fund_xml = split /\n/, $fund->get_xml();       

            # save the closing tag for the end
            my $fund_closing_tag = pop @fund_xml;

            my $entries = $fund->get_entries_by_date(
                            start => $y .'-'.  $m      .'-01 00:00:00',
                            end   => $y .'-'. ($m + 1) .'-00 00:00:00'
                        );
            # put it all together
            $xml .= join "\n", @fund_xml;
            my $entry_xml;
            my $balance = $fund->value();
            for my $entry (@$entries)
            {
                $entry_xml .= $entry->get_xml();        
                $balance += $entry->amount();
            }
            $balance = sprintf "%.2f", $balance;      # format balance
            $balance = '0.00' if $balance == '-0.00'; # Fix negative zero
            $xml =~ s/(.*)>$/$1 balance="$balance">/; # add balance to XML
            $xml .= $entry_xml if $entry_xml;
            $xml .= $fund_closing_tag;
        }
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error(
            MoneyTracker::Error->new( 
                msg   => 'An error occured retrieving entries.',
                error => $@,
                level => 5,
                code  => 5,
            )
        );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

    return $xml;

}
#########################################
# get_imported_entries 
#########################################
sub get_imported_entries
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};

    my $xml = '';

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $budget = MoneyTracker::Budget->new(ID => $s->budget_id());
        $budget->retrieve(session => $s); 
        
        my $entries = $budget->get_imported_entries(session => $s);

        $xml .= $_->get_xml() for @$entries
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( 
            MoneyTracker::Error->new( 
                msg   => 'An error occured retrieving imported entries.',
                error => $@,
                level => 5,
                code  => 5,
            )
        );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# create_object
#########################################
sub create_object
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $obj_class = $q->param('class');
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $obj = $obj_class->new();
        for my $attr (keys %{$obj_class->CLASS_DB_ATTR()})
        {
            # set budget_id from session so people can't add
            # stuff to other peoples budgets
            if ($attr eq 'budget_id')
            {
                $obj->budget_id($s->budget_id());
            }
            # set user_id from session as well
            elsif ($attr eq 'user_id')
            {
                $obj->user_id($s->user()->ID());
            }
            # set all other attributes from params 
            else
            {
                $obj->$attr($q->param($attr));
            }
        }
        $obj->save(session => $s);

        $obj->retrieve();   
        # mysql formats some of the fields for us. Doing the
        # retrieve insures that we're sending back exactly 
        # what's stored in the db

        $self->_log('['.$obj_class.'] object created with ID ['.$obj->ID().'].');
        $xml = $obj->get_xml();
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while saving your data.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# edit_object
#########################################
sub edit_object
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $obj_class = $q->param('class');
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        # New and retrieve the object based on the Unique key that was given
        my $obj = $obj_class->new($obj_class->UNIQUE_KEY() => $q->param($obj_class->UNIQUE_KEY()));
        $obj->retrieve(session => $s);

        # Loop through each attribute passed in and set that attr for the object (except budget_id)
        for my $attr (keys %{$obj_class->CLASS_DB_ATTR()})
        {
            unless ($attr eq 'budget_id')
            {
                $obj->$attr($q->param($attr)) if defined $q->param($attr);
            }
        }
        $obj->save();

        $obj->retrieve();   
        # mysql formats some of the fields for us. Doing the
        # retrieve insures that we're sending back exactly 
        # what's stored in the db

        $self->_log('['.$obj_class.'] with '.$obj_class->UNIQUE_KEY().
                     ': ['.$q->param($obj_class->UNIQUE_KEY()).'] updated.');
        $xml = $obj->get_xml();
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while saving your data.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# delete_object
#########################################
sub delete_object
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $obj_class = $q->param('class');
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {
        my $obj = $obj_class->new($obj_class->UNIQUE_KEY() => $q->param($obj_class->UNIQUE_KEY()));
        $obj->retrieve(session => $s);
        $self->_log('['.$obj_class.'] with '.$obj_class->UNIQUE_KEY().
                     ': ['.$q->param($obj_class->UNIQUE_KEY()).'] deleted.');

        my $obj_xml = $obj->get_xml(); # Save the XML for this object

        $obj->delete();                # Delete the object

        $xml = $obj_xml;               # set the return XML to the XML of the deleted object
    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while saving your data.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# import_entry
#########################################
sub import_entry
{
    my $self = shift;
    my $q = $self->query();
    my $s = $self->{session};
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}){return $self->error($self->{ERROR});}

    eval
    {

        ## CREATE NEW ENTRY ##

        my $entry = MoneyTracker::Entry->new();
        for my $attr (keys %{MoneyTracker::Entry->CLASS_DB_ATTR()})
        {
            # set budget_id from session so people can't add
            # stuff to other peoples budgets
            if ($attr eq 'budget_id')
            {
                $entry->budget_id($s->budget_id());
            }
            # set user_id from session as well
            elsif ($attr eq 'user_id')
            {
                $entry->user_id($s->user()->ID());
            }
            # set all other attributes from params 
            else
            {
                $entry->$attr($q->param($attr));
            }
        }
        $entry->save(session => $s);

        $entry->retrieve();   
        # mysql formats some of the fields for us. Doing the
        # retrieve insures that we're sending back exactly 
        # what's stored in the db

        $self->_log('[MoneyTracker::Entry] object created with ID ['.$entry->ID().'].');

        ## UPDATE IMPORTED ENTRY ##

        # New and retrieve the object based on the Unique key that was given
        my $imported_entry = MoneyTracker::ImportedEntry->new(ID => $q->param('imported_entry_id'));
        $imported_entry->retrieve(session => $s);
        $imported_entry->status('imported');
        $imported_entry->save();

        $imported_entry->retrieve();   
        # mysql formats some of the fields for us. Doing the
        # retrieve insures that we're sending back exactly 
        # what's stored in the db

        $self->_log('Marked imported_entry with ID '.$imported_entry->ID.' as imported');
        $xml = $entry->get_xml() ."\n". $imported_entry->get_xml();

    };
    if ($@)
    {
        chomp($@);
        $self->_log('Error ['.$@.']');
        return $self->error( MoneyTracker::Error->new( msg => 'An error occured while saving your data.',
                                                       error => $@,
                                                       level => 5,
                                                       code => 5,
                                                     )
                           );
    }
    else
    {
        return $self->_prep_xml($xml);
    }

}
#########################################
# autocomplete_entity
#########################################
sub autocomplete_entity
{
    my $self    = shift;
    my $q       = $self->query();
    my $fund_id = $q->param('fund');
    my $like    = $q->param('q');
    my $s       = $self->{session};
    my $xml;

    # check for error in prerun
    if (exists $self->{ERROR}) {
        $self->error($self->{ERROR}); 
        return '';
    }

    $self->header_props(-type=>'text/html');

    my $fund = MoneyTracker::Fund->new(ID => $fund_id);
    $fund->retrieve(session => $s);

    return unless $fund->budget_id eq $s->budget_id;

    my $entities = $fund->get_entities(like => $like, recent_days => 365);

    return join("\n",@$entities);
}
#########################################
# _check_login
#########################################
sub _check_login
{
    my $self = shift;
    my $rm   = $self->get_current_runmode();
    my $q    = $self->query();
    my $cn   = $self->{conf}{cookie_name};

    unless (${&PUBLIC_RUN_MODES}{$rm})
    {
        $self->_log("Getting Cookie...");

        my $c = $q->cookie($cn);

        # IF no cookie at all (or blank cookie)
        unless( $c )
        {
           $self->_log("ERROR: User attempted to access [$rm] without cookie.");
           $self->{ERROR} =  MoneyTracker::Error->new( 
                                         msg => "Access Denied",
                                         error => "You must be logged in to access this feature.",
                                         level => 5, code  => 1,
                                         ); 
           return;
        }

        # IF Cookie
        my ($user_name,$budget) = ($c =~ /(\w*)\|(\d*)/);

        $self->_log("User: $user_name");
        $self->_log("Budget: $budget");

        # IF Cookie exists AND is the right format
        if( $user_name && ($budget > -1) )
        {
            $self->{session}->budget_id($budget);

            my $user = MoneyTracker::User->new(user_name => $user_name);
            $user->retrieve(session => $self->{session});

            $self->{session}->user($user);
            $self->_log("User [$user_name] is logged in to budget [$budget].");
        }
        # IF Cookie exists but has bad format
        else
        {
           $self->_log("ERROR: Bad cookie! [$c]");
           $self->{ERROR} =  MoneyTracker::Error->new( 
                                         msg => "Access Denied",
                                         error => "Bad cookie sent. [$cn] = [$c].",
                                         level => 5, code  => 5,
                                         ); 
        }
    }
}

#########################################
#  _quick_entry_prerun
#########################################
sub _quick_entry_prerun
{
    my $self = shift;
    my $q    = $self->query();
    my $s    = $self->{session};

    # Change the runmode
    $self->prerun_mode('create_object');

    # Parse out the From address
    require Email::Address;
    my @addresses = Email::Address->parse($q->param('From'));
    my $auth_email = $addresses[0]->address();

    # Pull up that user
    my $user = MoneyTracker::User->new(auth_email => $auth_email); 
    $user->retrieve(session => $s);
   
    # Store the user and budget_id in the session
    $s->user( $user );
    my $budget_id = $user->get_budgets()->[0]->ID();
    $s->budget_id( $budget_id );

    $self->_log("User [".$user->user_name()."] is logged in to budget [$budget_id] for a quick entry.");

    # Parse the e-mail body for instructons
    my $entry = $self->_parse_quick_entry( $q->param('Body') );

    # Get fund_id
    my $sth = $s->dbh->prepare('SELECT ID FROM '.MoneyTracker::Fund->DB_TABLE.' WHERE LOWER(name) = ? AND budget_id = ?');
    $sth->execute( lc($entry->{fund}), $s->budget_id() );  
    my $row = $sth->fetchrow_hashref();

    $self->{ERROR} = MoneyTracker::Error->new( 
        msg   => "[$entry->{fund}] isn't a valid fund name in this budget.", 
        level => 5, 
        code  => 5,
    ) and return if (! defined $row);

    my $fund_id = $row->{ID};

    my $today = time2str('%Y/%m/%d', time);
    $q->param('entity'     , $entry->{ entity } || ''            );
    $q->param('amount'     , $entry->{ amount } || 0             );
    $q->param('description', $entry->{ desc   } || 'Quick Entry' );
    $q->param('date'       , $entry->{ date   } || $today        );
    $q->param('fund_id'    , $fund_id                            );
    $q->param('class'      , 'MoneyTracker::Entry'               );

}

#########################################
# _parse_quick_entry
#########################################
sub _parse_quick_entry {
    my $self = shift;
    my $text = shift;

    # This regex uses $LAST_REGEXP_CODE_RESULT (aka $^R) to keep track
    # of captures that would otherwise be lost since they occur in 
    # repreated blocks. $LAST_REGEXP_CODE_RESULT get's set to the
    # result of the last (?{}). 
    # See http://japhy.perlmonk.org/articles/tpj/2004-summer.html
    # (or google 'Regex Arcana') if this doesn't make sense.

    $text =~ /

    # initialize $LAST_REGEXP_CODE_RESULT (aka $^R) with an arrayref
    (?{ [] }) 

    \s*                         # optional whitespace
    ( [+-]?\d{1,}(?:\.\d\d?)? ) # An amount (-2.11, 10, etc) ($1)

    # Store the captured amount
    (?{ [ @$LAST_REGEXP_CODE_RESULT, 'amount' => "$1" ] })

    # Match, in any order, any number of pairs like the following:
    #  "at Panera Bread"
    #  "from Food"
    #  "for breakfast with peter"
    # Capture the keyword (eg: "at") and the value (eg: "Panera Bread")
    # appending them to an array stored in $LAST_REGEXP_CODE_RESULT
    (?:
      \s*              # optional whitespace
      (at|for|from|on) # a keyword ($2)
      \s+              # whitespace

      # everything up to the space before the next keyword ($3)
      ( 
        (?: (?! \s+ (?:at|for|from|on)) . )* 
      )

      # Store the captured values
      (?{ [ @$LAST_REGEXP_CODE_RESULT, $2 => $3 ] })
    )*

    # Assign the hash we've built to %1 so we can get to it
    # outside of this regex. Using %1 get's us around troublesome
    # 'use strict' issues because it one of those magic globals (used for $1)
    (?{ %1 = @$LAST_REGEXP_CODE_RESULT })

    /xi;

    require Date::Parse;
    import Date::Parse  qw(str2time);

    my $result = {
        fund   => $1{ from   },
        desc   => $1{ for    },
        entity => $1{ at     },
        # assume negative amount unless explicitly positive
        amount => ($1{amount} > 0 && $1{amount} !~ /^\+/)
                ? $1{amount} * -1
                : $1{amount},
        # if a date is given, force it to YYYY/MM/DD format
        # if the time given doesn't parse, use the current time
        date   => $1{on} 
                ? time2str( '%Y/%m/%d', (str2time($1{on})||time) ) 
                : undef,
    };

    return $result;
}

#########################################
# run_event_proc
#########################################
sub run_event_proc
{
    my $self = shift;
    my $proc_cmd = "MT_CODEBASE=$ENV{MT_CODEBASE} MT_CONFIG=$ENV{MT_CONFIG} $ENV{MT_CODEBASE}/bin/event_processor.pl";
    `$proc_cmd &`;
    return $self->_prep_xml('running');
}
#########################################
# error
#########################################
sub error
{
    my $self = shift;
    my $err = shift;
    my $rm = $self->get_current_runmode();
    my $error_xml;

    if (ref $err eq 'MoneyTracker::Error')
    {
        $error_xml = $err->get_xml(); 

        $self->_log('ERROR returned to user: '.
                'MSG: ['.($err->msg()   || '').'], '.
                'LEVEL: ['.($err->level() || '').'], '.
                'ERROR: ['.($err->error() || '').'], '.
                'CODE: ['.($err->code()  || '').'].');
    }else
    {
        $self->_log('ERROR returned to user: '.$err);
        $error_xml = "<error>$err</error>"; 
    }

    return $self->_prep_xml($error_xml);
}
#########################################
# _prep_xml
#########################################
sub _prep_xml
{
    
    my $self = shift;
    my $rm = $self->get_current_runmode();

    return "<$rm>".shift()."</$rm>";
}
#########################################
# _log
#########################################
sub _log
{
    my $self = shift;
    $self->{log}->info(@_);
}
1;
