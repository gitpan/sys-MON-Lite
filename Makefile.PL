use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'sys::MON::Lite',
    AUTHOR        => 'Jon Brookes <jon@ajblog.co.uk>',
    VERSION_FROM  => 'lib/sys/MON/Lite.pm',
    ABSTRACT_FROM => 'lib/sys/MON/Lite.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'        => 0,
        'Module::Pluggable' => 0,
                'Log::Log4perl' =>0,
                'DBM::Deep'         => 0,
                'Class::MethodMaker' => 0,
                'Log::Dispatch::Syslog' => 0,
                'Mail::POP3Client' => 0,
                'Data::GUID' => 0,
                'Net::IMAP::Simple' => 0,
                'Email::Simple' => 0,
        'Config::Std' => 0,
        'YAML' => 0,
        'WWW::Mechanize' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'sys-MON-Lite-*' },
);

