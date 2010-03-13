#! /usr/bin/perl

use strict;
use warnings;

use lib $ENV{MT_CODEBASE}.'/lib/perl';
use MoneyTracker::API; 

eval { 
    my $api = MoneyTracker::API->new(
        PARAMS => {
            base_dir     => $ENV{MT_CODEBASE}.'/'         ,
            config_file  => $ENV{MT_CONFIG}  .'_conf.yaml',
        },
    );
    $api->run(); 
};
if ($@) {
    print 
         "Content-type: text/html\n\n"
        ."<pre>$@</pre>\n";
}

1;
