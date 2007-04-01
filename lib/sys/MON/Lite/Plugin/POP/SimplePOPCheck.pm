package sys::MON::Lite::Plugin::POP::SimplePOPCheck;

=head1 NAME

sys::MON::Lite::Plugin::POP::SimplePOPCheck - simple POP check plugin for sys::MON::Lite

=head1 VERSION

Version 0.02

=cut

use warnings;
use strict;
use Class::MethodMaker [ scalar => [qw/pop/], ];

use base qw(sys::MON::Lite::Core::Plugin::Base);
use Mail::POP3Client;
use sys::MON::Lite::Util;
my $util = sys::MON::Lite::Util->new;

sub init {

    my $self = shift;

    $self->{pop} = new Mail::POP3Client(
        USER     => $self->{run_params}->{user},
        TIMEOUT  => $self->{run_params}->{timeout},
        PASSWORD => $self->{run_params}->{password},
        HOST     => $self->{run_params}->{host}
    );

    $self->{content} .= "\n###\n";
    $self->{content} .= "# PLUGIN : " . __PACKAGE__ ."\n";

    if ( $self->{pop} ) {
        $self->{status} = ${ $util->status_hash }{OK};
        $self->{summary} = __PACKAGE__ . " status OK";
    }
    else {
        $self->{status}  = ${ $util->status_hash }{CRITICAL};
        $self->{content} =
          "can't connect to pop server [$self->{run_params}->{host}] $!\n";
        $self->{summary} = __PACKAGE__ . " status CRITICAL - no POP connection";
    }

    return __PACKAGE__;
}

sub service_check {

    my $self = shift;

    $self->{pop} = new Mail::POP3Client(
        USER     => $self->{run_params}->{user},
        TIMEOUT  => $self->{run_params}->{timeout},
        PASSWORD => $self->{run_params}->{password},
        HOST     => $self->{run_params}->{host}
    );

    my $i;
    my $count = 0;
    for ( $i = 1 ; $i <= $self->pop->Count() ; $i++ ) {
        foreach ( $self->pop->Head($i) ) {
            if ($_ =~ m/^(Subject):\s+/i) {
                $count++;
                #print "subject>>>>>$_\n";
            }
        }
    }
    if ( $self->{run_params}->{host} ) {
    $self->{content} .=
      "pop'ed [$count] mails from [$self->{run_params}->{host}]\n";
    }
    my $message = $self->pop->Message;
    unless ( $message =~ m{OK} ) {
        $self->{status} = ${ $util->status_hash }{CRITICAL};
        $self->{summary} = __PACKAGE__ . " status CRITICAL - failed to POP messages";
	}
    my $popcount = $self->pop->Count;
    my $alive    = $self->pop->Alive;
    my $popstat  = $self->pop->POPStat;
    $message =~ s{(\r|\n)}{}g;
    $self->{content} .= "message:[" . $message . "]\n";
    $self->{content} .= "popcount:[" . $popcount . "]\n";
    $self->{content} .= "alive:[" . $alive . "]\n";
    $self->{content} .= "popstat:[" . $popstat . "]\n";
    if ( $self->pop->State ne 'TRANSACTION' ) {
        $self->{status} = ${ $util->status_hash }{CRITICAL};
        $self->{summary} = __PACKAGE__ . " status CRITICAL - bad POP status";
	}
    $self->{content} .= "state:[" . $self->pop->State . "]\n";
    $self->pop->Close();
    $self->{content} .= "closing connection ...\n";

    return 1;
}

sub define_default_config {

    my $self = shift;

    $self->{default_config_file} = <<CONF;

[main]
              enabled: 0
                 user: user
             password: password
                 host: pop.somewhere.net
              command: /opt/tools/call_president
 skip_command_n_times: 3
run_only_after_n_mins: 30

CONF

}

1;

__END__

=pod

=head2 SYNOPSIS

  use sys::MON::Lite;

  my $workdir = '/home/workdir';

  my $sml = sys::MON::Lite->new({workdir=>$workdir});

  $sml->run({ plugins =>'POP::SimplePOPCheck' });

this plugin checks that it can connect to a POP server and list all mails in a given mail box

mail contents is not recorded

no mails are deleted

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

  $sml->run({ plugins =>'POP::SimplePOPCheck' });

which will create a directory structure something like:

  /home/workdir/sys_MON_Lite.dbm
  /home/workdir/POP/SimplePOPCheck
  /home/workdir/POP/SimplePOPCheck/default
  /home/workdir/POP/SimplePOPCheck/default/plugin.cfg
  /home/workdir/POP/SimplePOPCheck/default/POP_SimplePOPCheck.dbm

edit the contents of plugin.cfg:

  [main]
                enabled: 1
                   user: *your_user_name*
               password: *your_password*
                   host: *address_of_pop_server*
                command: *path_to_script_to_run_after_a_failure*
   skip_command_n_times: *amount_of_times_to_skip_running_command_when_failing*
  run_only_after_n_mins: *number_of_minutes_between_command_running*

notes:

=over

=item enabled

this must be set to a positive value for the plugin to run

=item user 

the user name to log in to a POP service

=item password

the password to log in to a POP service

=item host

address of POP server

=item command

this is optional and is a fully resolved path name

if you include this parameter, the specified command or script will first be checked to exist and be executable

if this is the case, the command will be run if the plugin returns a status other than 'OK'

=item skip_command_n_times

this is optional and must be a number

if specified, the command will not run before 'n' failures have occured - these must be contiguous, that is one after another

=item run_only_after_n_mins

this is optional and must be a number

if specified, once 'n' failures have occured and the command has been run once, it will not run again untill this amount of 
minutes have elapsed and failures have been constant and contiguous

where 'self healing' scripts are used, this value can be used to 'throttle' the amount of times a system will automatically recover


=back

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

  run_only_after_n_mins: 30

  skip_command_n_times: 3

  host: some.pop.host

  password: ********

  timeout: 30

  user: *******

  command: /opt/tools/call_president "POP3 Check Failed"

  enabled: 1

a configuration file for this plugin will be over written, if already present before the parameterised call to run()

rather than over writing an existing configuration, another may be written and later selected:

  $sml->config_name('new_config');

the run() method may then be called with paramers to create a new configuraiton under the directory 'new_config', for example:

  $sml->config_name('new_config');

  my %run_params = (
    user                  => '****',
    timeout               => 10,
    password              => '*****',
    host                  => 'some.pop.server',
    command               => '/opt/tools/call_president "POP3 Check Failed"',
    skip_command_n_times  => 3,
    run_only_after_n_mins => 30,
  );

  $sml->run({
    plugins            =>'POP::SimplePOPCheck',
    params             =>\%run_params,
    plugin_search_path => 'sys::MON::Lite::Plugin',
  });

will create a configuration file under 'new_config', rather than 'default'

  /home/workdir/POP/SimplePOPCheck/new_config/plugin.cfg


=head2 METHODS

the following are internal methods used by the plugin manager to control each plugin, they are not for use externally

=over

=item C<define_default_config>

=item C<init>

=item C<service_check>

=back

=head2 ACCESSORS

the following are used internally by the plugin manager to access the POP object

=over

=item C<pop>

=item C<pop_clear>

=item C<pop_isset>

=item C<pop_reset>

=back

=head2 SEE ALSO

L<sys::MON::Lite>

=cut
