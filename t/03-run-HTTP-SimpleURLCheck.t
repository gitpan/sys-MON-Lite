#!perl 
use strict;
use warnings;
use Test::More tests => 6;
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

my $sml = sys::MON::Lite->new({workdir=>$workdir});

ok($sml, 'new sys::MON::Lite');

my %run_params = (
              enabled => 1,
              address => 'http://localhost:8889',
              timeout => 30,
        search_string => 'It Can Never Work',
              command => '/opt/tools/restart_web_server',
 skip_command_n_times => 3,
run_only_after_n_mins => 30,
);

ok($sml->run({plugins=>'HTTP::SimpleURLCheck', params=>\%run_params}), 'sys::MON::LIte ran and primed config file');
ok($sml->run({plugins=>'HTTP::SimpleURLCheck'}), 'sys::MON::LIte ran relying on config file');

ok( @{$sml->plugin_list} > 0, 'plugins found in list' );

my $enabled = 0;

my %res_hash = %{$sml->plugin_result_hash};

my @epochs = ();

foreach my $epoch (keys(%res_hash)) {
    
    push @epochs, $epoch;
}

my @epochs_sorted_desc = sort {$b <=> $a} @epochs;

$enabled = 0;

foreach my $plugin (keys(%res_hash)) {
    $enabled += $res_hash{$plugin}->{enabled};
}

#use YAML; print Dump(%res_hash);
ok($enabled == 1, '1 plugin enabled');

