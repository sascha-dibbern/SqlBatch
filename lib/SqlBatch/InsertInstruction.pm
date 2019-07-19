package SqlBatch::InsertInstruction;

# ABSTRACT: Class for an SQL-insert instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use parent 'SqlBatch::InstructionBase';
use Data::Dumper;

sub new {
    my ($class,$config,$content,$sth_placeholder,%args) = @_;

    my $self = SqlBatch::InstructionBase->new($config,$content,%args);

    $self = bless $self, $class;
    $self->{_sth_placeholder} = $sth_placeholder;

    return $self;    
}

sub run {
    my $self = shift;

    my $field_values = $self->content;
    my @fields       = sort keys %$field_values;
    my $sth_ph       = $self->{_sth_placeholder};
    my $sth          = ${$sth_ph};

    unless (defined $sth) {
	my $table = $self->arguments('table');
	my $sql   = sprintf(
	    "insert into %s (%s) values (%s)",
	    $table, 
	    join(",", @fields), 
	    join(",", ("?")x@fields)
	    );

	$sth       = $self->databasehandle->prepare($sql);	    
	${$sth_ph} = $sth;
    }

    my @values = @{$field_values}{@fields};
    eval {
	my $rv = $sth->execute(@values);
	$self->runstate(_returnvalue=>$rv);
    };
    if ($@) {
	$self->runstate(_error=>$@);
	self->show_error("Failed running instruction: ".Dumper($self));
	croak($@);
    }
}

1;
