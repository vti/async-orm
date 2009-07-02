package Async::ORM::SQL;

use Any::Moose;

sub build {
    my $class = shift;
    my $command = shift;

    die 'command is required' unless $command;

    my $command_class = 'Async::ORM::SQL::' . ucfirst $command;
    unless (Any::Moose::is_class_loaded($command_class)) {
        Any::Moose::load_class($command_class);
    }

    return $command_class->new(@_);
}

1;
__END__

=head1 NAME

Async::ORM::SQL - SQL factory for Async::ORM

=head1 SYNOPSIS

    my $sql = Async::ORM::SQL->build('select');

    $sql = Async::ORM::SQL->build('insert');
    $sql->table('foo');
    $sql->columns([qw/a b c/]);
    $sql->bind([qw/a b c/]);

=head1 DESCRIPTION

This an SQL factory for L<Async::ORM>.

=head1 METHODS

=head2 C<build>

Returns a new instance of L<Async::ORM::SQL::Select>, L<Async::ORM::SQL::Insert>,
L<Async::ORM::SQL::Update> or L<Async::ORM::SQL::Delete>.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
