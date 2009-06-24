use Test::More tests => 4;

use Async::ORM::SQLBuilder;

my $sql = Async::ORM::SQLBuilder->build('select');

ok(defined $sql);
ok($sql->isa('Async::ORM::SQL::Select'));

$sql = Async::ORM::SQLBuilder->build('insert',
                          table   => 'foo',
                          columns => [qw/ a b c /],
                          bind    => [qw/ a b c/]);
is("$sql", "INSERT INTO `foo` (`a`, `b`, `c`) VALUES (?, ?, ?)");
is_deeply($sql->bind, [qw/ a b c /]);
