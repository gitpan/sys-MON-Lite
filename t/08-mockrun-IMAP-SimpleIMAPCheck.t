#!perl 

use Test::More tests => 4;
use Test::Exception;
use Cwd;
use File::Path;

my $workdir = getcwd . '/t/tmp/workdir'.'.'.time();
mkpath($workdir) unless (-d $workdir);

use lib qw(./t/lib ./lib);

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

$sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

my %run_params = (
              enabled => 1,
              user => 'jon@wibble.net',
              timeout => 10,
              password => 'wibble',
              host => 'wibble',
              command => '/opt/tools/call_president "IMAP Check Failed"',
              skip_command_n_times => 3,
              run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'IMAP::SimpleIMAPCheck', params=>\%run_params, plugin_search_path => 'Test::sys::MON::Lite::Plugin'}), 'mock sys::MON::Lite IMAP test ran ');

ok(($sml->overall_status == 0), 'mock sys::MON::Lite status OK');

print "CONTENT\n" . $sml->content . "\n";
print "STATUS\n" . $sml->overall_status. "\n";

