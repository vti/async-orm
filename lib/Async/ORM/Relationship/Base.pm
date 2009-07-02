package Async::ORM::Relationship::Base;

use Any::Moose;

has name => (
    is       => 'rw',
    required => 1
);

has type => (
    is => 'rw'
);

has _orig_class => (
    is => 'rw'
);

has _class => (
    is => 'rw'
);

has with => (
    is => 'rw'
);

has where => (
    is      => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has join_args => (
    isa => 'ArrayRef',
    is => 'rw'
);

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(
        @_,
        _orig_class => delete $params{orig_class},
        _class      => delete $params{class}
    );
    
    return $self;
}

sub orig_class {
    my $self = shift;

    my $orig_class = $self->_orig_class;

    unless (Any::Moose::is_class_loaded($orig_class)) {
        Any::Moose::load_class($orig_class);
    }

    return $orig_class;
}

sub class {
    my $self = shift;

    my $class = $self->_class;

    unless (Any::Moose::is_class_loaded($class)) {
        Any::Moose::load_class($class);
    }

    return $class;
}

sub related_table {
    my $self = shift;

    return $self->class->schema->table;
}

1;
__END__

=head1 NAME

Async::ORM::Relationship::Base - A base class for Async::ORM relationships

=head1 SYNOPSIS

    package My::Relationship;

    use Any::Moose;

    extends 'Async::ORM::Relationship::Base';

    ...

=head1 DESCRIPTION

This is a base class for all L<Async::ORM> relationships.

=head1 ATTRIBUTES

=head2 C<new>

Returns new L<Async::ORM::Relationship::Base> instance.

=head2 C<name>

Holds relationship name.

=head2 C<type>

Holds relationship type.

=head2 C<with>

Holds relationships that are fetched automatically.

=head2 C<where>

Array reference that is passed to every where clause.

=head2 C<join_args>

Despite of automatic joins you can specify additional join args.

=head1 METHODS

=head2 C<orig_class>

Returns original class automatically loading it.

=head2 C<class>

Returns related class automatically loading it.

=head2 C<related_table>

Returns related table name.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
