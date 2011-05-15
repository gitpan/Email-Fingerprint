require 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Fingerprint',
    AUTHOR              => 'Len Budney <lbudney@pobox.com>',
    VERSION_FROM        => 'lib/Email/Fingerprint.pm',
    ABSTRACT_FROM       => 'lib/Email/Fingerprint.pm',
    LICENSE             => 'perl',
    INST_SCRIPT         => 'blib/bin',
    EXE_FILES           => [ 'bin/eliminate-dups' ],
    NO_META             => 1,
    PREREQ_PM => {
        'Carp'              => 0,
        'Class::Std'        => 0,
        'Fcntl'             => 0,
        'File::Path'        => 2.0,
        'File::Slurp'       => 0,
        'File::Spec'        => 0,
        'FileHandle'        => 0,
        'List::MoreUtils'   => 0,
        'LockFile::Simple'  => 0,
        'Mail::Header'      => 0,
        'NDBM_File'         => 0,
        'Scalar::Util'      => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0,
        'Test::Warn'        => 0,
        'overload'          => 0,
        'version'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Fingerprint-*' },
);
