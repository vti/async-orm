package Async::ORM::SQL::Update;

use strict;
use warnings;

use base 'Async::ORM::SQL::Base';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{columns} ||= [];

    return $self;
}

sub table { @_ > 1 ? $_[0]->{table} = $_[1] : $_[0]->{table} }
sub where { @_ > 1 ? $_[0]->{where} = $_[1] : $_[0]->{where} }

sub where_logic {
    @_ > 1 ? $_[0]->{where_logic} = $_[1] : $_[0]->{where_logic};
}
sub columns { @_ > 1 ? $_[0]->{columns} = $_[1] : $_[0]->{columns} }

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
__END__

=head1 NAME

Async::ORM::SQL::Update - SQL update for Async::ORM

=head1 SYNOPSIS

    This is used internally.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<table>

Table name.

=head2 C<columns>

Column values.

=head2 C<where>

WHERE clause.

=head2 C<where_logic>

WHERE clause logic (AND and OR).

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
