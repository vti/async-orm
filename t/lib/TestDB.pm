package TestDB;

use strict;
use warnings;

use Async::ORM::DBI;
use File::Spec;

sub database {
    return File::Spec->catfile(File::Spec->tmpdir, 'anyevent-orm.db');
}

sub dbh {
    my $db = database();

    return Async::ORM::DBI->new(dbi => "dbi:SQLite:dbname=$db");
}

sub cleanup {
    unlink database();
}

1;
