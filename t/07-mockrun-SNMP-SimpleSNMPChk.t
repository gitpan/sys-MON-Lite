#!perl 

use Test::More tests => 4;
use Test::Exception;
use Cwd;
my $workdir = getcwd . '/t/workdir';

use lib qw(./t/lib ./lib);

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

$sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

my %run_params = (
              commity => 'public',
              host => 'localhost',
              command => '/opt/tools/restart_web_server',
              skip_command_n_times => 3,
              run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'SNMP::SimpleSNMPCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite SNMP test ran ');

ok(($sml->overall_status == 0), 'mock sys::MON::Lite status OK');


