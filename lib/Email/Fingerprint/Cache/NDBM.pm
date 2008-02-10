package Email::Fingerprint::Cache::NDBM;
use Class::Std;

use warnings;
use strict;

use Fcntl;
use Fcntl ":flock";
use FileHandle;
use NDBM_File;
use Carp qw(cluck);

=head1 NAME

Email::Fingerprint::Cache::NDBM - NDBM backend for Email::Fingerprint::Cache

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Email::Fingerprint::Cache;

    my $foo = Email::Fingerprint::Cache->new({
        backend => 'NDBM',
    });
    ...

You never want to use this class directly; you always want to access it
through Email::Fingerpint::Cache.

=head1 ATTRIBUTES

=cut

my %file :ATTR( :init_arg<file>, :set<file> ) = ();
my %hash :ATTR( :init_arg<hash> )             = ();
my %lock :ATTR                                = ();

=head1 FUNCTIONS

=head2 new

  $cache = new Email::Fingerprint::Cache::NDBM({
    file => $filename,  # Mandatory
  });

Method created automatically by C<Class::Std>.

=head2 BUILD

Internal helper method; never called directly by users.

=cut

sub BUILD {
    my ( $self, $ident, $args ) = @_;
}

=head2 open

    $cache->open or die;

Open the associated file, and tie it to our hash. This method does not
lock the file, nor unlock it on failure. See C<lock> and C<unlock>.

=cut

sub open {
    my $self = shift;

    my $file = $file{ ident $self } || '';
    return unless $file;

    my $hash = $self->get_hash;

    tie %$hash, 'NDBM_File', $file, O_CREAT|O_RDWR, oct(600);

    if ( not $self->is_open ) {
        cluck "Couldn't open $file";
        return;
    }

    1;
}

=head2 close

Unties the hash, which causes the underlying DB file to be written and
closed.

=cut

sub close {
    my $self = shift;

    return unless $self->is_open;

    untie %{ $self->get_hash };
}

=head2 is_open

Returns true if the cache is open; false otherwise.

=cut

sub is_open {
    my $self = shift;
    my $hash = $self->get_hash;

    return 0 unless defined $hash and ref $hash eq 'HASH';
    return 0 unless tied %{ $hash };
    return 1;
}

=head2 is_locked

Returns true if the cache is locked; false otherwise.

=cut

sub is_locked {
    my $self = shift;
    return defined $lock{ ident $self } ? 1 : 0;
}

=head2 lock

  $cache->lock or die;                  # returns immediately
  $cache->lock( block => 1 ) or die;    # Waits for a lock

Lock the DB file. Returns false on failure, true on success.

=cut

sub lock {
    my $self = shift;
    my %opts = @_;

    return 1 if exists $lock{ ident $self };    # Success if already locked

    return unless exists $file{ ident $self };  # Can't lock nothing!
    my $file = $file{ ident $self };

    # Flags for the correct locking mode
    my $flags  = LOCK_EX;
    $flags    |= LOCK_NB unless $opts{block};

    my $FH = new FileHandle;

    # Open a file handle
    $FH->open(">> $file.lock") or return;
    flock($FH, $flags) or return;

    # Remember the lock
    $lock{ ident $self } = $FH;

    1;
}

=head2 unlock

  $cache->unlock or cluck "Unlock failed";

Unlocks the DB file. Returns false on failure, true on success.

=cut

sub unlock {
    my $self = shift;
    my $FH   = delete $lock{ ident $self } or return 1; # Success if no lock

    flock($FH, LOCK_UN) or return;
    $FH->close or return;

    unlink $file{ ident $self } . ".lock" or return;

    1;
}

=head1 PRIVATE METHODS

=head2 get_hash

Returns a reference to the hash which is tied to the backend storage.

=cut

sub get_hash : PRIVATE {
    my $self = shift;
    return $hash{ ident $self };
}

=head1 AUTHOR

Len Budney, C<< <lbudney at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-fingerprint at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Fingerprint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Fingerprint::Cache::NDBM

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Fingerprint>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Fingerprint>

=back

=head1 ACKNOWLEDGEMENTS

Email::Fingerprint::Cache is based on caching code in the
C<eliminate_dups> script by Peter Samuel and available at
L<http://www.qmail.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Len Budney, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
