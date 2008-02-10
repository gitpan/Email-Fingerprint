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

# Undefine the filename and verify that methods do nothing
$cache->set_file(undef);

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

chmod(0, $_) for glob "$file*";
is $cache->open, undef, "Can't open file";

unlink "t/data/out.tmp";
unlink $_ for glob "$file*";
}
