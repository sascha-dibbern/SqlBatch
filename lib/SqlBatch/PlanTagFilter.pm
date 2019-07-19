package SqlBatch::PlanTagFilter;

use v5.16;
use strict;
use warnings;

use Carp;

sub new {
    my ($class, @tags)=@_;

    my $self = {
	no_tags_defined => ! scalar(@tags),
	tags            => \@tags,
    };

    return bless $self, $class;
}

sub filter {
    my $self = shift;
    my $plan = shift;

    my @new_plan = grep { $self->is_allowed_instruction($_) } @$plan;
    
    return wantarray ? @new_plan : \@new_plan;
}

sub is_allowed_instruction {
    my $self        = shift;
    my $instruction = shift;
    
    my %run_if_tags     = $instruction->run_if_tags;
    my %run_if_not_tags = $instruction->run_if_not_tags;

    if ($self->{no_tags_defined}) {
	my @run_if_tags = keys %run_if_tags;
	if (scalar(@run_if_tags) == 0) {
	    return 1;
	} else { 
	    return 0; 
	}

	# check for %run_if_not_tags is not relevant => always match to run
	return 1;
    }

    # Not running in case of certain tags is prioritized 
    for my $tag (@{$self->{tags}}) {
	if ($run_if_not_tags{$tag}) {
	    return 0;
	}
    }

    for my $tag (@{$self->{tags}}) {
	if ($run_if_tags{$tag}) {
	    return 1;
	}
    }

    # Default is to run
    return 1;
}

1;
