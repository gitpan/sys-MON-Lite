package Test::sys::MON::Lite::Plugin::IMAP::SimpleIMAPCheck;

use warnings;
use strict;

use base qw(sys::MON::Lite::Plugin::IMAP::SimpleIMAPCheck);

{

    package MockIMAP;

    sub new {
        my ( $pkg, $config ) = @_;

        my $self = {};

        bless( $self, $pkg );

        return $self;
    }

    sub select {
        my $self = shift;
        return 0;
    }

    sub seen {
        my $self = shift;
    }

    sub top {
        my $self = shift;
        return [];
    }

    sub quit {
        my $self = shift;
    }

    1;

}

sub init {

    my $self = shift;

    $self->{imap} = MockIMAP->new();
    
    return __PACKAGE__;

}

1;
