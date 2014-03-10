package TestFor::Throwable::Error::NamedException;

use TestLib::MyApp::Error;
use Test::Class::Moose;
use Test::Fatal;

sub test_static_error_message {
    like(
        exception {
            TestLib::MyApp::Error->throw( exception_name => 'static_error' );
        },
        qr/^Something happened/,
    );
}

sub test_customized_error_message {
    like(
        exception {
            TestLib::MyApp::Error->throw(
                exception_name => 'customized_error',
                message_params => { foo => 'bar' },
            );
        },
        qr/^Something happened to bar/,
    );
}

sub test_missing_param {
    like(
        exception {
            TestLib::MyApp::Error->throw(
                exception_name => 'customized_error',
                message_params => { bar => 'baz' },
            );
        },
        qr/^An exception was raised while handling an exception/,
    );
}

1;
