package Async::ORM::DBI::Abstract;

use Any::Moose;

has dbi => (is => 'rw');

has user => (is => 'rw');

has pass => (is => 'rw');

has attr => (is => 'rw');

has dbh => (is => 'rw');

#requires 'exec';

#requires 'begin_work';

#requires 'commit';

#requires 'rollback';

#requires 'func';

1;
__END__

=head1 NAME

Async::ORM::DBI::Abstract - Base class for Async::ORM::DBI drivers

=head1 SYNOPSIS

    package Async::ORM::DBI::MyNewDriver;

    use Any::Moose;

    extends 'Async::ORM::DBI::Abstract';

    sub exec {
        my $self = shift;
        my ($sql, $args, $cb) = @_;

        ...

        return $cb->($self, $rows, $metadata);
    }

    sub begin_work {
        my $self = shift;
        my ($cb) = @_;

        ...

        $cb->($self);
    }

    sub commit {
        my $self = shift;
        my ($cb) = @_;

        ...

        $cb->($self);
    }

    sub rollback {
        my $self = shift;
        my ($cb) = @_;

        ...

        $cb->($self);
    }

    sub func {
        my $self = shift;
        my ($name, $args, $cb) = @_;

        ...

        return $cb->($self, $rv);
    }

    1;

=head1 DESCRIPTION

Base class for the Async::ORM::DBI drivers. To create you own driver extend this
class providing all nessesary methods.

=head1 METHODS

=head2 C<new>

Returns new driver instance.

=head2 C<exec>

    sub exec {
        my $self = shift;
        my ($sql, $args, $cb) = @_;

        ...

        return $cb->($self, $rows, $metadata);
    }

This is the main method used for running SQL statements.

=head2 C<begin_work>

Starts transaction.

=head2 C<rollback>

Rollbacks transaction.

=head2 C<commit>

Commits transaction.

=head2 C<func>

Runs database function.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
