#!/usr/bin/perl

use strict;

use sys::MON::Lite;

my ( $manager_status, $result_status, $status_summary_string, $content );

my %settings = ( configfile => 'websitecheck.cfg' );

my $plugin_manager = sys::MON::Lite->new(workdir=>'/home/jon/settings/');

( $manager_status, $result_status, $status_summary_string, $content ) =
  $plugin_manager->run;

print "MOTOR\n\nmanager_status:$manager_status\n";
print "result_status:$result_status\n";
print "status_summary_string:$status_summary_string\n";
print "content:\n$content\n";

