package SqlBatch::RunState;

# ABSTRACT: Class for central runstate object

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;

sub new {
    my ($class,$copy_of)=@_;

    my $self;

    if (defined $copy_of) {
	# Replicate
	my %copy = map {
	    # Generate new has element
	    $_ => $copy_of->{$_}
	} grep { 
	    # Copy only public attributes => non-"_..."
	    ! /^_/ 
	} keys %$copy_of;

	$self = \%copy;
    } else {
	# Default
	$self = {
	    autocommit => 1 ,
	};
    }

    return bless $self, $class;
}

sub commit_mode {
    my $self = shift;

    if ($self->{autocommit}) {
	return 'autocommitted';
    } else {
	return 'nonautocommitted'; 
    }
}

sub AUTOLOAD {
    my $self = shift;

    my $new_value;
    my $has_new_values = scalar(@_);
    if ($has_new_values) {
	$new_value = shift;
    }

    our $AUTOLOAD; # keep 'use strict' happy
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;

    if ($has_new_values) {
	$self->{$attr} = $new_value;
    }

    return $self->{$attr};
}

1;
