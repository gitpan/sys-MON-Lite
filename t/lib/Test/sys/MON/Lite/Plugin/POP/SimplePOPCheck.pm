package Test::sys::MON::Lite::Plugin::POP::SimplePOPCheck;

use warnings;
use strict;
use sys::MON::Lite::Util;
my $util = sys::MON::Lite::Util->new();

use base qw(sys::MON::Lite::Plugin::POP::SimplePOPCheck);

{

    package MockPOP;

    sub new {
        my ( $pkg, %config ) = @_;
        my $self = {};
        $self->{config} = \%config;
        bless( $self, $pkg );

        return $self;
    }

    sub Count {
        my ($self) = @_;
        return 42 if ($self->{config}{'USER'} =~ m{worky\.worky});
    }

    sub Head {
        my ($self) = @_;
    }

    sub Message {
        my ($self) = @_;
        
        return 'OK' if ($self->{config}{'USER'} =~ m{worky\.worky});

    }

    sub Alive {
        my ($self) = @_;
        return 1 if ($self->{config}{'USER'} =~ m{worky\.worky});
    }

    sub POPStat {
        my ($self) = @_;
    }

    sub State {
        my ($self) = @_;
        return 'TRANSACTION' if ($self->{config}{'USER'} =~ m{worky\.worky});
    }

    sub Close {
        my ($self) = @_;
    }

    1;

}

sub init {

    my $self = shift;

    $self->{pop} = MockPOP->new(

        USER     => $self->{run_params}->{user},
        TIMEOUT  => $self->{run_params}->{timeout},
        PASSWORD => $self->{run_params}->{password},
        HOST     => $self->{run_params}->{host}
    );

    $self->{summary} .= "state:[" . $self->pop->State . "]\n";

    if ( $self->{pop} ) {
        $self->{status} = ${ $util->status_hash }{OK};
    }
    else {
        $self->{status}  = ${ $util->status_hash }{CRITICAL};
        $self->{summary} =
          "can't connect to pop server [$self->{run_params}->{host}] $!\n";
    }
 
    return __PACKAGE__;

}

1;
