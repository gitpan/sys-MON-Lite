package sys::MON::Lite;

=head1 NAME

sys::MON::Lite - lightweight pluggable service monitoring 

=head1 VERSION

Version 0.02

=cut

use warnings;
use strict;
our $VERSION = '0.02';
use File::Path;
use Class::MethodMaker [
    scalar => [
        qw/status_hash status_list workdir plugin_result_hash plugin_list manager_status overall_status summary content config_name/
    ],
];

use Module::Pluggable instantiate => 'new';
use Log::Log4perl qw(:easy);
Log::Log4perl->init( \<<EOT);
log4perl.logger = DEBUG, app
log4perl.appender.app=Log::Dispatch::Syslog
log4perl.appender.app.Facility=user
log4perl.appender.app.layout=SimpleLayout
EOT

use sys::MON::Lite::Util;
use sys::MON::Lite::Store;

# $config->{params}
# $config->{workdir}
# 
sub new {
    my ( $pkg, $config ) = @_;

    my $self = {};
    $self->{util} = sys::MON::Lite::Util->new();

    DEBUG "LITE STARTING";

    $self->{status_hash} = $self->{util}->status_hash;

    $self->{'manager_status'} = 1;

    $self->{status_list} = $self->{util}->status_list;

    $self->{run_params} = $config->{params} if $config->{params};

    # set initial summary values
    $self->{run_status} = $self->{status_hash}{OK};
    $self->{summary}        = undef;
    $self->{content}        = undef;

    if ( $config->{workdir} ) {

        $self->{workdir} = $config->{workdir};

        if ( !-d $self->{workdir} ) {
            eval { mkpath( $self->{workdir} ); };
            ERROR "can't create workdir " . $self->{workdir} . " : $@\n" if $@;
        }

    }

    bless( $self, $pkg );

    # store list of current plugins
    @{ $self->{plugin_list} } = $self->plugins;

    return $self;
}

###
# RUN
###
#
# params:
#   $param->{store}
#   $param->{params}
#   $param=>{plugin_search_path}
#   $param->{plugins}
#   $param->{config_name}
#
# returns:
#   $self->{manager_status}
#

sub run {

    my ( $self, $param ) = @_;

    $self->{plugin_result_hash} = ();

    # check for available working directory
    die "no workdir specified - eg "
      . "\$sml=sys::MON::Lite->new({workdir => '/some/dir'});"
      unless ( defined( $self->{workdir} ) );
    die "directory [" . $self->{workdir} . "] does not exist\n"
      unless ( -d $self->{workdir} );
    $self->{store} = $param->{store} if $param->{store};
    $self->{DB} = sys::MON::Lite::Store->new(
        {
            dir   => $self->{workdir},
            name  => 'sys::MON::Lite',
            store => $self->{store},
        }
    );

    $self->{run_params} = $param->{params} if $param->{params};

    $self->search_path( new => $param->{plugin_search_path} )
      if $param->{plugin_search_path};

    # run each plugin in path
    my $store = ( {} );
    my $plugin_count = 0;

  PLUGIN:
    foreach my $plugin ( $self->plugins ) {

        if ( $param->{plugins} ) {
            next PLUGIN unless ( $plugin =~ m{$param->{plugins}} );
        }

        $plugin_count++;

        DEBUG "config_name:[$self->{config_name}]" if $self->{config_name};

        my $config_name = $param->{config_name} || $self->{config_name};

        # RUN the plugin
        $plugin->run(
            {
                workdir     => $self->{workdir},
                params      => $self->{run_params},
                config_name => $self->{config_name}
            }
        );

        # STORE results
        $self->{plugin_result_hash}->{ $plugin->name }->{'enabled'} =
          $plugin->enabled;
        $self->{plugin_result_hash}->{ $plugin->name }->{'config_file'} =
          $plugin->config_file;
        $self->{plugin_result_hash}->{ $plugin->name }->{'status'} =
          $plugin->status;
        $self->{plugin_result_hash}->{ $plugin->name }->{'summary'} =
          $plugin->summary;
        $self->{plugin_result_hash}->{ $plugin->name }->{'content'} =
          $plugin->content;

        if ( $plugin->status ) {
            $self->{run_status} = $plugin->status
              if ( $plugin->status > $self->{run_status} );
        }

        $self->{content} .= $plugin->summary . "\n" if ( $plugin->summary );
        $self->{content} .= $plugin->content . "\n" if ( $plugin->content );

        $self->{util}->check_run_command(
            {
                config  => $plugin->config_file,
                name    => $plugin->name,
                status  => $plugin->status,
                summary => $plugin->summary,
            }
        );

    }

    $self->{summary} = "$plugin_count] plugin(s) ran status is : [" . ${$self->{status_list}}[$self->{run_status}];

    # set initial summary values and save current run status
    $self->{overall_status} = $self->{run_status};
    $self->{run_status} = $self->{status_hash}{OK};

    my $now = time;
    my $res = ( {} );
    $res->{$now} = $self->{plugin_result_hash};

    # store results 
    $self->{DB}->store( { ref => $res } );
	# re-set run status in case run is to be called 
	# again in the life time of this object
    $self->{status} = 0;

    return $self->{manager_status};

}

###
# output_plugin_summary
###
#
# convenience method which returns human readable summarised output of a plugin
# when it has been run
#
# the summary and overall_status methods hold an ongoing status summary and text
# buffer with output from all plugins run and overall status of all plugins run
#
sub output_plugin_summary {

    my $self     = shift;
    my $summary  = undef;
    my %res_hash = %{ $self->plugin_result_hash };
    my @enabled  = qw(OFF ON);
    foreach my $plugin ( keys(%res_hash) ) {
        $summary .= "PLUGIN : [$plugin] ";
        $summary .= $enabled[ $res_hash{$plugin}->{enabled} ];
		$res_hash{$plugin}->{status} = 0 unless $res_hash{$plugin}->{status};
        $summary .=
          " status "
          . ${ $self->{util}->status_list }[ $res_hash{$plugin}->{status} ];
        $summary .= " config " . $res_hash{$plugin}->{config_file} . "\n";
    }

    $summary .=
        "OVERALL STATUS : "
      . $self->content . "\n"
      . "STATUS: " . ${ $self->{util}->status_list }[ $self->overall_status ] ;

    return $summary;

}

1;

__END__


=pod

=head2 SYNOPSIS

  use sys::MON::Lite;

  my $workdir = '/home/workdir';

  my $sml = sys::MON::Lite->new({workdir=>$workdir});

  $sml->run({ plugins =>'Plugin::Name' });

to access results from above run ....

  print $sml->output_plugin_summary;

or raw data using YAML to dump and format a data structure of the results

  use YAML;
  print Dump($sml->plugin_result_hash);

=head2 USAGE

sys::MON::Lite is intended to be used as a framework monitor services using plugins

it is meant to be run at regular intervals & repeatedly to monitor and manage service availability

it's plugins use either pre-defined configuration files or run time parameters to control their behaviour

=head3 Configuration File Usage

in the above 'Plugin::Name' has to be the name in part or full of a plugin that already exists in the plugin path

if you dont know names of plugins & paths, make a call to run() with no parameters: 

  $sml->run;

... then check the contents of 'workdir' to find a directory structure for all currently installed plugins

  # find /home/workdir/
  /home/workdir/
  /home/workdir/SMTP
  /home/workdir/SMTP/ServiceSMTPPOPCheck
  .....
  /home/workdir/POP/SimplePOPCheck
  /home/workdir/POP/SimplePOPCheck/default
  /home/workdir/POP/SimplePOPCheck/default/plugin.cfg
  .....

each plugin has it's own sub directory and configuration file created with default values - these need to be editted - for example SimplePOPCheck.cfg:

  [main]
                enabled: 1
                   user: test
               password: pop_user_password
                   host: some.pop.host
                command: /opt/tools/call_president
   skip_command_n_times: 3
  run_only_after_n_mins: 30


when auto - created by the above method, 'enabled' will be set to '0', the plugin will not run untill enabled is set to 1


the 'skip_command_n_times' and 'run_only_after_n_mins' can be used to specify the amount of times the plugin should run and the POP service to be failing before the command is run - in the above, the command will only be run once 3 contiguous failures have occured 

the command will not run again untill failure has persisted for over 30 minutes.

'/opt/tools/call_president' does not likely exist on your system - see examples of the kind of thing you may want to run in the 'examples' directory of this module - the idea behind some of these scripts is to use 'self healing' strategies as well as failure alerting

to run a specific plugin, re-run the above, using a plugin path and substituting '/' with '::', for example

  $sml->run({ plugins =>'POP::SimplePOPCheck' });

=head3 Run Time Parameter Usage

This second method of running plugins does not need configuration files 

parameters may be used to prime each plugin configuration 

for example, the 'SimplePOPCheck' plugin accepts a hash containing something like the following:

  my %run_params = (
    user                  => 'user@somewhere.com',
    timeout               => 10,
    password              => 'password',
    host                  => '127.0.0.1',
    command               => '/opt/tools/call_president "POP3 Check Failed"',
    skip_command_n_times  => 3,
    run_only_after_n_mins => 30,
  );

this hash is then passed by reference 

  $sml->run({
    plugins            =>'POP::SimplePOPCheck', 
    params             =>\%run_params, 
    plugin_search_path => 'sys::MON::Lite::Plugin'
  });

this over rides and also over writes any configuration information already defined in the plugins own config file

see the documentation for this plugin and others for more detail

=head2 METHODS

=head3 run()

params:

=over 

=item store

sets the storage method to use for saving status information, default is 'DBMDeep' and so far is the only 
supported store however YAML and others are planned to follow in later releases

=item params

run time parameters - a reference to a hash - if not set this defaults to either create default, 
disabled configs for each plugin or to read config information from previously defined configs

=item plugin_search_path

search path is default of sys::MON::Lite::Plugins but if set to anything else permits the substitution of
the core plugins with others supplied by the user

=item plugins

a string naming the pluigns to run - actually a pattern match, so 'SNMP' would run all plugins with the 
string 'SNMP' in them and 'POP::SimplePOPCheck' would run only the plugin matching this string

=item config_name

as each plugin has a configuration directory, it subsequently may have named configuration data different 
to the dircectory named 'default'

this allows a plugin to be run with different configurations within the current cycle

=back 

returns:

=over

=item manager_status

status of the plugin manager itself - 1 is okay, 0 denotes failure

=back

=head3 new()

params:

=over

=item params

run time parameters - a reference to a hash - if not set this defaults to either create default, 
disabled configs for each plugin or to read config information from previously defined configs

=item workdir

where to store / access configuration files and also where the plugin stores it's status information
by means of (default) a DBM::Deep file

this directory location must be somewhere that is both readable and writeable by the process 
running sys::MON::Lite

if the directory does not exist, it will be created

sys::MON::Lite fails to run if it cannot find or create this diretory

=back

=head3 output_plugin_summary()

a convenience method providing human readable output for the current run plugin

=head2 ACCESSORS

the following access methods are available, where appended by '_isset', '_reset' or '_clear' these are provided by Class::Methodmaker which can be used to test for each value to be set, to reset or to clear

=over

=over

=item content accessors:

=item  C<content>

=item  C<content_clear>

=item  C<content_isset>

=item  C<content_reset>

holds the output of all plugins - as each plugin is run, this scalar is appended to with new output of each run

=back 

=over 

=item manager status accessors:

=item C<manager_status>

=item C<manager_status_clear>

=item C<manager_status_isset>

=item C<manager_status_reset>

status of the plugin manager itself - the thing that runs all the plugins in sys::MON::LIte - if this fails in 
any way it should return a false, non positive value

=back

=over

=item overall status accessors:

=item C<overall_status>

=item C<overall_status_clear>

=item C<overall_status_isset>

=item C<overall_status_reset>

all plugins return status results, this is the overall status of all plugins in the current run - it is 
the responsibilty of the user to re-set this to '0' each time a new run is to start in the current running
process

=back

=over

=item plugin list accessors:

=item C<plugin_list>

=item C<plugin_list_clear>

=item C<plugin_list_isset>

=item C<plugin_list_reset>

the list of plugins available to run or matching a particular string match

=back

=over

=item plugn result hash accessors:

=item C<plugin_result_hash>

=item C<plugin_result_hash_clear>

=item C<plugin_result_hash_isset>

=item C<plugin_result_hash_reset>

a hash containing the current plugin reslults - this is reset by each plugin as it runs

=back

=over

=item status hash accessors:

=item C<status_hash>

=item C<status_hash_clear>

=item C<status_hash_isset>

=item C<status_hash_reset>

this returns a hash something like :

 (
          'WARNING' => 1,
          'CRITICAL' => 2,
          'OK' => 0,
          'DEPENDENT' => 4,
          'UNKNOWN' => 3,
 );

and is used to measure the status of each plugin and the overall status of all plugins - you can change this if you want to but whatever it is changed to must have numeric values 0..4 lest internal functions are broken

=back

=over

=item status list accessors

=item C<status_list>

=item C<status_list_clear>

=item C<status_list_isset>

=item C<status_list_reset>

returns a list of status values, something like

  (OK WARNING CRITICAL UNKNOWN DEPENDENT)

the same applies to this accessor as to status_hash

=back

=over

=item summary accessors:

=item C<summary>

=item C<summary_clear>

=item C<summary_isset>

=item C<summary_reset>

this is a string containing the current status text retruned by each plugin in the current set of runs - it is the responisibility of the user to clear this before starting a new batch of plugin runs

=back

=over

=item workdir accessors:

=item C<workdir>

=item C<workdir_clear>

=item C<workdir_isset>

=item C<workdir_reset>

workdir is where all status and configuration information is stored - it is a directory structure that will be created if it does not exist and must be able to be written to by the process running sys::MON::Lite

=back

=over 

=item C<config >

=item C<config_name_clear>

=item C<config_name_isset>

=item C<config_name_reset>

rather than over writing an existing configuration when using parameterised run method or in order to select a specific configuration:

  $sml->config_name('new_config');

=back

=back

=head1 AUTHOR

Jon Brookes, C<< <jon at ajblog.co.uk> >>

=head1 BUGS

This is still an early release, there are only a few plugins, more will be added in later releases.

A minimal test framework is now available but in need of more development.

please report any bugs or feature requests to L<http://code.google.com/p/sys-mon-lite/issues/list>

latest source for this module may be dowloaded from L<http://code.google.com/p/sys-mon-lite/source>

=head1 SUPPORT

=over

=item * perldoc 

  perldoc sys::mon::lite

=item * Search CPAN

L<http://search.cpan.org/dist/sys-MON-Lite>

=back

=head1 ACKNOWLEDGEMENTS

this module relies on other modules to work and must acknowledge 
Module::Pluggable,
DBM::Deep,
Class::MethodMaker,
Log::Dispatch::Syslog,
Mail::POP3Client,
Data::GUID,
Net::IMAP::Simple,
Email::Simple,
Config::Std,
YAML,
WWW::Mechanize,
the might CPAN, Perl and all who have contributed to them.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jon Brookes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

see L<sys::MON::Lite>

=cut
