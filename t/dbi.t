use strict;
use warnings;

use Test::More tests => 4;

use File::Spec;

use Async::ORM::DBI;

my $dbi = Async::ORM::DBI->new;
ok($dbi->isa('Async::ORM::DBI::Simple'));

my $db = File::Spec->catfile(File::Spec->tmpdir, 'anyevent-orm.db');
$dbi = Async::ORM::DBI->new(dbh => "dbi:SQLite:$db");
ok($dbi->isa('Async::ORM::DBI::Simple'));
ok($dbi->dbh);
ok($dbi->can('exec'));
