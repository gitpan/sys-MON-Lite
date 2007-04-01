#!/usr/bin/perl 
use strict;
use warnings;

use sys::MON::Lite;

my $workdir = '/home/workdir';

my $sml = sys::MON::Lite->new({workdir=>$workdir});

my %run_params = (
              address => 'http://www.yahoo.com',
              timeout => 30,
        search_string => 'html',
              command => '/opt/tools/call_president "the internet is broken"',
 skip_command_n_times => 3,
run_only_after_n_mins => 30,
);

$sml->run({
    plugins            =>'HTTP::SimpleURLCheck',
    params             =>\%run_params,
    plugin_search_path => 'sys::MON::Lite::Plugin',
});

print "\nsummary:\n".$sml->output_plugin_summary()."\n\n";

print "status: [" . $sml->overall_status . "]\n";

