package Async::ORM::SQLBuilder;

use Any::Moose;

sub build {
    my $class = shift;
    my $command = shift;

    die 'command is required' unless $command;

    my $command_class = 'Async::ORM::SQL::' . ucfirst $command;
    unless (Any::Moose::is_class_loaded($command_class)) {
        Any::Moose::load_class($command_class);
    }

    return $command_class->new(@_);
}

1;
