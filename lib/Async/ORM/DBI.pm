package Async::ORM::DBI;

use Any::Moose;

sub new {
    my $class = shift;

    my %params = @_;

    my $driver = delete $params{driver} || 'Async::ORM::DBI::Simple';

    eval "require $driver;";
    die $@ if $@;

    return $driver->new(%params);
}

1;
__END__

=head1 NAME

Async::ORM::DBI - Database handle for Async::ORM

=head1 SYNOPSIS

    my $dbh = Async::ORM::DBI->new(dbi => "dbi:SQLite:table.db");

=head1 DESCRIPTION

This is a dbh factory. Returns a new driver instance that is based on
L<Async::ORM::DBI::Abstract>.

It is created so it is easy to write you own database
handle. Existing implementations include wrappers for L<DBI> and
L<AnyEvent::DBI>.

=head1 METHODS

=head2 C<new>

    my $dbh = Async::ORM::DBI->new(dbi => "dbi:SQLite:table.db");

Returns new L<Async::ORM::DBI> instance. By default L<Async::ORM::DBI::Simple>
is used. To change this behavior pass C<driver> option.

    my $dbh = Async::ORM::DBI->new(
        dbi    => "dbi:SQLite:table.db",
        driver => 'Async::ORM::DBI::AnyEvent'
    );

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
