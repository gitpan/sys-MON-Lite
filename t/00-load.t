
use Test::More tests => 9;

BEGIN {
use_ok( 'sys::MON::Lite::Core::Plugin::Base');
use_ok( 'sys::MON::Lite::Store::DBMDeep');
use_ok( 'sys::MON::Lite::Plugin::HTTP::SimpleURLCheck');
use_ok( 'sys::MON::Lite::Plugin::SMTP::ServiceSMTPPOPCheck');
use_ok( 'sys::MON::Lite::Plugin::IMAP::SimpleIMAPCheck');
use_ok( 'sys::MON::Lite::Plugin::POP::SimplePOPCheck');
use_ok( 'sys::MON::Lite::Store');
use_ok( 'sys::MON::Lite::Util');
use_ok( 'sys::MON::Lite');
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );



