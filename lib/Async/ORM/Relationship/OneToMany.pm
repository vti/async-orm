package Async::ORM::Relationship::OneToMany;

use strict;
use warnings;

use base 'Async::ORM::Relationship::Base';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{map} ||= {};

    return $self;
}

sub map { @_ > 1 ? $_[0]->{map} = $_[1] : $_[0]->{map} }

sub to_source {
    my $self = shift;

    my $table     = $self->orig_class->schema->table;
    my $rel_table = $self->class->schema->table;

    my ($from, $to) = %{$self->map};

    my $as = $self->name;

    return {
        name       => $rel_table,
        join       => 'left',
        as         => $as,
        constraint => ["$as.$to" => "$table.$from"]
    };
}

1;
__END__

=head1 NAME

Async::ORM::Relationship::OneToMany - one to many relationship for Async::ORM

=head1 SYNOPSIS

    package Article;

    use strict;
    use warnings;

    use base 'Async::ORM';

    __PACKAGE__->schema(
        table          => 'article',
        columns        => [qw/ id category_id author_id title /],
        primary_keys   => ['id'],
        auto_increment => 'id',

        relationships => {
            comments => {
                type  => 'one to many',
                class => 'Comment',
                map   => {id => 'comment_id'}
            }
        }
    );

    1;

=head1 DESCRIPTION

One to many relationship for L<Async::ORM>.

=head1 ATTRIBUTES

=head2 C<map>

Hash reference holding columns mappings.

=head1 METHODS

=head2 C<new>

Returns new L<Async::ORM::Relationship::OneToMany> instance.

=head2 C<to_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
