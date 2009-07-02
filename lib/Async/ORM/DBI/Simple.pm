package Async::ORM::DBI::Simple;

use Any::Moose;

extends 'Async::ORM::DBI::Abstract';

use DBI;

sub BUILD {
    my $self = shift;

    my $dbh = DBI->connect($self->dbi, $self->user, $self->pass, $self->attr)
      or die $DBI::errstr;

    $self->dbh($dbh);

    return $self;
}

sub exec {
    my $self = shift;
    my ($sql, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my $sth = $self->dbh->prepare_cached($sql, undef, 1) or die $DBI::errstr;

    my $rv = $sth->execute(@$args) or die $sth->errstr;

    return $cb->(
        $self, $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref : undef, $rv
    );
}

sub begin_work {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->begin_work or die $DBI::errstr;

    $cb->($self);
}

sub commit {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->commit or die $DBI::errstr;

    $cb->($self);
}

sub rollback {
    my $self = shift;
    my ($cb) = @_;

    $self->dbh->rollback or die $DBI::errstr;

    $cb->($self);
}

sub func {
    my $self = shift;
    my ($name, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my $rv = $self->dbh->func(@$args, $name);

    return $cb->($self, $rv);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Async::ORM::DBI::Simple - Simple DBI wrapper

=head1 SYNOPSIS

    my $dbh = Async::ORM::DBI->new(dbi => "dbi:SQLite:table.db");

=head1 DESCRIPTION

This is just a simple DBI wrapper. It should be used only for sequential
programming. This way you can use L<Async::ORM> in usual scripts.

=head1 ATTRIBUTES

=head2 C<dbh>

    my $dbh = Async::ORM::DBI->new(dbi => "dbi:SQLite:table.db");
    my $original_dbh = $dbh->dbh;

Holds original DBI object.

=head1 METHODS

=head2 C<new>

Returns new L<Async::ORM::DBI::Simple> instance.

=head2 C<BUILD>

Creates internal L<DBI> object. Used internally.

=head2 C<begin_work>

A wrapper for B<begin_work>.

=head2 C<commit>

A wrapper for B<commit>.

=head2 C<exec>

A wrapper for B<exec>.

=head2 C<func>

A wrapper for B<func>.

=head2 C<rollback>

A wrapper for B<rollback>.

=head1 AUTHOR

Viacheslav Tikhanovskii, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tikhanovskii.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
