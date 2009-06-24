package Async::ORM::RelationshipFactory;

use Any::Moose;

sub build {
    my $class  = shift;
    my %params = @_;

    die 'type is required' unless $params{type};

    my @parts = map {ucfirst} split(' ', $params{type});
    my $rel_class = "Async::ORM::Relationship::" . join('', @parts);

    unless (Any::Moose::is_class_loaded($rel_class)) {
        Any::Moose::load_class($rel_class);
    }

    return $rel_class->new(%params);
}

1;
