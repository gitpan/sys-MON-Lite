package sys::MON::Lite::Plugin::SMTP::ServiceSMTPPOPCheck;

=head1 NAME

sys::MON::Lite::Plugin::SMTP::ServiceSMTPPOPCheck - combined SMTP & POP service check plugin for sys::MON::Lite

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;
use Class::MethodMaker [ scalar => [qw/smtp pop/], ];

use base qw(sys::MON::Lite::Core::Plugin::Base);
use Net::SMTP;
use sys::MON::Lite::Util;
use Mail::POP3Client;
use YAML;
use Data::GUID;

my $util = sys::MON::Lite::Util->new;

sub init {

    my $self = shift;

    # Constructors
    $self->{smtp} = Net::SMTP->new(
        $self->{run_params}->{host},
        Timeout => $self->{run_params}->{timeout},
        Debug   => $self->{run_params}->{debug},
    );

    $self->{status} = ${ $util->status_hash }{OK};
    $self->{summary} = __PACKAGE__ . " status OK";


    $self->{content} .= "\n###\n";
    $self->{content} .= "# PLUGIN : " . __PACKAGE__ ."\n";

    return __PACKAGE__;
}

sub service_check {

    my $self = shift;

    $self->{content} .= "smtp to: " . $self->{run_params}->{to} . "\n";

    $self->{guid}        = Data::GUID->new;
    $self->{guid_string} = $self->{guid}->as_string;

    my $epoch = time;
    $self->test_smtp(
        {
            time  => $epoch,
            shost => $self->{run_params}->{host},

            stimeout => $self->{run_params}->{timeout},
            debug    => 0,
            from     => $self->{run_params}->{to},
            to       => $self->{run_params}->{to},
            guid     => $self->{guid_string},
        }
    );

    my $pop_retries = 10;
    my $sleep       = 1;
    my $ok = 0;
  POPOK:
    foreach my $try ( 0 .. $pop_retries ) {

        $self->{content} .= "about to test pop connection: "
          . $self->{run_params}->{pophost}
          . " try[$try] with user: $self->{run_params}->{popuser} ...\n";

        $ok = $self->test_pop(
            {
                user    => $self->{run_params}->{popuser},
                pass    => $self->{run_params}->{poppass},
                host    => $self->{run_params}->{pophost},
                guid    => $self->{run_params}->{guid},
                debug   => 0,
                timeout => $self->{run_params}->{poptimeout},
            }
        );
        last POPOK if $ok;
        sleep $sleep;
    }

    $self->{content} .= 'message pop succeeded' if $ok;

}

sub test_smtp {
    my ( $self, $params ) = @_;
    my %status_hash = (
        'epoch'    => $params->{time},
        'smtphost' => $params->{shost},
        'pophost'  => $params->{phost},
        'guid'     => $params->{guid},
    );

    eval {
        $self->{smtp} = Net::SMTP->new(
            $params->{shost},
            Timeout => $params->{stimeout},
            Debug   => $params->{debug},
        );
    };

    if($@) {
       $self->{content} .= "smtp connection failed : $@\n";
       $self->{summary} = "smtp connection to $params->{shost} failed\n";
       $self->{status} = ${ $util->status_hash }{CRITICAL};
	   return;
    } 
	else {
       $self->{content} .= "smtp connection to $params->{shost} fine\n";
	}

    $self->{smtp}->mail( $params->{from} );
    $self->{smtp}->to( $params->{to} );

    $self->{subject} = __PACKAGE__ . ": mail end to end test";
    $self->{subject} .= ' ' . $self->{run_params}->{subject} if ( $self->{run_params}->{subject} );

    $self->{smtp}->data();
    $self->{smtp}->datasend("To: $params->{to}\n");
    $self->{smtp}->datasend( "Subject: " . $self->{subject} . "\n" );
    $self->{smtp}->datasend("\n");
    $self->{smtp}->datasend( "<YAML>\n" . Dump( \%status_hash ) . "</YAML>\n" );

    $self->{smtp}->dataend();

    $self->{smtp}->quit;
}

sub test_pop {

    my ( $self, $params ) = @_;
    
    my $pop;

    eval {
        $self->{pop} = new Mail::POP3Client(
            USER     => $params->{user},
            PASSWORD => $params->{pass},
            HOST     => $params->{host},
            DEBUG    => $params->{debug},
            TIMEOUT  => $params->{timeout},
        );
    };
    return if $@;

    if ( !$self->{pop}->Login() ) {
        print "failed to login : to POP account : "
          . $self->{pop}->Message() . "\n";
    }

    my $i;
  POP:
    for ( $i = 1 ; $i <= $self->{pop}->Count() ; $i++ ) {

        my $yaml_mess = 0;
        foreach ( $self->{pop}->Head($i) ) {
            $yaml_mess = 1 if ( $_ =~ m{$self->{subject}} );
        }
        next POP unless $yaml_mess;

        if ( $self->{pop}->Body($i) =~ m{<YAML>(.+)</YAML>}si ) {

            my $loaded;
            eval { $loaded = Load( $1 . "\n" ); };

            if ($@) {
                print "error parsing YAML\n";
            }
            else {

                if ( $$loaded{guid} eq $self->{guid_string} ) {
                    $self->{pop}->Delete($i);
                    $self->{pop}->Close();
                    return 1;
                }
            }
        }

        # DELETE anyway - clear out previously failed attempts
        $self->{pop}->Delete($i);
    }

    $self->{pop}->Close();

    return 0;
}

sub define_default_config {

    my $self = shift;

    $self->{default_config_file} = <<CONF;

  [main]
                enabled: 0
                   host: some.smtp.host
                timeout: 30
                subject: smtp_pop check - automated mail test
                     to: some_recipient
                pophost: some.pop.server
                popuser: user_name
                poppass: ******
             poptimeout: 30
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

  $sml->run({ plugins =>'SMTP::ServiceSMTPPOPCheck' });

this plugin checks that it can send an SMTP message, connect to a POP server and retrieve the signed, sent message

mails are deleted

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

  /home/workdir/
  /home/workdir/sys_MON_Lite.dbm
  /home/workdir/SMTP/ServiceSMTPPOPCheck/default/plugin.cfg
  /home/workdir/SMTP/ServiceSMTPPOPCheck/default/SMTP_ServiceSMTPPOPCheck.dbm

edit the contents of plugin.cfg:

  [main]
                enabled: 0
                   host: some.smtp.host
                timeout: 30
                subject: smtp_pop check - automated mail test
                     to: some_recipient
                pophost: some.pop.server
                popuser: user_name
                poppass: ******
             poptimeout: 30
                command: /opt/tools/call_president
   skip_command_n_times: 3
  run_only_after_n_mins: 30

notes:

=over

=item enabled

this must be set to a positive value for the plugin to run 

=item user

the user name to log in to a SMTP service 

=item password

the password to log in to a SMTP service 

=item host

address of SMTP server 

=item timeout

SMTP timeout

=item subject

mail subject - used to identify mails when POP'ed 

=item to

mail recipient

=item pophost

POP server

=item popuser

POP user

=item poppass

POP user password

=item poptimeout

POP timeout

=item command

this is optional and is a fully resolved path name 

if you include this parameter, the specified command or script will first be checked to exist and be executable

if this is the case, the command will be run if the plugin returns a status other than 'OK'

=item skip_command_n_times

this is optional and must be a number 

if specified, the command will not run before 'n' failures have occured - these must be contiguous, that is one after another

=item run_only_after_n_mins

this is optional and must be a number 

if specified, once 'n' failures have occured and the command has been run once, it will not run again untill this amount of minutes have elapsed and failures have been constant and contiguous

where 'self healing' scripts are used, this value can be used to 'throttle' the amount of times a system will automatically recover

=back

=head4 RUN TIME PARAMETERS

this plugin may be configured by passing a reference to a hash:

  my %run_params = (

                   host => 'some.smtp.host',
                timeout => 30,
                subject => 'smtp_pop check - automated mail test',
                     to => 'some_recipient',
                pophost => 'some.pop.server',
                popuser => 'user_name',
                poppass => '******',
             poptimeout => 30,
                command => '/opt/tools/call_president',
   skip_command_n_times => 3,
  run_only_after_n_mins => 30,

  );

  $sml->run({
    plugins            =>'SMTP::ServiceSMTPPOPCheck',
    params             =>\%run_params, 
    plugin_search_path => 'sys::MON::Lite::Plugin'
  });

this will automatically create a config file similar to the above method in the 'workdir' directory:

  [main]

  run_only_after_n_mins: 30

  skip_command_n_times: 3

  subject: smtp_pop check - automated mail test

  pophost: some.pop.host

  host: some.smtp.host

  to: recipient

  timeout: 30

  poppass: *******

  enabled: 1

  command: /opt/tools/call_president

  popuser: pop_user

  poptimeout: 30


rather than over writing an existing configuration, another may be written and later selected:

  $sml->config_name('new_config');

=head3 INTERNAL METHODS & ACCESSORS

the following are internal methods used by the plugin manager to control the plugin, they are not for use externally

=over 

=item service_check

=item define_default_config

=item init

=item test_pop

=item test_smtp

=item smtp

=item smtp_clear

=item smtp_isset

=item smtp_reset

=item pop

=item pop_clear

=item pop_isset

=item pop_reset

=back

=head2 SEE ALSO

L<sys::MON::Lite>

=cut

