package SqlBatch::PlanTagFilter;

# ABSTRACT: Class to filter out instructions according to their matching against given tags

use v5.16;
use strict;
use warnings;

use Carp;
use Data::Dumper;

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

#    say Dumper($self->{tags});
    my %run_if_tags     = $instruction->run_if_tags;
    my %run_not_if_tags = $instruction->run_not_if_tags;

#    say Dumper(\%run_if_tags);
#    say Dumper(\%run_not_if_tags);

    if ($self->{no_tags_defined}) {
	my @run_if_tags = keys %run_if_tags;
	if (scalar(@run_if_tags) == 0) {
#   say "#1";
	    return 1;
	} else { 
#   say "#2";
	    return 0; 
	}

	# check for %run_not_if_tags is not relevant => always match to run
	return 1;
    }

    # Not running in case of certain tags is prioritized 
    for my $tag (@{$self->{tags}}) {
# say "#a# $tag";
	if ($run_not_if_tags{$tag}) {
#   say "#3";
	    return 0;
	}
    }

    for my $tag (@{$self->{tags}}) {
# say "#b# $tag";
	if ($run_if_tags{$tag}) {
#   say "#4";
	    return 1;
	}
    }

    # Default is not to run
#   say "#5";
    return 0;
}

1;
