package sys::MON::Lite::Store;

use warnings;
use strict;
use DBM::Deep;
use sys::MON::Lite::Store::DBMDeep;

use Module::Pluggable;

sub new {

    my ( $pkg, $param ) = @_;
    my $self = {};
    bless( $self, $pkg );

    $self->{default_store} = $param->{store} || 'DBMDeep';

    $self->search_path( new => 'sys::MON::Lite::Store' );

  PLUGIN:
    foreach my $store_plugin ( $self->plugins ) {
        if ( $store_plugin !~ m{$self->{default_store}} ) { next PLUGIN }
        #DEBUG ">>$store_plugin\n";
        $self->{db} =
          $store_plugin->new(
            { dir => $param->{dir}, name => $param->{name} } );
    }

    return $self;
}

sub store {
    my ( $self, $param ) = @_;
    
    $self->{db}->save( { ref => $param->{ref} } );
}

sub fetch {
    my ( $self, $param ) = @_;
    return $self->{db}->get( { val => $param->{val} } );
}

1;

__END__

=pod

=head2 fetch
=head2 new
=head2 store

=cut
