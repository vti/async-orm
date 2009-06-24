package Async::ORM::Relationship::Base;

use Any::Moose;

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
