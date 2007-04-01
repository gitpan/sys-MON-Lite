#!/usr/bin/perl 
use strict;
use warnings;

use sys::MON::Lite;

my $workdir = '/home/workdir';

my $sml = sys::MON::Lite->new({workdir=>$workdir});

# fill in the **** bits and set a proper host name
my %run_params = (
    user                  => '****',
    timeout               => 10,
    password              => '****',
    host                  => 'some host somewhere',
    command               => '/opt/tools/call_president "POP3 Check Failed"',
    skip_command_n_times  => 3,
    run_only_after_n_mins => 30,
);

$sml->run({
    plugins            =>'POP::SimplePOPCheck', 
    params             =>\%run_params, 
    plugin_search_path => 'sys::MON::Lite::Plugin',
});

print "content: \n" . $sml->content . "\n" if $sml->content;

print "status: [" . $sml->overall_status . "]\n";
