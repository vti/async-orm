use Test::More tests => 1;

use Async::ORM::SQL;

my $sql = Async::ORM::SQL->new;
ok($sql->isa('Async::ORM::SQL'));
