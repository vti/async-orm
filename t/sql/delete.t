use Test::More tests => 3;

use Async::ORM::SQLBuilder;

my $sql = Async::ORM::SQLBuilder->build('delete');

$sql->table('foo');
is("$sql", "DELETE FROM `foo`");

$sql = Async::ORM::SQLBuilder->build('delete');
$sql->table('foo');
$sql->where([id => 2]);
is("$sql", "DELETE FROM `foo` WHERE (`id` = ?)");
is_deeply($sql->bind, [2]);
