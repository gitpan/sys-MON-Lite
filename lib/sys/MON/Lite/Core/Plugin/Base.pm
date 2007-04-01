package sys::MON::Lite::Core::Plugin::Base;

=head1 NAME

sys::MON::Lite::Core::Plugin::Base - base package for sysMONLite plugins

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;

use sys::MON::Lite::Util;
use Config::Std;

my $util = sys::MON::Lite::Util->new();

our $VERSION = '0.01';

use Class::MethodMaker [
    scalar => [qw/status summary content enabled config_file name/], ];

use Log::Log4perl qw(:easy);
Log::Log4perl->init( \<<EOT);
log4perl.logger = DEBUG, app
log4perl.appender.app=Log::Dispatch::Syslog
log4perl.appender.app.Facility=user
log4perl.appender.app.layout=SimpleLayout
EOT

sub new {

    my ( $pkg, $config ) = @_;
    my $self = { enabled => 1 };

    $self->{run_params} = $config->{params} if $config->{params};

    bless( $self, $pkg );
    $self->define_default_config;
    return $self;
}

# RUN
# params:
#     $param->{workdir} - where to read config files / store state information
#     $param->{params} - any plugin specific parameters { only really used when specifying plugins to run }
#     $param->{config_name} - optional - specify name of config file, enabling multiple configs
sub run {

    my ( $self, $param ) = @_;

    if ($param->{config_name}) {
        DEBUG "DEBUG: base.pm: config_name[" . $param->{config_name} . "]";
	}
    
    $self->{run_params} = $param->{params} if $param->{params};

    ( $self->{config_file}, $self->{name} ) = $util->validate_config_file(
        {
            package_name => $self->init,
            wd           => $param->{workdir},
            dconf        => \$self->{default_config_file},
            config_name  => $param->{config_name}
        }
    );

	$self->{content} .= "# CONFIG : " . $self->{config_file} . "\n###\n\n";

    $self->{enabled_config_file} = $util->enabled_config_file;

    # choose config - passed parameter hash or config file
    $self->choose_config;

    # run the plugins own service check if enabled
    
    $self->service_check if ( $self->{enabled} );

}

# CHOOSE_CONFIG
# params:
#         $run_params => \hashref to hash of parameters
#
# configuration can be from 1 of 2 places:
#     1. parameters passed as a reference to a hash containing configuration options
#       .or.
#     2. a config file found in the appropriate place under $self->{workdir}
#
# if configuration is not found from 1. or 2. or config file has 'enabled: 0' within it
# this plugin will not run, $self->{enabled} gets set to 0
#
sub choose_config {

    my ( $self, $param ) = @_;

    # we have parameters passed directly to run
    if ( keys(%{$self->{run_params}}) ) {
        
        $self->save_config_file;
        $self->{enabled} = 1;
    }
    if ( $self->{enabled_config_file} ) {
        
        $self->read_config_file;
        $self->{enabled} = 1;
    }
    else {
        $self->{enabled} = 0;
    }

}

sub save_config_file {
    my ( $self ) = @_;
	my $new_conf = ({});
	$new_conf->{main} = $self->{run_params};
	$new_conf->{main}{enabled} = 1 unless (defined($new_conf->{main}{enabled}));
    write_config $new_conf, $self->{config_file};
}

sub read_config_file {
    my ( $self, $conf ) = @_;

    my %read_config = ();
    read_config $self->{config_file} => %read_config;
    $self->{run_params} = $read_config{main};
}

1;

__END__

=pod

This module is not for use externally.

see L<sys::MON::Lite>

=over

=item C<choose_config>

=item C<config_file>

=item C<config_file_clear>

=item C<config_file_isset>

=item C<config_file_reset>

=item C<content>

=item C<content_clear>

=item C<content_isset>

=item C<content_reset>

=item C<enabled>

=item C<enabled_clear>

=item C<enabled_isset>

=item C<enabled_reset>

=item C<name>

=item C<name_clear>

=item C<name_isset>

=item C<name_reset>

=item C<new>

=item C<read_config_file>

=item C<run>

=item C<save_config_file>

=item C<status>

=item C<status_clear>

=item C<status_isset>

=item C<status_reset>

=item C<summary>

=item C<summary_clear>

=item C<summary_isset>

=item C<summary_reset>

=back 

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jon Brookes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
