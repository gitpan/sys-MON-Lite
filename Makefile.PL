use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'sys::MON::Lite',
    AUTHOR              => 'Jon Brookes <jon@ajblog.co.uk>',
    VERSION_FROM        => 'lib/sys/MON/Lite.pm',
    ABSTRACT_FROM       => 'lib/sys/MON/Lite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'sys-MON-Lite-*' },
);
