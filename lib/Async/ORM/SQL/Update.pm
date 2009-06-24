package Async::ORM::SQL::Update;

use Any::Moose;

extends 'Async::ORM::SQL';

has table => (is => 'rw');

has where_logic => (is => 'rw');

has where => (is => 'rw');

has columns => (
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

    return $self->_string if $self->_string;

    my $query = "";

    $query .= 'UPDATE ';
    $query .= '`' . $self->table . '`';
    $query .= ' SET ';

    my @bind;
    my $i     = @{$self->columns} - 1;
    my $count = 0;
    foreach my $name (@{$self->columns}) {
        if (ref $self->bind->[$count] eq 'SCALAR') {
            my $value = $self->bind->[$count];
            $query .= "`$name` = $$value";
        }
        else {
            $query .= "`$name` = ?";
            push @bind, $self->bind->[$count];
        }

        $query .= ', ' if $i;
        $i--;
        $count++;
    }

    $self->bind([@bind]);

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where);
    }

    return $self->_string($query);
}

1;
