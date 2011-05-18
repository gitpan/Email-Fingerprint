require 5.007003;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Automated tools don't handle this dependency automatically, because
# it's part of perl-core--yet some broken systems are actually missing
# them!
for my $module (qw/
    Carp
    Fcntl
    FileHandle
    NDBM_File
/) {
    eval "use $module";
    die <<EOF if $@;

    ****************************************************************
    I am unable to load the core module "$module". You must install
    $module and then try installing Email::Fingerprint again.  Your
    Perl installation should have included these modules, so if
    they're missing it suggests something might be very wrong, or
    you might be using too old a Perl version.

    Sorry for any inconvenience!
    ****************************************************************

EOF
}


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
        'File::Path'        => 2.08,
        'File::Slurp'       => 0,
        'File::Spec'        => 0,
        'FileHandle'        => 0,
        'List::MoreUtils'   => 0,
        'LockFile::Simple'  => 0,
        'Mail::Header'      => 0,
        'NDBM_File'         => 0,
        'Scalar::Util'      => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0,
        'Test::Warn'        => 0,
        'overload'          => 0,
        'version'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Fingerprint-*' },
);

{
    package MY;
    sub postamble {
        return <<"EOF";
authortest: test
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"

EOF
    }
    
    sub dist_test {
        my $self      = shift;
        my $inherited =  $self->SUPER::dist_test(@_);
        $inherited    =~ s/ test / authortest /;
        return $inherited;
    }
}
