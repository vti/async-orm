package Async::ORM::SQL::Insert;

use strict;
use warnings;

use base 'Async::ORM::SQL::Base';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{columns} ||= [];

    return $self;
}

sub table   { @_ > 1 ? $_[0]->{table}   = $_[1] : $_[0]->{table} }
sub columns { @_ > 1 ? $_[0]->{columns} = $_[1] : $_[0]->{columns} }

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
__END__

=head1 NAME

Async::ORM::SQL::Insert - SQL insert for Async::ORM

=head1 SYNOPSIS

    This is used internally.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<table>

Table name.

=head2 C<columns>

Column values.

=head1 METHODS

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
