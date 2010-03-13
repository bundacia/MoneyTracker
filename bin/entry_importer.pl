#!/usr/bin/perl
use lib $ENV{MT_CODEBASE}.'/lib/perl';
use MoneyTracker::Processor::ImportEntries;

my $processor = MoneyTracker::Processor::ImportEntries->new(
                  conf => $ENV{MT_CONFIG}, 
                  debug => 0,
              );

$processor->start();
