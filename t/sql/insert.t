use Test::More tests => 3;

use Async::ORM::SQL;

my $sql = Async::ORM::SQL->build('insert');

$sql->table('foo');
is("$sql", "INSERT INTO `foo` DEFAULT VALUES");

$sql->table('foo');
$sql->columns([qw/a b c/]);
is("$sql", "INSERT INTO `foo` (`a`, `b`, `c`) VALUES (?, ?, ?)");

$sql = Async::ORM::SQL->build('insert');
$sql->table('bar');
$sql->columns([qw/bo boo booo/]);
is("$sql", "INSERT INTO `bar` (`bo`, `boo`, `booo`) VALUES (?, ?, ?)");
