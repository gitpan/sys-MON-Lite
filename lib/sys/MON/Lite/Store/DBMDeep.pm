package sys::MON::Lite::Store::DBMDeep;

use warnings;
use strict;
use DBM::Deep;
	use YAML;

sub new {

    my ( $pkg, $param ) = @_;
    my $self = {};
    bless( $self, $pkg );

    $self->{status_file} = $param->{dir} . '/' . $param->{name} . '.dbm';
	$self->{status_file} =~ s{::}{_}g;
	
	$self->{ref} = DBM::Deep->new( $self->{status_file} );
	

    return $self;
}

sub save {
    my ($self, $param) = @_;

	my @keys = keys(%{$param->{ref}});

	foreach my $key (@keys) {
	    $self->{ref}->{$key} = $param->{ref}->{$key} if $param->{ref}->{$key};
	}
}

sub get {
    my ($self, $param) = @_;
       
	return $self->{ref}->{ $param->{val} };
}

1;

=pod

=head2 get
=head2 new
=head2 save

=cut
