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
