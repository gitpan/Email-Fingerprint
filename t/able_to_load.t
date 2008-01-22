#!/usr/bin/perl

use Test::More tests => 3;

BEGIN: {
    use_ok( 'Email::Fingerprint' );
    use_ok( 'Email::Fingerprint::Cache' );
    use_ok( 'Email::Fingerprint::Cache::NDBM' );
}

diag( "Testing Email::Fingerprint $Email::Fingerprint::VERSION, Perl $]" );
