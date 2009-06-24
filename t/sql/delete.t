use Test::More tests => 3;

use Async::ORM::SQL;

my $sql = Async::ORM::SQL->build('delete');

$sql->table('foo');
is("$sql", "DELETE FROM `foo`");

$sql = Async::ORM::SQL->build('delete');
$sql->table('foo');
$sql->where([id => 2]);
is("$sql", "DELETE FROM `foo` WHERE (`id` = ?)");
is_deeply($sql->bind, [2]);
