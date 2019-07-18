package SqlBatch::SqlInstruction;

# ABSTRACT: Base class for an unspecific SQL-instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use parent 'SqlBatch::InstructionBase';
use Data::Dumper;

sub new {
    my ($class,$config,%args) = @_;

    my $self = SqlBatch::InstructionBase->new($config,%args);

    $self = bless $self, $class;
    return $self;    
}

sub run {
    my $self = shift;

    my $sql = $self->content;

    eval {
	my $rv = $self->databasehandle->do($sql);
	$self->runstate(_returnvalue=>$rv);
    };
    if($@) {
	$self->runstate(_error=>$@);
	self->show_error("Failed running instruction: ".Dumper($self->state_dump));
	croak($@);
    }
}

1;
