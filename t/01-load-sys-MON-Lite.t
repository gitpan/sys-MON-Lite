#!perl 

use Test::More tests => 7;

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

my $sml = sys::MON::Lite->new();

ok($sml, 'new object created');
ok(($sml->manager_status == 1), 'status == 1');
my $status = $sml->overall_status || 0;
ok(($status == 0), 'plugin overall status == 0');
my $workdir = $sml->workdir;
ok(! defined($workdir), 'workdir = undef');

my @expected = qw(OK WARNING CRITICAL UNKNOWN DEPENDENT);
ok(eq_array($sml->status_list, \@expected),'status list ok');

my %expected = (
          'WARNING' => 1,
          'CRITICAL' => 2,
          'OK' => 0,
          'DEPENDENT' => 4,
          'UNKNOWN' => 3,
        );
ok(eq_hash($sml->status_hash, \%expected),'status hash ok');

