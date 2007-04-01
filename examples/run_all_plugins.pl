#!/usr/bin/perl 
use strict;
use warnings;

# run this once all plugins have been configured
#  - see setup_ ... scripts
#
use sys::MON::Lite;

my $workdir = '/home/workdir';

my $sml = sys::MON::Lite->new({workdir=>$workdir});

$sml->run();

print "\nsummary:\n".$sml->output_plugin_summary()."\n\n";

print "status: [" . $sml->overall_status . "]\n";

