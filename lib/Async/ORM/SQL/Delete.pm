package Async::ORM::SQL::Delete;

use Any::Moose;

extends 'Async::ORM::SQL';

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
