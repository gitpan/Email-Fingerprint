#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Trap;

use File::Path 2.0 qw( remove_tree );

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
ok $trap->exit == 111, "Exit status 111";
like $trap->stderr, qr/test message/, "Warning message";

# Two ways to get help messages
for my $option (qw{ --help --bogus }) {
    trap { $process_options->($option) };
    ok $trap->exit == 111, "Exit status 111 for $option";
    like $trap->stderr, qr/usage:/, "Usage message for $option";
}

# Try once with valid args; these options will persist.
ok ! $process_options->('--no-purge', '--no-check'), "Valid options";

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

# Point cache at temp directory now
my $tmp = "t/tmp";
$process_options->("$tmp/cache");

# Create empty cache
remove_tree($tmp);
mkdir $tmp;
$app->open_cache;
$app->close_cache;

# Cache fingerprints for test emails
for my $n (1..6) {
    # Open the test email
    open EMAIL, "<", "t/data/$n.txt";
    local *STDIN = *EMAIL;

    # Check its fingerprint
    trap { $app->run("$tmp/cache") };
    ok ! $trap->exit, "First copy of message $n accepted";
    ok $trap->stderr eq '', "No error messages";
    ok $trap->stdout eq '', "No output";

    # "Reopen" the email
    seek EMAIL, 0, 0;

    # Check again
    trap { $app->run("$tmp/cache") };
    ok $trap->exit == 99, "Second copy of message $n rejected";
    ok $trap->stderr eq '', "No error messages";
    ok $trap->stdout eq '', "No output";
}

# Take away permissions and then try reading cache
chmod 0, "$_" for glob "$tmp/*";
trap { $app->open_cache };
ok $trap->exit == 111, "Cache with no permission";
like $trap->stderr, qr/couldn't open/i, "Got error message (namely, a confusing one from tie)";

# Try dumping the cache contents, which are empty
ok !defined $app->dump_cache, "Unrequested dump is no-op";
$process_options->('--dump');
trap { $app->dump_cache };
ok ! $trap->exit, "Dumped cache";
ok $trap->stderr eq '', "No errors or warnings";
ok $trap->stdout eq '', "No output (empty cache)";

# Clean up a little
unlink "$_" for glob ".maildups*";
remove_tree($tmp);
