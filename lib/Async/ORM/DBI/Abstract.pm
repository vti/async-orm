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
