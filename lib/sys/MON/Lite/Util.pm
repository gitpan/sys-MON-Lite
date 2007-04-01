package sys::MON::Lite::Util;

=head1 NAME

sys::MON::Lite::Util - library functions for sys::MON::Lite

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;
use File::Path;
use File::Basename;
use Config::Std;
use File::Basename;
use DBM::Deep;
use sys::MON::Lite::Store;

use Log::Log4perl qw(:easy);
Log::Log4perl->init( \<<EOT);
log4perl.logger = DEBUG, app
log4perl.appender.app=Log::Dispatch::Syslog
log4perl.appender.app.Facility=user
log4perl.appender.app.layout=SimpleLayout
EOT

our $VERSION = '0.01';

use Class::MethodMaker [
    scalar => [qw/enabled_config_file status_hash status_list/], ];

sub new {

    my ( $pkg, $config ) = @_;
    my $self = {};

    $self->{store} = $config->{store} if $config->{store};

    %{ $self->{status_hash} } = (
        'OK'        => 0,
        'WARNING'   => 1,
        'CRITICAL'  => 2,
        'UNKNOWN'   => 3,
        'DEPENDENT' => 4
    );

    my @list = qw(OK WARNING CRITICAL UNKNOWN DEPENDENT);
    $self->{status_list} = \@list;

    bless( $self, $pkg );
    return $self;
}

sub validate_config_file {

    my ( $self, $param ) = @_;

    if ( $param->{package_name} =~ m{ .+ :: Plugin :: (.+) $ }x ) {
        $self->{plugin_short_name} = $1;
    }

    my $plugin_short_path = $self->{plugin_short_name};
    $plugin_short_path =~ s{::}{/}g;

    DEBUG "DEBUG: Util.pm: config_name:[$param->{config_name}]"
      if $param->{config_name};

    my $plugin_subdir = $param->{config_name} || 'default';

    my $config_path =
        $param->{wd} . '/'
      . $plugin_short_path . '/'
      . $plugin_subdir
      . '/plugin.cfg';

    $self->create_default_config(
        { path => $config_path, dconf => $param->{dconf} } )
      unless ( -e $config_path );

    $self->{enabled_config_file} =
      $self->config_file_valid_enabled( { cnf => $config_path } );

    return ( $config_path, $self->{plugin_short_name} );

}

sub create_default_config {

    my ( $self, $param ) = @_;
    my $dir = dirname( $param->{path} );

    mkpath($dir) unless ( -e $dir );
    open( C, ">$param->{path}" );
    print C ${ $param->{dconf} };
    close C;
}

sub config_file_valid_enabled {
    my ( $self, $param ) = @_;

    my %config;
    eval { read_config $param->{cnf} => %config; };

    return 0 if ($@);

    return 0 unless ( defined( $config{main}{enabled} ) );

    return 0 if ( $config{main}{enabled} == 0 );

    return 1;
}

sub check_run_command {

    my ( $self, $param ) = @_;
    use YAML;

    read_config $param->{config} => my %config;
	
   my $conf_dir = dirname( $param->{config} );

    my $now = time;

    my $DB = sys::MON::Lite::Store->new(
        {
            dir   => $conf_dir,
            name  => $param->{name},
            store => $self->{store},
        }
    );

    $DB->store( { ref => { now_epoch => $now } } );
	
    # store current status and time
    $DB->store( { ref => { status => $param->{status} } } );
    $DB->store( { ref => { summary => $param->{summary} } } );
	
	my $status = $param->{status} || 0;

    if ( ! $status ) {
        if ( $status == $self->{status_hash}{OK} ) {

            $DB->store( { ref => { skip_count => 0 } } );

        }
    }

    else {

	    # test for existence of executable run command
        unless ( -x $config{main}{command}) {
            $DB->store( { ref => { summary => "CRITICAL : $config{main}{command} does not exist or is not executable" } } );
		    return;
		}

        if ( $config{main}{skip_command_n_times} ) {
            $self->skip_command_n_times (
                    {
                        store   => $DB,
                        config => \%config,
                    }
			);
		}
		else {
                $self->run_command(
                    {
                        store   => $DB,
                        command => $config{main}{command}
                    }
                );
		}


        }
}

sub skip_command_n_times {

    my ( $self, $params ) = @_;

    my $DB = $params->{store};
    my $skip_count = $DB->fetch( { val => 'skip_count' } ) || 0;
	my $skip_command = $params->{config}->{main}{skip_command_n_times};

    $skip_count++;
    $DB->store( { ref => { skip_count => $skip_count } } );

	if($skip_count >= $skip_command) {

	    if( $params->{config}->{main}{run_only_after_n_mins} ) {

            $self->run_only_after_n_mins (

                    {
                        store  => $DB,
                        config => $params->{config},
                    }

			);

		}
		else {

            $self->run_command(
                {
                    store   => $DB,
                    command => $params->{config}->{main}{command},
                }
            );

		}
	}

}

sub run_only_after_n_mins {

    my ( $self, $params ) = @_;

    my $DB = $params->{store};
    my $ran_epoch = $DB->fetch( { val => 'ran_epoch' } ) || 0;
    my $now = time();
	my $run_only_after_n_mins = $params->{config}->{main}{run_only_after_n_mins};
    my $ran_seconds_ago = $now - $ran_epoch;
	my $mins_ago = int($ran_seconds_ago / 60);
   
    if($mins_ago >= $run_only_after_n_mins) {

        $self->run_command(
            {
                store   => $DB,
                command => $params->{config}->{main}{command},
            }
        );
	}
}

sub run_command {

    my ( $self, $params ) = @_;

    my $DB              = $params->{store};
    my $now             = time();

    system( $params->{command} );
    INFO "ran [$params->{command}]";
    $DB->store({ref => {command => $params->{command}}});
    $DB->store({ref => {ran_epoch => time()}});
    $DB->store({ref => {skip_count => 0}});

}

1;

__END__

=pod


the following are internal methods used by the plugin manager, they are not for use externally


=over

=item C<check_run_command>

=item C<config_file_valid_enabled>

=item C<create_default_config>

=item C<enabled_config_file>

=item C<enabled_config_file_clear>

=item C<enabled_config_file_isset>

=item C<enabled_config_file_reset>

=item C<new>

=item C<run_command>

=item C<status_hash>

=item C<status_hash_clear>

=item C<status_hash_isset>

=item C<status_hash_reset>

=item C<status_list>

=item C<status_list_clear>

=item C<status_list_isset>

=item C<status_list_reset>

=item C<validate_config_file>

=item C<run_only_after_n_mins>

=item C<skip_command_n_times>

=back 

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jon Brookes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.




=cut


