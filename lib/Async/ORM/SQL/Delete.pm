package Async::ORM::SQL::Delete;

use Any::Moose;

extends 'Async::ORM::SQL::Base';

has table => (
    is => 'rw'
);

has where => (
    is => 'rw'
);

has where_logic => (
    is      => 'rw',
    default => 'AND'
);

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'DELETE FROM ';
    $query .= '`' . $self->table . '`';

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where);
    }

    return $query;
}

1;
__END__

=head1 NAME

Async::ORM::SQL::Delete - SQL delete for Async::ORM

=head1 SYNOPSIS

    This is used internally.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<table>

Table name.

=head2 C<where>

WHERE clause.

=head2 C<where_logic>

WHERE clause logic (AND and OR).

=head1 METHODS

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
