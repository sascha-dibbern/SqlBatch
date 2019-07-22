package SqlBatch::AbstractPlan;

# ABSTRACT: Abstract class for a plan object 

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;

sub new {
    my ($class,$config,%defaults)=@_;

    my $self = \%defaults;

    return bless $self, $class;
}

sub add_instructions {
    my $self = shift;

    croak "Abstract methode";
}

1;
