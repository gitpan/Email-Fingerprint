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

my $backend = $cache->get_backend;

# Undefine the filename and verify that methods do nothing
$cache->set_file(undef);

ok !defined $cache->open, "Can't open undefined file";
ok !defined $cache->close, "Can't close file that isn't open";
ok !defined $backend->lock, "Can't lock undefined file";

# Try opening a file under adverse conditions
my $file = "t/data/tmp_cache";

ok $cache->set_file($file), "Set new cache file";
ok $cache->open, "Opened file";
ok $backend->is_open, "Cache is open";
ok $cache->close, "Closed file";
ok ! $backend->is_open, "Cache is closed";
ok $cache->lock( block => 1 ), "Locked cache with blocking";
ok $cache->lock( block => 1 ), "Locked cache a second time";
ok $backend->is_locked == 1, "Cache is locked";
ok $cache->unlock, "Unlocked cache";
ok $backend->is_locked == 0, "Cache is unlocked";
ok $cache->unlock, "Unlocking again silently succeeds";

# Turn off access permissions
{
open NULL, ">", "t/data/out.tmp";
local(*STDERR) = *NULL;

chmod(0, $_) for glob "$file*";
ok !defined $cache->open, "Can't open file";
ok $cache->lock, "Can still lock file, though";
ok $cache->unlock, "Can unlock as well";

unlink "t/data/out.tmp";
unlink $_ for glob "$file*";
}
