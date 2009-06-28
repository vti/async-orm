use Test::More tests => 2;

use Async::ORM::Relationship;

my $rel = Async::ORM::Relationship->build(name => 'foo', type => 'many to one');
ok($rel);

is(ref $rel, 'Async::ORM::Relationship::ManyToOne');
