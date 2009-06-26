package Async::ORM::DBI::AnyEvent;

use Any::Moose;

extends 'Async::ORM::DBI::Abstract';

use AnyEvent::DBI;

sub BUILD {
    my $self = shift;

    my $dbh = AnyEvent::DBI->new($self->dbi, $self->user, $self->pass);

    $self->dbh($dbh);

    return $self;
}

sub exec {
    my $self = shift;
    my ($sql, $args, $cb) = @_;

    $self->dbh->exec(
        $sql => @$args => sub {
            $self->dbh($_[0]);

            $cb->($self, $_[1], $_[2]);
        }
    );
}

sub begin_work {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->begin_work(sub { $self->dbh($_[0]); $cb->($self) });
}

sub commit {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->commit(sub { $self->dbh($_[0]); $cb->($self) });
}

sub rollback {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->rollback(sub { $self->dbh($_[0]); $cb->($self) });
}

sub func {
    my $self = shift;
    my ($name, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my @args = map { defined $_ ? "'$_'" : 'undef' } @$args;

    $self->dbh->func(
        join(',', @args) => $name => sub {
            $self->dbh($_[0]);

            $cb->($self, $_[1]);
        }
    );
}

__PACKAGE__->meta->make_immutable;

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
