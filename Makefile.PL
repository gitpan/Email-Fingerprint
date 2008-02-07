use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Fingerprint',
    AUTHOR              => 'Len Budney <lbudney@pobox.com>',
    VERSION_FROM        => 'lib/Email/Fingerprint.pm',
    ABSTRACT_FROM       => 'lib/Email/Fingerprint.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    INST_SCRIPT         => 'blib/bin',
    INSTALLSCRIPT       => '/usr/local/bin',
    EXE_FILES           => [ 'bin/eliminate-dups' ],
    MAN1PODS            => {
         'bin/eliminate-dups' => "\$(INST_MAN1DIR)/eliminate-dups.1",
    },
    PREREQ_PM => {
        'Carp'          => 0,
        'Test::More'    => 0,
        'Fcntl'         => 0,
        'FileHandle'    => 0,
        'Mail::Header'  => 0,
        'NDBM_File'     => 0,
        'Class::Std'    => 0,
        'Scalar::Util'  => 0,
        'overload'      => 0,
        'File::Slurp'   => 0,
        'List::MoreUtils'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Fingerprint-*' },
);
