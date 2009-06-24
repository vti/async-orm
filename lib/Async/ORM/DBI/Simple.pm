package Async::ORM::DBI::Simple;

use Any::Moose;

extends 'Async::ORM::DBI::Abstract';

use DBI;

sub BUILD {
    my $self = shift;

    $self->connect if $self->dbi;

    return $self;
}

sub connect {
    my $self = shift;

    my $dbh = DBI->connect($self->dbi, $self->user, $self->pass, $self->attr)
      or die $DBI::errstr;

    $self->dbh($dbh);
}

sub exec {
    my $self = shift;
    my ($sql, $args, $cb) = @_;

    ($cb, $args) = ($args, []) unless $cb;

    my $sth = $self->dbh->prepare_cached($sql, undef, 1) or die $DBI::errstr;

    my $rv = $sth->execute(@$args) or die $sth->errstr;

    return $cb->(
        $self,
        $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref : undef,
        {rv => $rv}
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
