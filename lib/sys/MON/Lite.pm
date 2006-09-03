package sys::MON::Lite;

our $VERSION = '0.01';

use strict;
use warnings;
use base qw( Class::Base );
use Module::Pluggable;

sub init {

    my ( $self, $config ) = @_;

    # set initial summary values
    $self->{manager_status}        = 1;
    $self->{overall_result_status} = 0;
    $self->{overall_summary}       = undef;
    $self->{combined_content}      = undef;
    %{ $self->{status_hash} } = (
        0 => 'GREEN',
        1 => 'BLUE',
        2 => 'YELLOW',
        3 => 'RED',
        4 => 'RED',
    );


    if ($config->{workdir}) {
        $self->{workdir} = $config->{workdir};
		chdir($config->{workdir});
	}

    return $self;
}

sub run {

    my ( $self, $config ) = @_;

    # append search path with addath if specified
    if ( $config->{addpath} ) {
        $self->search_path( add => $config->{addpath} );
    }

    # replace search path with newpath if specified
    if ( $config->{newpath} ) {
        $self->search_path( new => $config->{newpath} );
    }

    # require all plugins in current path
    use Module::Pluggable ( require => 1 );

    # run each plugin in path
    foreach my $plugin ( $self->plugins ) {
	    
        if ( $config->{type} ) {
            next unless $plugin =~ m{ $config->{type} }xi;
        }

        my ( $plugin_status, $result_status, $summary, $content ) =
          $plugin->run( { settings => $config->{settings} } );

        $self->_summarise_plugin_output(
            {
                status  => $plugin_status,
                result  => $result_status,
                summary => $summary,
                content => $content
            }
        );

    }

    $self->{combined_content} .= "Overall Status => ";
    $self->{combined_content} .=
      ${ $self->{status_hash} }{ $self->{overall_result_status} };

    return (
        $self->{manager_status},  $self->{overall_result_status},
        $self->{overall_summary}, $self->{combined_content}
    );

}

sub _summarise_plugin_output {

    my ( $self, $params ) = @_;

    return
      if ( !defined($params->{status})
        || !defined($params->{result})
        || !defined($params->{summary})
        || !defined($params->{content}) );

    $self->{manager_status} = 0 unless $params->{status};
    $self->{overall_result_status} = $params->{result}
      if ( $params->{result} > $self->{overall_result_status} );
    $self->{overall_summary}  .= $params->{summary} . ' ';
    $self->{combined_content} .= $params->{content} . "\n\n";

}

1;

__END__

=head1 NAME

sys::mon::lite - light weight system management framework

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS


'sys::mon::lite' is intended for use:

=over 4

=item * as a  framework for managing a system by means of an extendible
plugin mechanism


=item * to manage single or multiple system checks, calculating an overall
alert level based on the output of a given set of pre-registered
plugins


=item * to augment the monitoring capabilities of existing monitoring solutions


=item * where use of full scale monitoring applications the likes of Nagios, 
BigBrother etc to monitor a systems availability and / or performance
may not be practical and where a simple, stand alone, Perl based
solution will suffice

=back 

=head2 USAGE

    use sys::MON::Lite;

    my ( $manager_status, $result_status, $status_summary_string, $content );


    my $plugin_manager = sys::MON::Lite->new( workdir => '/path/to/working/directory' );

    ( $manager_status, $result_status, $status_summary_string, $content ) =

      $plugin_manager->run;


in '/path/to/working/directory' a config file named as each plugins 'short name'

e.g./

    SimpleMultiSiteCheck.cfg

containing something like this example config file for use with sys::MON::Lite::Plugin::HTTP::SimpleMultiSiteCheck : 

    [URL: http://www.yahoo.com]
    has: </html>
    not: error
    [URL: http://www.bbc.co.uk]
    has: </html>
    not: error
    [URL: http://www.perl.com]
    has: </html>
    not: failure
    [URL: http://search.cpan.org]
    has: </html>
    not: error

=head2 PARAMETERS:

=head2 new

optional parameter - workdir

if specified, will change directory to location given

e.g./

    my $plugin_manager = sys::MON::Lite->new( workdir => '/path/to/working/directory' );


=head2 run

optional parameters - settings, addpath, newpath, type

settings - reference to a hash

e.g./

    my %settings = ( 
        configfile => 'websitecheck.cfg',
    );

above will get passed to each plugin that is found in the plugin search path


the plugin search path is by default below the namespace of the Lite module:

    sys::MON::Lite::Plugins

this may be added to using 'addpath'

e.g./

    addpath => 'another::name::space'

or replaced

    newpath => 'new::name::space'

and plugins may be placed here, rather than the default namespace of sys::Mon::Lite::Plugins

type - a string used to match the plugins in the current Plugin path for running and in doing so, exclude plugins not matching 

e.g/

    type => $type,

where earlier, $type could be defined as:

    my $type = 'Plugins.+SomePlugin.+OrOther';


=head1 INTERNAL SUBROUTINES

=head3  _summarise_plugin_output

called by run() and not intended for external access

=head3  init

invoked by new() and not intended for external access;

=head1 AUTHOR

Jon Brookes, C<< <jon at ajblog.co.uk> >>

=head1 BUGS

This is an early release

Module documentation and test suite is scant and in want of more work

sys::mon::lite is here expressed as an idea - a simple management framework 
for small systems that can be expanded by the addition of plugins

there is only one, publicly released, plugin:

    sys::MON::Lite::Plugin::HTTP::SimpleMultiSiteCheck

sys::MON::Lite is very light of a monitoring framework with only one plugin

more are to be added to this in future releases

more documentation on how to add additional module plugins is needed

Please report any bugs or feature requests to
C<bug-sys-mon-lite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=sys-mon-lite>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc sys::mon::lite

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
