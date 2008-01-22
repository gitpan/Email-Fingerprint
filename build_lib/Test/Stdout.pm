use strict;
use warnings;

package Test::Stdout;

sub TIEHANDLE
{
    my $class = shift;
    my $self = {};
    $self->{string} = shift;
    ${ $self->{string} } ||= '';

    return bless $self, $class;
}

sub PRINT
{
    my $self = shift;
    ${ $self->{string} } .= join '', @_;
}

sub PRINTF
{
    my $self = shift;
    my $format = shift;
    ${ $self->{string} } .= sprintf($format, @_);
}

1;
