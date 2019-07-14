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
    
    if ($self->{no_tags_defined}) {
	my @run_if_tags = keys %{$instruction->{run_if_tags}};
	if (scalar(@run_if_tags) == 0) {
	    return 1;
	} else { 
	    return 0; 
	}

	my @run_if_not_tags = keys %{$instruction->{run_if_not_tags}};
	if (scalar(@run_if_not_tags)) {
	    return 1;
	} else {
	    return 0;
	}
    }

    for my $tag (@{$self->{tags}}) {
	if ($instruction->{run_if_not_tags}->{$tag}) {
	    return 0;
	}
    }

    for my $tag (@{$self->{tags}}) {
	if ($instruction->{run_if_tags}->{$tag}) {
	    return 1;
	}
    }

    return 1;
}

1;
