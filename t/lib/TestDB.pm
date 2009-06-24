package TestDB;

use strict;
use warnings;

use Async::ORM::DBI;
use File::Spec;

sub _database {
    return File::Spec->catfile(File::Spec->tmpdir, 'anyevent-orm.db');
}

sub dbh {
    my $db = _database();

    return Async::ORM::DBI->new(dbi => "dbi:SQLite:dbname=$db");
}

sub cleanup {
    unlink _database();
}

1;
