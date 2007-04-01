#!/usr/bin/perl 
use strict;
use warnings;

use sys::MON::Lite;

my $workdir = '/home/workdir';

my $sml = sys::MON::Lite->new({workdir=>$workdir});

# fill in the '***' bits and a proper host name
my %run_params = (
    enabled               => 1,
    user                  => '****',
    password              => '****',
    host                  => 'some host somewhere',
);

$sml->run({
    plugins            =>'IMAP::SimpleIMAPCheck', 
    params             =>\%run_params, 
});

print "content:[" . $sml->content."]\n";
print "summary:[" . $sml->summary ."]\n";

print "status: [" . $sml->overall_status . "]\n";


