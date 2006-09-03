package sys::MON::Lite::Plugin::HTTP::SimpleMultiSiteCheck;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Class::Base );
use Config::Std;
use WWW::Mechanize;

use constant GOOD  => 1;
use constant BAD   => 0;
use constant GREEN => 0;
use constant RED   => 3;

use Data::Dumper;

my %ok = ( 1 => 'ok', 0 => 'error' );

sub init {
    my ( $self, $config ) = @_;

    return $self;
}

sub run {

    my ( $self, $params ) = @_;

    my $plugin_status         = GOOD;
    my $status_summary_string = undef;
    my $status                = GREEN;
    my $content               = undef;
    my %conf;


	my $plugin_short_name;
    if( __PACKAGE__ =~ m{ .+ :: (.+) $ }x) {
	    $plugin_short_name = $1;
	}

    $content .= $plugin_short_name . '--' . __PACKAGE__ . " running ....\n";

    my $config_file;

    if ( $params->{settings}->{configfile} ) {
        $config_file = $params->{settings}->{configfile};
	}
	else {
        $config_file = $plugin_short_name . '.cfg';
	}

    if ( !read_config( $config_file => %conf ) ) {
        $content .= "cant open config file : $!\n";
        $status_summary_string = "cant open config file : $!\n";
    }

    $content .=
      "using config file : " . $config_file . "\n";

    my @keys = keys(%conf);

    foreach my $url (@keys) {
        if ( $url =~ m{URL:\s+(.+)} ) {
            my $addr        = $1;
            my $string      = $conf{$url}{has} || undef;
            my $not         = $conf{$url}{not} || undef;
            my $url_status =
              $self->check_url(
                { addr => $addr, search => $string, not => $not } );
            $status = RED unless $url_status;
            $content .= "[$ok{$url_status}] url:[$url]\n";
        }
    }

    $status_summary_string = "status[$plugin_status]";
    $content .= "status:[" . $status . "]\n";

    return ( $plugin_status, $status, $status_summary_string, $content );
}

sub check_url {

    my ( $self, $params ) = @_;

    my $mech = WWW::Mechanize->new();

    $mech->get( $params->{addr} );

    if ( !$mech->success ) {
        return BAD;
	}

    if ( $params->{search} ) {

        if ( ! ($mech->content =~ m{$params->{search}}i) ) {
            return BAD;

        }
    }

    if ( $params->{not} ) {

        if ( $mech->content =~ m{$params->{not}}i ) {
            return BAD;
		}

    }

    return GOOD;

}

1;

__END__


=head1 NAME

sys::mon::lite::Plugin::HTTP::SimpleMultiSiteCheck - a plugin for sys::MON::Lite

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

a plugin for use with sys::MON::Lite

can check for a valid response from a list of predefined url's

see sys::MON::Lite SYNOPSIS for example use


=head2 PARAMETERS:

following is extracted from sys::MON::Lite module - where this plugin is called from
and what it's return values are expected to be:

        my ( $plugin_status, $result_status, $summary, $content ) =
          $plugin->run( { settings => $config->{settings} } );

=head3 INPUTS

plugins must have passed to them 'settings' if the calling process 
needs to convey configuration information specific to the plugin

this, optional parameter passed by sys::MON::Lite may contain for example:

    configfile => 'configfilename.cfg',

which will overide the default of the modules short name which is appended to become:

    SimpleMultiSiteCheck.cfg

which must be in the current working directory to be found

=head3 RETURN VALUES

=over

=item $plugin_status

=back

the status of the running plugin - 0 being 'successefull', anying greater being an error

=over

=item $result_status - a numeric value [0-3]

=back

the status of the service checks run by the plugin:

=over

=item 0 => GREEN

service is ok, all systems are 'green'

=item 1 => BLUE

service is operational but warnings are given - may need attention soon

=item 2 => YELLOW

service is starting to fail, immediate action required

=item 3 => RED

system is failing - fix it quick !

=back

	$summary
	$content

=head1 INTERNAL SUBROUTINES

=head2 run

automatically called by sys::MON::Lite

=head2 check_url

internally called by run()

=head2  _summarise_plugin_output

internally called by check_url

=head2  init

internally called by sys::MON::Lite when invoking this plugin with a call to 'new();

=head1 AUTHOR

Jon Brookes, C<< <jon at ajblog.co.uk> >>

=head1 BUGS

This is an early release

Module documentation and test suite is scant and in want of more work

Please report any bugs or feature requests to
C<bug-sys-mon-lite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=sys-mon-lite>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc sys::mon::lite::Plugin::HTTP::SimpleMultiSiteCheck

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/sys-mon-lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/sys-mon-lite>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=sys-mon-lite>

=item * Search CPAN

L<http://search.cpan.org/dist/sys-mon-lite>

=back

=head1 ACKNOWLEDGEMENTS

CPAN, Perl

All who have contributed to them

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jon Brookes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of sys::mon::lite
