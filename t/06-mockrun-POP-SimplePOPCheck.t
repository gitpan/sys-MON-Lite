#!perl 

use Test::More tests => 6;
use Test::Exception;
use Cwd;
use strict; 
use File::Copy;
use File::Path;

my $workdir = getcwd . '/t/tmp/workdir'.'.'.time();
mkpath($workdir) unless (-d $workdir);

use lib qw(./t/lib ./lib);

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

my $sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

my %run_params = (
              user => 'billyboy@worky.worky.com',
              timeout => 10,
              password => 'password',
              host => '127.0.0.1',
              command => '/opt/tools/call_president("POP3 Check Failed")',
              skip_command_n_times => 3,
              run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'POP::SimplePOPCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite POP test ran ');

ok(($sml->overall_status == 0), 'mock sys::MON::Lite status OK');

my $sml_two = sys::MON::Lite->new({workdir=>$workdir});

%run_params = (
              user => 'billyboy@no.where.com',
              timeout => 10,
              password => 'password',
              host => '127.0.0.1',
              command => '/opt/tools/call_president("POP3 Check Failed")',
              skip_command_n_times => 3,
              run_only_after_n_mins => 30,
);

ok($sml_two->run({plugins=>'POP::SimplePOPCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite ran - bad page');

ok(($sml_two->overall_status == 2), 'mock sys::MON::Lite status critical check');
