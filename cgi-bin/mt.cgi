#! /usr/bin/perl -w

use strict;

use lib $ENV{MT_CODEBASE}.'/lib/perl';
use MoneyTracker::API; 
my $base_dir = $ENV{MT_CODEBASE}.'/';
my $api = MoneyTracker::API->new(
                        PARAMS => {
                                    base_dir     => $base_dir,
                                    config_file  => $ENV{MT_CONFIG}.'_conf.xml',
                                 },
                        );
eval 
{ 
    $api->run(); 
};
if ($@)
{
    print <<EOE;
Content-type: text/html

    $@
EOE
}
    #<UNCAUGHT_ERROR><![CDATA[
    #]]></UNCAUGHT_ERROR>
1;
