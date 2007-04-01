package sys::MON::Lite::Plugin::HTTP::SimpleURLCheck;

=head1 NAME

sys::MON::Lite::Plugin::HTTP - simple HTTP check plugin for sys::MON::Lite

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;
use Class::MethodMaker [
    scalar => [qw/mech/], ];


use base qw(sys::MON::Lite::Core::Plugin::Base);
use WWW::Mechanize;
use sys::MON::Lite::Util;
my $util = sys::MON::Lite::Util->new;

sub init {

    my $self = shift;

    $self->{mech} = WWW::Mechanize->new;
    $self->{status} = ${$util->status_hash}{OK};

    $self->{content} .= "\n###\n";
    $self->{content} .= "# PLUGIN : " . __PACKAGE__ ."\n";

    return __PACKAGE__;
}

sub service_check {

    my $self = shift;

    $self->{mech}->timeout($self->{run_params}->{timeout});

    $self->{mech}->get($self->{run_params}->{address});
    
    if ($self->{mech}->success) { 
		
		$self->{status} = ${$util->status_hash}{OK};
        $self->{summary} = "returned good page\n";

        if ( $self->{run_params}->{search_string} ) {
		    
		    if($self->{mech}->content !~ m{$self->{run_params}->{search_string}}) {
                 $self->{summary} .= " but match of search string ".$self->{run_params}->{search_string}." failed";
				 
		         $self->{status} = ${$util->status_hash}{CRITICAL};
			}
		}


	}
	else {
		$self->{status} = ${$util->status_hash}{CRITICAL};
	}

    #$self->{content} = $self->{mech}->content. "\n-----\n";

	return 1;
}

sub define_default_config {

    my $self = shift;

	$self->{default_config_file} = <<CONF;

[main]
              enabled: 0
              address: http://127.0.0.1
              timeout: 30
        search_string: It Will Never Work
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

  $sml->run({ plugins =>'HTTP::SimpleURLCheck' });

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

  $sml->run({ plugins =>'HTTP::SimpleURLCheck' });

which will create a directory structure something like:

  /home/workdir/
  /home/workdir/sys_MON_Lite.dbm
  /home/workdir/HTTP/SimpleURLCheck/default/plugin.cfg
  /home/workdir/HTTP/SimpleURLCheck/default/HTTP_SimpleURLCheck.dbm

edit the contents of plugin.cfg:

  [main]
                enabled: 0
                address: http://127.0.0.1
                timeout: 30
          search_string: It Will Never Work
                command: /opt/tools/call_president
   skip_command_n_times: 3
  run_only_after_n_mins: 30

notes:

=over

=item enabled

this must be set to a positive value for the plugin to run

=item address

web address to check 

=item timeout

timeout for web service

=item search_string

the string to search for in the contents of the html that is returned by the web service

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

=head3 INTERNAL METHODS & ACCESSORS

the following are internal methods used by the plugin manager to control the plugin, they are not for use externally

=over 

=item define_default_config

=item init

=item mech

=item mech_clear

=item mech_isset

=item mech_reset

=item service_check

=back 

=cut
