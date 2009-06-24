package Async::ORM::Relationship::OneToMany;

use Any::Moose;

extends 'Async::ORM::Relationship';

has map => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} }
);

sub to_source {
    my $self = shift;

    my $table     = $self->orig_class->schema->table;
    my $rel_table = $self->class->schema->table;

    my ($from, $to) = %{$self->map};

    return {
        name       => $rel_table,
        join       => 'left',
        constraint => ["$rel_table.$to" => "$table.$from"]
    };
}

1;
