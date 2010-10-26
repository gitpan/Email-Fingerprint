#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Trap;

use_ok "Email::Fingerprint::App::EliminateDups";

my $app;
ok $app = Email::Fingerprint::App::EliminateDups->new, "Constructor succeeds";

# Force the package to expose its privates
my ($process_options, $exit_retry);
{
    package Email::Fingerprint::App::EliminateDups;

    $process_options = sub { $app->_process_options(@_) };
    $exit_retry      = sub { $app->_exit_retry(@_) };
}

# Exit-status check
trap { $exit_retry->("test message") };
is $trap->exit, 111, "Exit status 111";
like $trap->stderr, qr/test message/, "Warning message";

# Two ways to get help messages
for my $option (qw{ --help --bogus }) {
    trap { $process_options->($option) };
    is $trap->exit, 111, "Exit status 111 for $option";
    like $trap->stderr, qr/usage:/, "Usage message for $option";
}

# Try once with valid args; these options will persist.
ok ! $process_options->('--no-purge', '--no-check'), "Valid options";

# Create a default cache file
open F, ">", ".maildups.db";
close F;

# Try reading a cache with no permission
chmod 0, ".maildups.db";
trap { $app->open_cache };
is $trap->exit, 111, "Cache with no permission";
like $trap->stderr, qr/permission denied/i, "Correct error message";
unlink ".maildups.db"; # So it will get recreated with default perms

# Try dumping the cache contents, which are empty
is $app->dump_cache, undef, "Unrequested dump is no-op";
$process_options->('--dump');
trap { $app->dump_cache };
ok ! $trap->exit, "Dumped cache";
is $trap->stderr, '', "No errors or warnings";
is $trap->stdout, '', "No output (empty cache)";

# Basic calls
ok $app->open_cache, "Opened default cache";
ok $app->open_cache, "Redundant attempt to open cache";
ok $app->close_cache, "Closed default cache";
ok $app->close_cache, "Closing a second time";

# Purging the empty cache
$process_options->('--no-purge');
ok ! $app->purge_cache, "Unrequested cache purge";
$process_options->();
$app->open_cache();
ok $app->purge_cache, "Purging empty cache";

# Basic fingerprint calls
$process_options->('--no-check');
ok ! $app->check_fingerprint, "Unrequested fingerprint check";

# Create empty cache
$process_options->('t/data/cache');
$app->open_cache;
$app->close_cache;

# Use test emails
for my $n (1..6) {
    # Open the test email
    open EMAIL, "<", "t/data/$n.txt";
    local *STDIN = *EMAIL;

    # Check its fingerprint
    trap { $app->run("t/data/cache") };
    ok ! $trap->exit, "First copy of message $n accepted";
    is $trap->stderr, '', "No error messages";
    is $trap->stdout, '', "No output";

    # "Reopen" the email
    seek EMAIL, 0, 0;

    # Check again
    trap { $app->run("t/data/cache") };
    is $trap->exit, 99, "Second copy of message $n rejected";
    is $trap->stderr, '', "No error messages";
    is $trap->stdout, '', "No output";
}

# Clean up a little
unlink ".maildups.db";
unlink "t/data/cache.db";
