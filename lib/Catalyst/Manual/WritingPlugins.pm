=head1 NAME

Catalyst::Manual::WritingPlugins - An introduction to writing plugins
with L<NEXT>.

=head1 DESCRIPTION

Writing an integrated plugin for L<Catalyst> using L<NEXT>.

=head1 WHY PLUGINS?

A Catalyst plugin is an integrated part of your application. By writing
plugins you can, for example, perform processing actions automatically,
instead of having to C<forward> to a processing method every time you
need it.

=head1 WHAT'S NEXT?

L<NEXT> is used to re-dispatch a method call as if the calling method
doesn't exist at all. In other words: If the class you're inheriting
from defines a method, and you're overloading that method in your own
class, NEXT gives you the possibility to call that overloaded method.

This technique is the usual way to plug a module into Catalyst.

=head1 INTEGRATING YOUR PLUGIN

You can use L<NEXT> for your lugin by overloading certain methods which
are called by Catalyst during a request.

=head2 The request life-cycle

Catalyst creates a context object (C<$context> or, more usually, its
alias C<$c>) on every request, which is passed to all the handlers that
are called from preparation to finalization.

For a complete list of the methods called during a request, see
L<Catalyst::Manual::Internals>. The request can be split up in three
main stages:

=over 4

=item preparation

When the C<prepare> handler is called, it initializes the request
object, connections, headers, and everything else that needs to be
prepared. C<prepare> itself calls other methods to delegate these tasks.
After this method has run, everything concerning the request is in
place.

=item dispatch

The dispatching phase is where the black magic happens. The C<dispatch>
handler decides which actions have to be called for this request.

=item finalization

Catalyst uses the C<finalize> method to prepare the response to give to
the client. It makes decisions according to your C<response> (e.g. where
you want to redirect the user to). After this method, the response is
ready and waiting for you to do something with it--usually, hand it off
to your View class.

=back

=head2 What Plugins look like

There's nothing special about a plugin except its name. A module named
C<Catalyst::Plugin::MyPlugin> will be loaded by Catalyst if you specify it
in your application class, e.g.:

    # your plugin
    package Catalyst::Plugin::MyPlugin;
    use warnings;
    use strict;
    ...

    # MyApp.pm, your application class
    use Catalyst qw/-Debug MyPlugin/;

This does nothing but load your module. We'll now see how to overload stages of the request cycle, and provide accessors.

=head2 Calling methods from your Plugin

Methods that do not overload a handler are available directly in the
C<$c> context object; they don't need to be qualified with namespaces,
and you don't need to C<use> them.

    package Catalyst::Plugin::Foobar;
    use strict;
    sub foo { return 'bar'; }

    # anywhere else in your Catalyst application:

    $c->foo(); # will return 'bar'

That's it.

=head2 Overloading - Plugging into Catalyst

If you don't just want to provide methods, but want to actually plug
your module into the request cycle, you have to overload the handler
that suits your needs.

Every handler gets the context object passed as its first argument. Pass
the rest of the arguments to the next handler in row by calling it via

    $c->NEXT::handler-name( @_ );

if you already C<shift>ed it out of C<@_>. Remember to C<use> C<NEXT>.
 
=head2 Storage and Configuration

Some Plugins use their accessor names as a storage point, e.g.

  sub my_accessor {
    my $c = shift;
    $c->{my_accessor} = ..

but it is more safe and clear to put your data in your configuration
hash:

    $c->config->{my_plugin}{ name } = $value;

If you need to maintain data for more than one request, you should
store it in a session.

=head1 EXAMPLE

Here's a simple example Plugin that shows how to overload C<prepare> 
to add a unique ID to every request:

    package Catalyst::Plugin::RequestUUID;
    use warnings;
    use strict;
  
    use NEXT;
    use Data::UUID;
    our $VERSION = 0.01;

    sub prepare {
      my $c = shift;
      $c = $c->NEXT::prepare( @_ );

      $c->req->{req_uuid} = Data::UUID->new->create_str;
      $c->log->debug( 'Request UUID "'. $c->req->{req_uuid} .'"' );

      return $c;
    }

    1;

Let's just break it down into pieces:

    package Catalyst::Plugin::RequestUUID;

The package name has to start with C<Catalyst::Plugin::> to make sure you
can load your plugin by simply specifying

    use Catalyst qw/RequestUUID/;

in the application class. L<warnings> and L<strict> are recommended for
all Perl applications.

    use NEXT;
    use Data::UUID;
    our $VERSION = 0.01;

NEXT must be explicitly C<use>d. L<Data::UUID> generates our unique
ID. The C<$VERSION> gets set because it's a) a good habit and b)
L<ExtUtils::ModuleMaker> likes it.

    sub prepare {

These methods are called without attributes (Private, Local, etc.).

    my $c = shift;

We get the context object for this request as the first argument. 

B<Hint!>:Be sure you shift the context object out of C<@_> in this. If
you just do a

  my ( $c ) = @_;

it remains there, and you may run into problems if you're not aware of
what you pass to the handler you've overloaded. If you take a look at

    $c = $c->NEXT::prepare( @_ );

you see you would pass the context twice here if you don't shift it out
of your parameter list.

This line is the main part of the plugin procedure. We call the
overloaded C<prepare> method and pass along the parameters we got. We
also overwrite the context object C<$c> with the one returned by the
called method returns. We'll return our modified context object at the
end.

Note that that if we modify C<$c> before this line, we also modify it
before the original (overloaded) C<prepare> is run. If we modify it
after, we modify an already prepared context. And, of course, it's no
problem to do both, if you need to. Another example of working on the
context before calling the actual handler would be setting header
information before C<finalize> does its job.

    $c->req->{req_uuid} = Data::UUID->new->create_str;

This line creates a new L<Data::UUID> object and calls the C<create_str>
method. The value is saved in our request, under the key C<req_uuid>. We
can use that to access it in future in our application.

    $c->log->debug( 'Request UUID "'. $c->req->{req_uuid} .'"' );

This sends our UUID to the C<debug> log.

The final line

    return $c;

passes our modified context object back to whoever has called us. This
could be Catalyst itself, or the overloaded handler of another plugin.

=head1 SEE ALSO

L<Catalyst>, L<NEXT>, L<ExtUtils::ModuleMaker>, L<Catalyst::Manual::Plugins>,
L<Catalyst::Manual::Internals>.

=head1 THANKS TO

Sebastian Riedel and his team of Catalyst developers as well as all the
helpful people in #catalyst.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

S<Robert Sedlacek, C<phaylon@dunkelheit.at>> with a lot of help from the
poeple on #catalyst.

=cut