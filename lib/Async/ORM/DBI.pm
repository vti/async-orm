package Async::ORM::DBI;

use Any::Moose;

sub new {
    my $class = shift;

    my %params = @_;

    my $driver = delete $params{driver} || 'Async::ORM::DBI::Simple';

    #unless (Any::Moose::is_class_loaded($driver)) {
        #Any::Moose::load_class($driver);
    #}

    eval "require $driver;";
    die $@ if $@;

    return $driver->new(%params);
}

1;
