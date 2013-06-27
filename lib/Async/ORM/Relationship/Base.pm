package Async::ORM::Relationship::Base;

use strict;
use warnings;

sub new {
    my $class  = shift;
    my %params = @_;

    my $_orig_class = delete $params{orig_class};
    my $_class      = delete $params{class};

    my $self = {%params};
    bless $self, $class;

    $self->{_orig_class} = $_orig_class;
    $self->{_class}      = $_class;

    $self->{where} ||= [];

    return $self;
}

sub name      { @_ > 1 ? $_[0]->{name}      = $_[1] : $_[0]->{name} }
sub type      { @_ > 1 ? $_[0]->{type}      = $_[1] : $_[0]->{type} }
sub with      { @_ > 1 ? $_[0]->{with}      = $_[1] : $_[0]->{with} }
sub where     { @_ > 1 ? $_[0]->{where}     = $_[1] : $_[0]->{where} }
sub join_args { @_ > 1 ? $_[0]->{join_args} = $_[1] : $_[0]->{join_args} }

sub _orig_class {
    @_ > 1 ? $_[0]->{_orig_class} = $_[1] : $_[0]->{_orig_class};
}
sub _class { @_ > 1 ? $_[0]->{_class} = $_[1] : $_[0]->{_class} }

sub orig_class {
    my $self = shift;

    my $orig_class = $self->_orig_class;

    unless ($orig_class->can('new')) {
        eval "require $orig_class";

        die "Error while loading $orig_class: $@" if $@;
    }

    return $orig_class;
}

sub class {
    my $self = shift;

    my $class = $self->_class;

    unless ($class->can('new')) {
        eval "require $class";

        die "Error while loading $class: $@" if $@;
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

    use strict;
    use warnings;

    use base 'Async::ORM::Relationship::Base';

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

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
