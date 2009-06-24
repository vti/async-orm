use Test::More tests => 9;

use Async::ORM::SQLBuilder;

my $sql;

$sql = Async::ORM::SQLBuilder->build('update');
$sql->table('foo');
$sql->columns([qw/ hello boo /]);
$sql->bind([1, 2]);
is("$sql", "UPDATE `foo` SET `hello` = ?, `boo` = ?");
is_deeply($sql->bind, [qw/ 1 2 /]);

$sql = Async::ORM::SQLBuilder->build('update');
$sql->table('foo');
$sql->columns([qw/ hello boo /]);
$sql->bind([5, 9]);
$sql->where([id => 3]);
is("$sql", "UPDATE `foo` SET `hello` = ?, `boo` = ? WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 5 9 3 /]);

$sql = Async::ORM::SQLBuilder->build('update');
$sql->table('foo');
$sql->columns([qw/ hello boo /]);
$sql->bind([\'hello + 1', 4]);
$sql->where([id => 5]);
is("$sql", "UPDATE `foo` SET `hello` = hello + 1, `boo` = ? WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 4 5 /]);

$sql = Async::ORM::SQLBuilder->build('update');
$sql->table('foo');
$sql->columns([qw/ hello boo /]);
$sql->bind([\'hello + 1', \'boo + 2']);
$sql->where([id => 5]);
is("$sql", "UPDATE `foo` SET `hello` = hello + 1, `boo` = boo + 2 WHERE (`id` = ?)");
is("$sql", "UPDATE `foo` SET `hello` = hello + 1, `boo` = boo + 2 WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 5 /]);
