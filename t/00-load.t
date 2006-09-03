#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );
