#!/usr/bin/perl
#
# Test Email::Fingerprint::Cache.

use lib 'build_lib';

use strict;
use warnings;
use Email::Fingerprint;

use Test::More qw( no_plan );
use Test::Exception;
use Test::Warn;
use Test::Stdout;

# Sentinel object to delete data files
package Sentinel;

sub DESTROY {
    my $self = shift;
    unlink $_ for glob $self->{file} . "*";
}

# Back to our show...
package main;

eval { use Email::Fingerprint::Cache };
plan ( skip_all => "Failed to load Email::Fingerprint::Cache" ) if $@;

############################################################################
# First, run through the general cache functionality, without stressing
# anything or doing anything extra.
############################################################################

my $cache;
my %fingerprints;
my $file     = "t/data/tmp_cache";

lives_ok {
    $cache     =  new Email::Fingerprint::Cache({
        backend   => "NDBM",
        hash      => \%fingerprints,
        file      => $file,         # Created if doesn't exist
        ttl       => 60,            # Purge records after one minute
    });
} "Constructor lives";

# Look up the TTL
can_ok $cache, "get_ttl";
is $cache->get_ttl, 60, "Cache has correct TTL";

# Arrange for cleanup on exit
my $sentinel = bless { file => $file }, "Sentinel";

# Create the file
can_ok $cache, "open";
ok $cache->open, "Opened cache file successfully";

# Add a bunch of "fingerprints", all older than one minute
for my $n ( 1..100 ) {
    my $timestamp = time - 60 - int(rand(100_000_000));
    $fingerprints{$n} = $timestamp;
}

# Now confirm that they're there
is scalar keys %fingerprints, 100, "Added fingerprints OK";

# Double-check using the value returned by get_hash()
is scalar keys %{ $cache->get_hash }, 100, "Double-checking fingerprint count";

# ...and purge them.
$cache->purge;
is scalar keys %fingerprints, 0, "Purged cache successfully";

# Verify that the hash is tied
ok tied %fingerprints ? 1 : 0, "Fingerprints tied";
lives_ok { $cache->close } "Closed cache without incident";
ok tied %fingerprints ? 0 : 1, "Fingerprints untied";
warning_is { undef $cache } undef, "Destroyed without warnings";


############################################################################
# Now, exercise the constructor more thoroughly
############################################################################

{
    # We define a package to suppress warnings we don't care about.
    package BOGUS;
    sub is_open {}
    sub unlock {}

    package main;

    # Simple constructor call, all defaults
    lives_ok { $cache = new Email::Fingerprint::Cache } "Default constructor";

    # Construction with an invalid backend should fail
    throws_ok { $cache = new Email::Fingerprint::Cache({ backend => 'BOGUS' }) }
        qr{Can't load},
        "Constructing an object with an invalid backend";
}

############################################################################
# Now exercise the file() method, which supports several cases for a
# generality of backends.
############################################################################

# Default backend, default filename
$cache = new Email::Fingerprint::Cache({ backend => undef });

# Backend with file() method
{
    package Backend1;
    sub new { my $scalar; return bless \$scalar, "Backend1"; }
    sub unlock {}
    sub is_open {0}

    package main;
    $cache = new Email::Fingerprint::Cache({ backend => "Backend1" });

    ok $cache, "Cache using locally defined class as backend";
}

# Backend with AUTOLOAD method supplying a filename
{
    package Backend2;
    sub new { my $scalar; return bless \$scalar, "Backend2"; }
    sub AUTOLOAD { return "foo" }
    sub unlock {}
    sub is_open {0}

    package main;
    $cache = new Email::Fingerprint::Cache({ backend => "Backend2" });

    ok $cache, "Another cache using locally defined class as backend";
}

# Constructor returns undef
{
    package Backend8;
    sub new  {}
    sub unlock {}
    sub is_open {0}

    package main;

    # Construction should fail
    throws_ok
        { $cache = new Email::Fingerprint::Cache({ backend => 'Backend8' }) }
        qr{Can't load},
        "Dies when constructor returns undef";
}

# Clean up a little
undef $cache;


############################################################################
# Exercise the lock() and unlock() methods
############################################################################

my $cache1 = new Email::Fingerprint::Cache({ file => $file });
ok $cache1,       "Cache 1 for lock test";

my $cache2 = new Email::Fingerprint::Cache({ file => $file });
ok $cache2, "Cache 2 for lock test";

# Locking cache 1 should prevent locking cache2
ok $cache1->lock   ? 1 : 0, "Locked cache 1";
ok $cache2->lock   ? 0 : 1, "Failed to lock cache 2";
ok $cache1->unlock ? 1 : 0, "Unlocked cache 1";
ok $cache2->lock   ? 1 : 0, "Locked cache 2";
ok $cache2->unlock ? 1 : 0, "Unlocked cache 2";

# Destroy the caches
undef $cache1;
undef $cache2;

# Note: we should also test blocking locks, but that requires a
# fork(), so I've lazily put it off for a different test.


############################################################################
# Test the ugly failsafe in the DESTROY() method
############################################################################

$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# Open and lock the cache.
ok $cache,       "New cache for the slaughter";
ok $cache->open, "Opened cache";
ok $cache->lock, "Locked cache";

warning_like
    { undef $cache }
    { carped => qr/before it was close/},
    "Warns on bad destroy";

# Create another one
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# This time, we open but don't lock the cache.
ok $cache,       "New cache for the slaughter";
ok $cache->open, "Reopened cache";

warning_like
    { undef $cache }
    { carped => qr/before it was close/},
    "Warns on bad destroy";

# Create another one
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# This time, we lock but don't open the cache.
ok $cache,       "New cache for the slaughter";
ok $cache->lock, "Reopened cache";

warning_is { undef $cache } undef, "Destroyed without warnings";


############################################################################
# Exercise purge() more thoroughly
############################################################################

%fingerprints = ();

$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => \%fingerprints,
    ttl  => 60,
});

# Open the cache.
ok $cache,       "New cache for TTL test";
ok $cache->open, "Opened cache";
is scalar keys %fingerprints, 0, "Cache initially empty";

# Populate the cache with 500 items each: less than 60 seconds old;
# between 60 and 120 seconds old; older than 120 seconds.
for my $n ( 1..500 ) {
    my $timestamp = time;
    my $key       = sprintf "%03i", $n;

    $fingerprints{"a$key"} = $timestamp - int(rand(59));
    $fingerprints{"b$key"} = $timestamp - int(rand(59)) -  61;
    $fingerprints{"c$key"} = $timestamp - int(rand(59)) - 121;
}

# Add a fingerprint with no defined timestamp, or a timestamp
# that evaluates to false.
$fingerprints{101} = undef;
$fingerprints{102} = 0;
$fingerprints{103} = '';

# Now confirm that they're there
is scalar keys %fingerprints, 1503, "Added fingerprints OK";

# Next, purge items older than 2 minutes, and check. The "false"
# fingerprints should also be gone.
$cache->purge( ttl => 120 );
is scalar keys %fingerprints, 1000, "First purge OK";

# Then purge using the default TTL, which we set earlier to 60.
# Confirm that the default TTL is used and not, e.g., 120.
$cache->purge;
is scalar keys %fingerprints, 500, "Second purge OK";

# Purge using a TTL of -1, which should remove everything
$cache->purge( ttl => -1 );
is scalar keys %fingerprints, 0, "Final purge OK";

# And finally, add one entry that WON'T be purged.
$fingerprints{1} = time;

# Try to purge it anyway
$cache->purge( ttl => 0 );
is scalar keys %fingerprints, 1, "Preserved same-second fingerprint";
delete $fingerprints{1};

# Clean up
lives_ok { $cache->close } "Closed cache without incident";
warning_is { undef $cache } undef, "Destroyed without warnings";


############################################################################
# Test the dump() method, which prints to STDOUT
############################################################################

$file = 't/data/cache';
my %hash;
our $data;

# Read the data, stored in Perl format: loads hashref $data
require "$file.pl";

$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => \%hash,
});

# Open the cache file
ok $cache->open, "Opened cache file successfully";

# Add our data to the hash
$hash{$_} = $data->{$_} for keys %$data;

# Close and reopen
ok $cache->close, "Closed cache";
ok $cache->open, "Cache reopened";

my $output;

# Dump the cache, catching the output
tie *STDOUT, 'Test::Stdout', \$output;
$cache->dump;
untie *STDOUT;

# Read the test data
open IN, '<', "$file.txt";
my $standard = join '', <IN>;
close IN;

# Compare
is $output, $standard, "Cache dumped correctly";

# Clean up
lives_ok { $cache->close } "Closed cache without incident";
warning_is { undef $cache } undef, "Destroyed without warnings";

############################################################################
# Test the set_file method, which only works when no file is open.
############################################################################

# Get a fresh cache
$cache = new Email::Fingerprint::Cache({
    file => $file,
    hash => {},
});

# Nothing should happen, either, if the file is locked
$cache->lock;
is $cache->set_file('foo'), undef, "Cache is locked";
$cache->unlock;

# Nothing should happen, either, if the file is locked
$cache->open;
is $cache->set_file('foo'), undef, "Cache is open";
$cache->close;

# Finally, the file is closed and unlocked, so it should work
ok $cache->set_file('foo'), "Changing the file name";
