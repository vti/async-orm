package Async::ORM::Relationship::ManyToMany;

use Any::Moose;

extends 'Async::ORM::Relationship';

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

    return {
        name       => $table,
        join       => 'left',
        constraint => ["$table.$to" => "$map_table.$from"]
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

1;
