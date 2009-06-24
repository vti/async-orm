package Async::ORM::SQL;

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
