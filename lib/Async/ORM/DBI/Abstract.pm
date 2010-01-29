package Async::ORM::DBI::Abstract;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub dbi  { @_ > 1 ? $_[0]->{dbi}  = $_[1] : $_[0]->{dbi} }
sub user { @_ > 1 ? $_[0]->{user} = $_[1] : $_[0]->{user} }
sub pass { @_ > 1 ? $_[0]->{pass} = $_[1] : $_[0]->{pass} }
sub attr { @_ > 1 ? $_[0]->{attr} = $_[1] : $_[0]->{attr} }
sub dbh  { @_ > 1 ? $_[0]->{dbh}  = $_[1] : $_[0]->{dbh} }

1;
__END__

=head1 NAME

Async::ORM::DBI::Abstract - Base class for Async::ORM::DBI drivers

=head1 SYNOPSIS

    package Async::ORM::DBI::MyNewDriver;

    use strict;
    use warnings;

    use base 'Async::ORM::DBI::Abstract';

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

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
