package Async::ORM::Relationship::ManyToOne;

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

    my ($from, $to) = %{$self->{map}};

    my $constraint = ["$rel_table.$to" => "$table.$from"];

    if ($self->join_args) {
        my $i = 0;
        foreach my $value (@{$self->join_args}) {
            if ($i++ % 2) {
                push @$constraint, $value;
            }
            else {
                push @$constraint, "$rel_table.$value";
            }
        }
    }

    return {
        name       => $rel_table,
        join       => 'left',
        constraint => $constraint
    };
}

1;
