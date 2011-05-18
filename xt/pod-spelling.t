#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Spelling;

set_spell_cmd('aspell list');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
ACKNOWLEDGEMENTS
AnnoCPAN
Budney
CGI
CPAN
Dolan
GPL
STDIN
STDOUT
TTL
UTC
backend
checksum
crontab
dups
filename
maildir
munge
qmail
qmail's
readably
timestamp
