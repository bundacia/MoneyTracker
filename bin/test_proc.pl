#!/usr/bin/perl -w
use lib '/home/tlittle/scripts/MoneyTracker/lib/perl';
use MoneyTracker::Processor::TEST;

my $test = MoneyTracker::Processor::TEST->new(conf => '/home/tlittle/scripts/MoneyTracker/conf/conf.xml');

$test->start();

 
