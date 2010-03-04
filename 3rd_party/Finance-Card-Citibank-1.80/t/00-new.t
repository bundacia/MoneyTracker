#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;

# Test set 1 -- can we load the library?
BEGIN { use_ok( 'Finance::Card::Citibank' ); };


