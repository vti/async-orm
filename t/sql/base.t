use Test::More tests => 1;

use Async::ORM::SQL::Base;

my $sql = Async::ORM::SQL::Base->new;
ok($sql->isa('Async::ORM::SQL::Base'));
