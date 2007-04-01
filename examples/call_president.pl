#!/usr/bin/perl 
#===============================================================================

use strict;
use warnings;
use IO::CaptureOutput qw(capture capture_exec qxx);
use Net::SMTP;

use Log::Log4perl qw(:easy);

my $message_to_president = shift || 'no message to report';

Log::Log4perl->easy_init( { level   => $DEBUG,
	                        file    => ">>/tmp/log" } );

DEBUG "call president called with [$message_to_president]";

#
# replace 'nefarious_service' with the name of the service you want to kicked
# or alternatively replace the whole command with something more tailored
# to your needs
#
my $com='/etc/init.d/nefarious_service stop ; /etc/init.d/nefarious_servic start';

my $to = 'president@your.company.net';
my $from = 'robot@your.server.net';
my $subject = 'AUTO RESTART of your nefarious service - ' . $message_to_president;

my ($stdout, $stderr);
my @args;

capture sub {command()}, \$stdout, \$stderr;

sub command {
        system($com);
}

my $smtp = Net::SMTP->new('some.smtphost.net', Debug => 0, Timeout => 300);

$smtp->mail($from);
$smtp->to($to);

$smtp->data();
$smtp->datasend("To: $to\n");
$smtp->datasend("From: $from\n");
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n");
$smtp->datasend("[command]:\n$com\n");
$smtp->datasend("[stdout]:\n$stdout\n");
$smtp->datasend("[stderr]:\n$stderr\n");
$smtp->dataend();

$smtp->quit;

