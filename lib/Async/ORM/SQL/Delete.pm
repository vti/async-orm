package Async::ORM::SQL::Delete;

use strict;
use warnings;

use base 'Async::ORM::SQL::Base';

sub table { @_ > 1 ? $_[0]->{table} = $_[1] : $_[0]->{table} }
sub where { @_ > 1 ? $_[0]->{where} = $_[1] : $_[0]->{where} }

sub where_logic {
    @_ > 1 ? $_[0]->{where_logic} = $_[1] : $_[0]->{where_logic};
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'DELETE FROM ';
    $query .= '`' . $self->table . '`';

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where);
    }

    return $query;
}

1;
__END__

=head1 NAME

Async::ORM::SQL::Delete - SQL delete for Async::ORM

=head1 SYNOPSIS

    This is used internally.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<table>

Table name.

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
