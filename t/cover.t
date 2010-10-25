#!/usr/bin/perl

use Test::More;
use File::Path;

eval "use Test::Strict";
plan skip_all => "Test::Strict not installed" if $@;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

all_cover_ok( 87, 't/' );

# Clean up
rmtree("cover_db");
