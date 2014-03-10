package Throwable::Error::NamedException;

use Moose;
extends 'Throwable::Error';

has name => (
    is      => 'ro',
    isa     => 'Str',
    default => q{},
);

has message_params => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        get_message_param        => 'get',
        all_message_params       => 'elements',
        message_param_keys       => 'keys',
        message_param_values     => 'values',
        message_param_exists     => 'exists',
        message_param_is_defined => 'defined',
        message_params_is_empty  => 'is_empty',
    },
);

has '+message' => (
    builder => '_build_message',
    lazy    => 1,
);

sub _build_message {
    my $exception = shift;

    if ( $exception->name ) {
        my $named_exception = $exception->name;

        # get meta and check that $named_exception exists as a method or as an attribute

        return $exception->$named_exception;
    }
};

__PACKAGE__->meta()->make_immutable();

1;

=pod

=SYNOPSIS

  package MyApp::Error;

  use Moose;
  use Moosex::Params::Validate;

  extends 'Throwable::Error::NamedException';

  has file_not_found => (
      is      => 'ro',
      isa     => 'Str',
      default => 'I could not find the file you asked me to open',
  );

  sub empty_file {
      my $exception = shift;

      my ( $path ) = validated_list( [ $exception->all_params ],
          path => { isa => 'Str' }, );

      my $message = q{Your file at '%s' is empty};

      return sprintf( $message, $path );
  }

...and in your app...

  use MyApp::Error;

  my $path = '/path/to/file';
  if ( ) {
      MyApp::Error->throw( name => 'file_not_found' );
  }
  elsif ( ) {
      MyApp::Error->throw( name => 'empty_file', message_params => { path => $path } );
  }

...and in your test...

  use Test::Fatal;

  my $test = shift;

  my $exception = exception { MyApp->foo() };

  my $expected_exception_name = 'could_not_do_foo';
  my $expected_message
      = 'I could not foo - not in a house and not with a mouse. I will not foo, either here or there. I will not foo, anywhere!';

  is( $exception->name(), $expected_exception_name );

  # or

  like( $exception->message(), qr/^$expected_message/ );

=head1 DESCRIPTION

This module let's you organize your exceptions by giving them names - like a more robust version of historic error codes.

It can be helpful if you find yourself repeating the same message multiple times or if your module is so large that you need to structure your error handling.

It can also help you to think through the ways in which your code can fail and help you provide more robust messages to your users.

However, you might want to wait to use this module, particularly constructing your messages with C<message_params> until you really need it.

This module will add complexity. Also, ideally, you would test for any situation where your code throws a named exception.

=head1 METHODS

This module does not add any additional methods to L<Throwable::Error>. You still just use C<throw>. However, it does add two new parameters C<exception_name> and C<message_params>.

Also, if you don't pass a C<exception_name>, you can still use Throwable::Error as before.

  MyApp::Error->throw( message => 'Something happened...' );

=head1 STATIC ERROR MESSAGES

If you want to throw a static error message by name you can just make it an attribute in your version of MyApp::Error.

  has some_error => (
      is      => 'ro',
      isa     => 'Str',
      default => 'Something happened',
  )

When MyApp::Error->throw( expcetion_name => 'some_error' ) is called, Throwable::Error would get the message 'Something happened'.

The C<type> should probably be a string. The C<default> should be your error message.

=head1 CUSTOMIZED ERROR MESSAGE

If you would like to customize your error message, you can also pass C<throw> a hash ref to C<message_params>.

  MyApp::Error->throw(
      exception_name => 'some_other_error',
      message_params => { foo => 'bar' },
  );

Rather than creating an attribute called C<some_other_error>, you create it as a method.

  sub some_other_error {
      my $exception = shift;

      my $foo = $exception->get_message_param('foo');

      return "Something happened to $foo";
  }

  # Would die with the message 'Something happened to bar'

=head1 ACCESSING THE ELEMENTS IN MESSAGE_PARAMS

To access the elements in C<message_params> you have the following methods available to you:

=over4

=item B<get_message_param>

Returns a value (or values) from C<message_params>.

In list context it returns a list of values in C<message_params> for the given keys. In scalar context it returns the value for the last key specified.

This method requires at least one argument.

  my $foo = $exception->get_message_param('foo');

  my ( $foo, $bar, $bang )
      = $exception->get_message_param( qw/foo bar bang/ );

  my $bang = $exception->get_message_param( qw/foo bar bang/ );

=item =B<all_message_params>

Returns the key/value pairs in C<message_params> as a flattened list.

This method does not accept any arguments.

  my %message_params = $exception->all_message_params;

=item B<message_param_keys>

Returns the list of keys in C<message_params>.

This method does not accept any arguments.

  my @keys = $exception->message_param_keys;

=item B<message_param_values>

Returns the list of values in C<message_params>.

This method does not accept any arguments.

  my @values = $exception->message_param_values;

=item B<message_param_exists>

Returns true if the given key is present in C<message_params>.

This method requires a single argument.

  if ( $exception->message_param_exists('foo') ) {
      ...
  }

=item B<message_param_is_defined>

Returns true if the value of a given key is defined.

This method requires a single argument.

  if ( $exception->message_param_is_defined('bar') ) {
      ...
  }

=item B<message_params_is_empty>

If the C<message_params> is populated, returns false. Otherwise, returns true.

This method does not accept any arguments.

  if ( $exception->message_params_is_empty ) {
      ...
  }

=back

If there is need for accessing C<message_params> in other ways like getting a count of the elements in it, please let me know.

=head1 TESTING

If an exception is raised while handling an exception it could be pretty confusing for your users to debug.

So, it is highly recommended that you test the exceptions you have created, particularly if you are creating customized ones.

At the very least, this can be started in the method you create. Let's revise the previous example:

  sub some_other_error {
      my $exception = shift;

      if ( $exception->message_param_exists('foo') ) {
          my $foo = $exception->get_message_param('foo');
          return "Something happened to $foo";
      }
      else {
          MyApp::Error->throw( exception_name => 'exceptional_exception' );
      }
  }

You could also include a test case for 'some_other_error' in whatever tests you write. Here we'll give an example with L<Test::Class::Moose> and L<Test::Fatal>.

  use Test::Class::Moose;
  use Test::Fatal;

  sub test_some_other_error {
      my $bad_param = 'baz';
      my $exception = exception{ MyApp->foo( bar => $bad_param ) };

      is( $exception->name, 'some_other_error',
          q{Received expected exception 'some_other_error' while trying to 'foo'}
      );
  }

=head1 SEE ALSO

L<Throwable::Error>
L<Test::Class::Moose>
L<Test::Fatal>

=cut
