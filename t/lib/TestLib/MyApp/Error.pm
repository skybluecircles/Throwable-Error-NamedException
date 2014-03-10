package TestLib::MyApp::Error;

use TestLib::MyApp::Error::Error;

use Moose;
extends 'Throwable::Error::NamedException';

has static_error => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'Something happened',
    init_arg => undef,
);

sub customized_error {
    my $exception = shift;

    my $message = 'Something happened to %s';
    my $param   = 'foo';
    my $foo     = $exception->get_message_param( $param );

    return sprintf $message, $foo;
}

__PACKAGE__->meta()->make_immutable();

1;
