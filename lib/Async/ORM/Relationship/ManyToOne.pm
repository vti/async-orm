package Async::ORM::Relationship::ManyToOne;

use Any::Moose;

extends 'Async::ORM::Relationship::Base';

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
