use Test::More tests => 3;

use lib 't/lib';

use Author;

my $author = Author->new;

ok($author);
is_deeply([$author->columns], []);

$author->column(id => 'boo');
is_deeply([$author->columns], [qw/ id /]);
