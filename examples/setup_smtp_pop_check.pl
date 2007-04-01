#!/usr/bin/perl 
use strict;
use warnings;

use sys::MON::Lite;

my $workdir = '/home/workdir';

my $sml = sys::MON::Lite->new({workdir=>$workdir});

# fill in the *** bits and set a proper smtp host and pop host name that 
# can be used to recieve the mail sent to the smtp host
  my %run_params = (
                   host => 'some smtp host somewhere',
                timeout => 30,
                subject => 'smtp_pop check - automated mail test',
                     to => 'test',
                pophost => 'pop host that recieves messages from smtp host',
                popuser => '****',
                poppass => '****',
             poptimeout => 30,
                command => '/opt/tools/call_president',
   skip_command_n_times => 3,
  run_only_after_n_mins => 30,

  );

  $sml->run({
    plugins            =>'SMTP::ServiceSMTPPOPCheck',
    params             =>\%run_params, 
    plugin_search_path => 'sys::MON::Lite::Plugin'
  });

print "\nsummary:[".$sml->summary()."]\n\n";
print "content:\n\n" . $sml->content."\n";
