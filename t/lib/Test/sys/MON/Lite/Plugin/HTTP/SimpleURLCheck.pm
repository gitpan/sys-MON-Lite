package Test::sys::MON::Lite::Plugin::HTTP::SimpleURLCheck;

use warnings;
use strict;

use base qw(sys::MON::Lite::Plugin::HTTP::SimpleURLCheck);

{

    package MockMech;

    sub new {
        my ( $pkg, $config ) = @_;

        my $self = {};

        bless( $self, $pkg );

        return $self;
    }

    sub content {
        my $self = shift;
		
        return <<END;

    ding dong !

END
    }

    sub success {
	    my $self = shift;
		
	    if($self->{url} =~ m{where}) {
		    
		    return 0;
		}
		else {
            return 1;
		}
    }

    sub get {
	    my ($self, $url) = @_;
		$self->{url} = $url;
        return 1;
    }

    sub timeout {
        return 1;
    }

    1;

}

sub init {

    my $self = shift;

    $self->{mech} = MockMech->new();
    
    return __PACKAGE__;

}

1;
