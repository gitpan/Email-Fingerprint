#!/usr/bin/perl
#
# Try to break Email::Fingerprint using bad inputs, etc.

use strict;
use warnings;
use Email::Fingerprint;

use Test::More;
use Test::Exception;

my $fp = new Email::Fingerprint;

# Try checksumming... NOTHING!
dies_ok { $fp->checksum } "Checksum with no email message";

# Setters shouldn't even exist for these puppies
ok not $fp->can('set_header');
ok not $fp->can('set_body' );
ok not $fp->can('set_input' );

# Try calling various private methods
dies_ok { $fp->_extract_headers } "Can't call _extract_headers";
dies_ok { $fp->_extract_body } "Can't call _extract_body";
dies_ok { $fp->_concat } "Can't call _concat";

# That's all, folks!
done_testing();
