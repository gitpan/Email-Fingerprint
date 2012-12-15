#!/usr/bin/perl
# Test the AnyDBM cache backend

use strict;
use warnings;
use English;

use Test::More;
use Test::Exception;

use File::Path 2.0 qw( remove_tree );

use_ok "Email::Fingerprint::Cache";
use_ok "Email::Fingerprint::Cache::AnyDBM";

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
my $tmp  = "t/data/tmp";
my $file = "$tmp/tmp_cache";
mkdir $tmp;

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
SKIP: {
    if ($EUID == 0)
    {
        diag <<"EOF";


        ***************************************************************************
                                YOU ARE RUNNING TESTS AS ROOT!

         You REALLY should not do that. Certain tests are skipped when you run as
         root, so you're not getting the full experience. Besides, what if I go
         haywire? I could reformat your disks, snoop your emails and kidnap your
         pets! Did you ever think of that? Yeah, running me as root was probably
         not the best idea you've ever had.
        ***************************************************************************

EOF

        skip "Can't test permissions when running as root", 3 if $EUID == 0;
    }

    # Redirect error messages to a temporary file
    open NULL, ">", "$tmp/out.tmp";
    local(*STDERR) = *NULL;

    # Disable permissions for ALL temporary files
    chmod(0, $_) for glob("$tmp/*");

    # Confirm that we can't open chmod 0 files. Sigh.
    if (open TEST, "<", "$tmp/out.tmp")
    {
        diag <<"EOF";


        ***************************************************************************
                        YOUR SYSTEM HAS BROKEN FILE PERMISSIONS!

         Either your operating system, or your Perl installation, is broken: I
         can read files with UNIX permissions set to 0. You're probably running
         this on Windows and/or as an administrative user, in which case I should
         reformat your hard drive just to teach you a lesson, but I won't.

         This module will probably work fine for you anyway, but I make no
         guarantees. If your system doesn't handle file permissions sanely,
         what else might it do that it shouldn't?
        ***************************************************************************

EOF

        close TEST;
        skip "Can't test permissions--your system or perl is broken", 3;
    }

    # Confirm that the file can't be opened
    ok !defined $cache->open, "Can't open file";
    ok $cache->lock, "Can still lock file, though";
    ok $cache->unlock, "Can unlock as well";
}

# Clean up
remove_tree($tmp);

# That's all, folks!
done_testing();
