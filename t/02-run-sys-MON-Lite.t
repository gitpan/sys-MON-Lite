#!perl 

use Test::More tests => 9;
use Test::Exception;
use Cwd;
use File::Copy;
use File::Path;

my $workdir = getcwd . '/t/tmp/workdir'.'.'.time();
mkpath($workdir) unless (-d $workdir);

BEGIN {
	use_ok( 'sys::MON::Lite' );
}

#diag( "Testing sys::MON::Lite $sys::MON::Lite::VERSION, Perl $], $^X" );

my $sml = sys::MON::Lite->new();

ok($sml, 'new sys::MON::Lite');

dies_ok { $sml->run } 'expecting to die with no workdir specified';

$sml = sys::MON::Lite->new({workdir=>'/some/illegal/address'});

dies_ok { $sml->run } 'expecting to die with workdir not existing';

$sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

ok($sml->run(), 'sys::MON::LIte ran');

like( $sml->plugin_list, qr/^ARRAY/, 'plugin list returns array ref');

ok( @{$sml->plugin_list} > 0, 'plugins found in list' );

my $enabled = 0;
my %res_hash = %{$sml->plugin_result_hash};

foreach my $plugin (keys(%res_hash)) {
    $enabled += $res_hash{$plugin}->{enabled};
}
ok($enabled == 0, 'no plugins yet enabled');
