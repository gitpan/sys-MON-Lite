#!perl 

use Test::More tests => 9;
use Test::Exception;
use Cwd;
use File::Basename;
my $workdir = getcwd . '/t/workdir';

use lib qw(./t/lib ./lib);

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

$sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

my %run_params = (
              address => 'http://localhost',
              timeout => 30,
        search_string => 'ding dong',
              command => '/opt/tools/restart_web_server',
 skip_command_n_times => 3,
run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'HTTP::SimpleURLCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite ran - good page');

ok(($sml->overall_status == 0), 'mock sys::MON::Lite status OK');

%run_params = (
              address => 'http://no.where.com',
              timeout => 30,
        search_string => 'It Worked',
              command => '/opt/tools/restart_web_server',
 skip_command_n_times => 3,
run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'HTTP::SimpleURLCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite ran - bad page');

my %res_hash = %{$sml->plugin_result_hash};

ok(($sml->overall_status == 2), 'mock sys::MON::Lite status critical check');

$sml_two = sys::MON::Lite->new({workdir=>$workdir, params=>\%run_params});
ok($sml_two, 'new sys::MON::Lite - with params passed to new()');
ok($sml_two->run({plugins=>'HTTP::SimpleURLCheck', plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite ran - bad page');
ok(($sml_two->overall_status == 2), 'mock sys::MON::Lite status critical check');


