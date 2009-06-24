use Test::More tests => 2;

use Async::ORM::RelationshipFactory;

my $rel = Async::ORM::RelationshipFactory->build(type => 'many to one');
ok($rel);

is(ref $rel, 'Async::ORM::Relationship::ManyToOne');
