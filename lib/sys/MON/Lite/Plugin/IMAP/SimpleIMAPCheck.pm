package sys::MON::Lite::Plugin::IMAP::SimpleIMAPCheck;

=head1 NAME

sys::MON::Lite::Plugin::IMAP::SimpleIMAPCheck - plugin form sys::MON::Lite

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;
use Class::MethodMaker [ scalar => [qw/imap/], ];

use base qw(sys::MON::Lite::Core::Plugin::Base);
use Net::IMAP::Simple;
use Email::Simple;

use sys::MON::Lite::Util;
my $util = sys::MON::Lite::Util->new;

sub init {

    my $self = shift;

    $self->{content} .= "\n###\n";
    $self->{content} .= "# PLUGIN : " . __PACKAGE__ . "\n";

    return __PACKAGE__;
}

sub service_check {

    my $self = shift;

    if ( $self->{run_params} ) {
        unless ( $self->{imap} =
            new Net::IMAP::Simple( $self->{run_params}->{host} ) )
        {
            $self->{status}  = ${ $util->status_hash }{CRITICAL};
            $self->{summary} =
              "can't connect to IMAP server ["
              . $NET::IMAP::Simple::errstr . "]";
            return;
        }
        unless (
            $self->{imap}->login(
                $self->{run_params}->{user},
                $self->{run_params}->{password}
            )
          )
        {
            $self->{status}  = ${ $util->status_hash }{CRITICAL};
            $self->{summary} =
              "can't login to IMAP server [" . $self->{imap}->errstr . "]";
            return 0;
        }

    }
    else {
        $self->{status}  = ${ $util->status_hash }{CRITICAL};
        $self->{summary} =
          'no run parameters specified or found in pre-defined config';
        return;
    }

    unless ( $self->{imap} ) {
        $self->{status}  = ${ $util->status_hash }{CRITICAL};
        $self->{summary} =
'imap not initialised - check run parameters and or pre-defined config';
        return 0;
    }

    my $nm = $self->{imap}->select('INBOX');
    my $i;

    for ( my $i = 1 ; $i <= $nm ; $i++ ) {
        my $es = Email::Simple->new( join '', @{ $self->{imap}->top($i) } );
        $self->{summary} .=
          sprintf( "[%03d] %s\n", $i, $es->header('Subject') );

    }
    $self->{imap}->quit;

    $self->{status} = ${ $util->status_hash }{OK};
    $self->{summary} .= 'ran ok';

    return 1;
}

sub define_default_config {

    my $self = shift;

    $self->{default_config_file} = <<CONF;

[main]

              enabled: 0
                 user: ****
             password: ****
                 host: imap_server
              command: /opt/tools/call_president "IMAP Check Failed"
 skip_command_n_times: 3
run_only_after_n_mins: 30

CONF

}

1;

=pod


=head2 SYNOPSIS

  use sys::MON::Lite;

  my $workdir = '/home/workdir';

  my $sml = sys::MON::Lite->new({workdir=>$workdir});

  $sml->run({ plugins =>'HTTP::SimpleIMAPCheck' });

this plugin checks that it can connect to a web server, retrieve a web page 
and match a given pattern match within the text of the html contents of the 
page

=head2 USAGE

=head3 ACCESSING RESULTS

to access results run ....

  print $sml->output_plugin_summary();

or raw data using YAML to dump and format a data structure of the results

  use YAML;
  print Dump($sml->plugin_result_hash);

access single line, plugin manager summary ....

  print "summary:[" . $sml->summary ."]\n";

or verbose, multi-line output ....

  print "content:[" . $sml->content."]\n";

or just the overall status ....

  print "status: [" . $sml->overall_status . "]\n";

=head3 PLUGIN CONFIGURATION

=head4 CONFIG FILE

with an empty, writeable directory - '/home/workdir', run:

  $sml->run({ plugins =>'HTTP::SimpleIMAPCheck' });

which will create a directory structure something like:






  /home/workdir/sys_MON_Lite.dbm
  /home/workdir/IMAP/SimpleIMAPCheck/default/plugin.cfg
  /home/workdir/IMAP/SimpleIMAPCheck/default/IMAP_SimpleIMAPCheck.dbm

edit the contents of plugin.cfg:

  [main]

                enabled: 0
                   user: ****
               password: ****
                   host: imap_server
                command: /opt/tools/call_president "IMAP Check Failed"
   skip_command_n_times: 3
  run_only_after_n_mins: 30

=head4 RUN TIME PARAMETERS

this plugin may be configured by passing a reference to a hash:

  my %run_params = (
    user                  => '********',
    timeout               => 30,
    password              => '********',
    host                  => 'some.pop.host',
    command               => '/opt/tools/call_president "POP3 Check Failed"',
    skip_command_n_times  => 3,
    run_only_after_n_mins => 30,
  );


  $sml->run({
    plugins            =>'POP::SimplePOPCheck', 
    params             =>\%run_params, 
    plugin_search_path => 'sys::MON::Lite::Plugin'
  });

this will automatically create a config file similar to the above method in the 'workdir' directory:

  [main]

  password: **********

  user: *********

  host: your_imap_host

  enabled: 1

a configuration file for this plugin will be over written, if already present before the parameterised call to run()

rather than over writing an existing configuration, another may be written and later selected:

  $sml->config_name('new_config');

=head2 ACCESSORS

the following are used internally by the plugin manager to access the POP object

=over

=item C<define_default_config>

=item C<imap>

=item C<imap_clear>

=item C<imap_isset>

=item C<imap_reset>

=item C<init>

=item C<service_check>

=back

=head2 SEE ALSO

L<sys::MON::Lite>

=cut

