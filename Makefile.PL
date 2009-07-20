use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Async::ORM',
    AUTHOR        => 'Viacheslav Tikhanovskii <vti@cpan.org>',
    VERSION_FROM  => 'lib/Async/ORM.pm',
    ABSTRACT_FROM => 'lib/Async/ORM.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Any::Moose'    => 0
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'Async-ORM-*'}
);
