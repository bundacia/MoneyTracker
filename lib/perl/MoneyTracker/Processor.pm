package MoneyTracker::Processor;

use strict;

use DBI;
use Config::YAML;
use MoneyTracker::Session;
use File::Spec::Functions qw(catfile);

sub new
{
    my $class = shift;
    my %args = @_;
    return bless \%args, $class;
}
sub start
{
    my $self = shift;
    my %args = @_;

    $self->{conf} = Config::YAML->new( config =>  $self->{conf} );

    $self->_start_log();

    my $dbh = DBI->connect(
                           'dbi:mysql:'.$self->{conf}{db}{db}.':'.$self->{conf}{db}{host},
                           $self->{conf}{db}{user}, 
                           $self->{conf}{db}{password},
                           { RaiseError => 1, AutoCommit => 1 }
                          ) or die "Error connecting to database $!";

    $self->{session} = MoneyTracker::Session->new(dbh => $dbh); 

    eval 
    { 
        $self->_run(); 
    }; 
    if ($@) 
    { 
        $self->_log("Uncaught error in processor! [$@]"); 
        $self->_log("ENDING RUN"); 
    }

    $self->_stop_log();
}


#########################################
# _run 
#########################################
sub _run { }

#########################################
# _start_log
#########################################
sub _start_log
{
return; #DEBUG#    
    my $self = shift;
    my $class = ref $self;
    my $log_dir = $self->{conf}{log_dir};
    my $logfile = catfile($log_dir, $class.'.log');

    open LOG, '>>', $logfile or die "can't open log [$logfile] because $!";
}

#########################################
# _log
#########################################
sub _log
{
    my $self = shift;
    my $date = `date '+[\%D - \%T]'`;
    chomp($date);
#DEBUG#    print LOG $date . "$_\n" for @_;

#DEBUG#    if ($self->{debug})
#DEBUG#    {
        print $date . "$_\n" for @_;
#DEBUG#    }
}
#########################################
# _stop_log
#########################################
sub _stop_log
{
return; #DEBUG#    
    my $self = shift;
    close $self->{LOG};
}
1;
