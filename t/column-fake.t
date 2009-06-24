use Test::More tests => 3;

use lib 't/lib';

use Author;

my $author = Author->new;

ok($author);

$author->column('foo' => 'bar');
is($author->column('foo'), 'bar');

$author = Author->new(foo => 'bar');
is($author->column('foo'), 'bar');
