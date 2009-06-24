package Async::ORM::SQL::Insert;

use Any::Moose;

extends 'Async::ORM::SQL';

has table => (is => 'rw');

has columns => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has bind => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'INSERT INTO ';
    $query .= '`' . $self->table . '`';
    if (@{$self->columns}) {
        $query .= ' (';
        $query .= join(', ', map {"`$_`"} @{$self->columns});
        $query .= ')';
        $query .= ' VALUES (';
        $query .= '?, ' x (@{$self->columns} - 1);
        $query .= '?)';
    }
    else {
        if ($self->driver && $self->driver eq 'mysql') {
            $query .= '() VALUES()';
        }
        else {
            $query .= ' DEFAULT VALUES';
        }
    }

    return $query;
}

1;
