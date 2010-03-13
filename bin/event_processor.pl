#!/usr/bin/perl
use lib $ENV{MT_CODEBASE}.'/lib/perl';
use MoneyTracker::Processor::EventProcessor;

my $processor = MoneyTracker::Processor::EventProcessor->new(
                  conf => $ENV{MT_CONFIG}, 
                  debug => 0,
              );

$processor->start();


