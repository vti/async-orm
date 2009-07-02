package Async::ORM::Relationship::ManyToMany;

use Any::Moose;

extends 'Async::ORM::Relationship::Base';

has _map_class => (
    is => 'rw'
);
has map_from => (
    is => 'rw'
);
has map_to => (
    is => 'rw'
);

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(
        @_,
        _map_class => delete $params{map_class},
    );

    return $self;
}

sub map_class {
    my $self = shift;

    my $map_class = $self->_map_class;

    unless (Any::Moose::is_class_loaded($map_class)) {
        Any::Moose::load_class($map_class);
    }

    return $map_class;
}

sub class {
    my $self = shift;

    my $map_class = $self->map_class;
    unless (Any::Moose::is_class_loaded($map_class)) {
        Any::Moose::load_class($map_class);
    }

    $self->_class($map_class->schema->relationships->{$self->map_to}->class)
      unless $self->_class;

    return $self->SUPER::class;
}

sub to_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->schema->relationships->{$map_to}->map};

    my $table = $self->class->schema->table;
    my $map_table = $self->map_class->schema->table;

    my $as = $self->name;

    return {
        name       => $table,
        as         => $as,
        join       => 'left',
        constraint => ["$as.$to" => "$map_table.$from"]
    };
}

sub to_map_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->schema->relationships->{$map_from}->map};

    my $table = $self->orig_class->schema->table;
    my $map_table = $self->map_class->schema->table;

    return {
        name       => $map_table,
        join       => 'left',
        constraint => ["$table.$to" => "$map_table.$from"]
    };
}

sub to_self_map_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->schema->relationships->{$map_to}->map};

    my $table = $self->class->schema->table;
    my $map_table = $self->map_class->schema->table;

    return {
        name       => $map_table,
        join       => 'left',
        constraint => ["$table.$to" => "$map_table.$from"]
    };
}

sub to_self_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->schema->relationships->{$map_from}->map};

    my $table = $self->orig_class->schema->table;
    my $map_table = $self->map_class->schema->table;

    my $rel_as = $self->_rel_as;

    return {
        name       => $table,
        as         => $rel_as,
        join       => 'left',
        constraint => ["$rel_as.$to" => "$map_table.$from"]
    };
}

sub _rel_as {
    my $self = shift;

    my $relationship;

    foreach my $rel_hash ($self->class->schema->relationships) {
        my ($rel) = values %$rel_hash;

        if (   $rel->type eq 'many to many'
            && $rel->_map_class eq $self->map_class)
        {
            $relationship = $rel;
            last;
        }
    }

    die 'can not find reverse relationship' unless $relationship;

    return $relationship->name;
}

1;
__END__

=head1 NAME

Async::ORM::Relationship::ManyToMany - many to many relationship for Async::ORM

=head1 SYNOPSIS

=head1 DESCRIPTION

Many to one relationship for L<Async::ORM>.

=head1 ATTRIBUTES

=head2 C<map_from>

Relationship name of original class.

=head2 C<map_to>

Relationship name of related class.

=head1 METHODS

=head2 C<new>

Returns a new L<Async::ORM::Relationship::ManyToMany> instance.

=head2 C<map_class>

Returns and automatically loads a map class.

=head2 C<class>

Returns and automatically loads related class.

=head2 C<to_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head2 C<to_map_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head2 C<to_self_map_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head2 C<to_self_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
