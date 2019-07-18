package SqlBatch::RollbackInstruction;

# ABSTRACT: Base class for an SQL transaction-rollback instruction

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

    my $force_autocommit = $self->configuration->item('force_autocommit');

    if ($force_autocommit) {
	$self->show_warning("Explicit rollback of a transaction is not enforced due to 'force_autocommit' in configuration");
    } else {
	eval {
	    my $rv = $self->databasehandle->rollback;
	    $self->runstate(_returnvalue => $rv);
	};
	if($@) {
	    $self->runstate(_error => $@);
	    self->show_error("Failed running instruction: ".Dumper($self->state_dump));
	    croak($@);
	}
	$self->runstate(autocommit => 1);
    }

}

1;

