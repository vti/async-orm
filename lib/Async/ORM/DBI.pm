package Async::ORM::DBI;

use Any::Moose;

sub new {
    my $class = shift;

    my %params = @_;

    my $driver = delete $params{driver} || 'Async::ORM::DBI::Simple';

    #unless (Any::Moose::is_class_loaded($driver)) {
        #Any::Moose::load_class($driver);
    #}

    eval "require $driver;";
    die $@ if $@;

    return $driver->new(%params);
}

1;
__END__

=head1 NAME

Async::ORM - Asynchronous Object-relational mapping

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<attr>

=head1 METHODS

=head2 C<new>

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
