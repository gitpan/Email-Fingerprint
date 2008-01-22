#!/usr/bin/perl
# Test the NDBM cache backend

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use_ok "Email::Fingerprint::Cache";
use_ok "Email::Fingerprint::Cache::NDBM";

my $cache;

# Test construction with no file name; the default filename will be used.
lives_ok {
    $cache = new Email::Fingerprint::Cache({
        file => undef,
    });
} "Constrution without filename";

ok $cache->get_file, "Default filename used";

# Undefine the filename and verify that methods do nothing
$cache->set_file(undef);

is $cache->get_file, undef, "Filename now undefined";
is $cache->open, undef, "Can't open undefined file";
is $cache->close, undef, "Can't close file that isn't open";

# Try opening a file under adverse conditions
my $file = "t/data/tmp_cache";

ok $cache->set_file($file), "Set new cache file";
ok $cache->open, "Opened file";
ok $cache->close, "Closed file";
ok $cache->lock( block => 1 ), "Locked cache with blocking";
ok $cache->lock( block => 1 ), "Locked cache a second time";
ok $cache->unlock, "Unlocked cache";

# Turn off access permissions
{
open NULL, ">", "t/data/out.tmp";
local(*STDERR) = *NULL;

ok chmod( 0, $cache->get_file ), "Turned off file permissions";
is $cache->open, undef, "Can't open file";
is $cache->lock, undef, "Can't lock file, either";

unlink "t/data/out.tmp";
unlink $cache->get_file;
}
