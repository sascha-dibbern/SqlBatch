package SqlBatch::Plan;

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;

sub new {
    my ($class,$config)=@_;

    my $self = {
	configuration => $config,	
	filters       => [],
	instructions  => [],
	commit_mode   => 'autocommitted',
    };

    return bless $self, $class;
}

sub add_filter {
    my $self = shift;
    push @{$self->{filters}},shift;
}

sub add_instructions {
    my $self         = shift;
    my @instructions = @_;

    if (scalar(@{$self->{filters}})) {
	my @filtered = grep {
	    my $ok_sum = 0;
	    
	    for my $filter (@{$self->{filters}}) {
		$ok_sum += 1 
		    if $filter->is_allowed_instruction($_);
	    }

	    $ok_sum;
	} @instructions;

	push @{$self->{instructions}},@filtered;
    } else {
	push @{$self->{instructions}},@instructions;
    }
}

sub run {
    my $self = shift;

    for my $instruction (@{$self->{instructions}}) {
	$self->_run_instruction($instruction);
    }
}

sub current_dbh {
    my $self = shift;

    my $dbhs = $self->{configuration}->database_handles;
    my $mode = $self->{commit_mode};

    return $dbhs->{$mode};
}

sub warn {
    my $self        = shift;
    my $text        = shift;
    my $instruction = shift;

    say STDERR "WARNING: ".$text;
    say "Instruction: ".Dumper($instruction) if defined $instruction;
}

sub _run_instruction {
    my $self        = shift;
    my $instruction = shift;

    my $dbh = $self->current_dbh;
#    say "%%".Dumper($instruction);

    my $type    = $instruction->{type};
    my $force_autocommit = $self->{configuration}->item('force_autocommit');

    if ($type eq "SQL") {
	$self->_run_sql_instruction($dbh,$instruction);
    } elsif ($type eq "INSERT") {
	$self->_run_insert_instruction($dbh,$instruction);
    } elsif ($type eq "DELETE") {
	$self->_run_delete_instruction($dbh,$instruction);
    } elsif ($type eq "BEGIN") {	
	if ($force_autocommit) {
	    $self->warn("Explicit beginning of a transaction is not enforced due to 'force_autocommit' in configuration",$instruction);
	} else {
	    $self->{commit_mode} = 'nonautocommitted';
	    $dbh->begin_work;
	}
    } elsif ($type eq "COMMIT") {
	if ($force_autocommit) {
	    $self->warn("Explicit commiting of a transaction is not enforced due to 'force_autocommit' in configuration",$instruction);
	} else {
	    $dbh->commit;
	    $self->{commit_mode} = 'autocommitted';
	}
    } elsif ($type eq "ROLLBACK") {
	if ($force_autocommit) {
	    $self->warn("Explicit rollback of a transaction is not enforced due to 'force_autocommit' in configuration",$instruction);
	} else {
	    $dbh->rollback;
	    $self->{commit_mode} = 'autocommitted';
	}
    }

}

sub _run_sql_instruction {
    my $self        = shift;
    my $dbh         = shift;
    my $instruction = shift;

    $dbh->do($instruction->{sql});
}

sub _run_insert_instruction {
    my $self        = shift;
    my $dbh         = shift;
    my $instruction = shift;

    my $field_values = $instruction->{data};
    my @fields       = sort keys %$field_values;
    my $sth          = ${$instruction->{sth_placeholder}};

    unless (defined $sth) {
	my $table = $instruction->{table};
	my $sql   = sprintf(
	    "insert into %s (%s) values (%s)",
	    $table, 
	    join(",", @fields), 
	    join(",", ("?")x@fields)
	    );

	$sth = $dbh->prepare($sql);	    
	${$instruction->{sth_placeholder}} = $sth;
    }

    my @values = @{$field_values}{@fields};
    my $rv;
    eval {
	$rv = $sth->execute(@values);
    };
    if ($@) {
	say "Failed running instruction: ".Dumper($instruction);
	say "Error: $@";
	croak $@;
    }
}

sub _run_delete_instruction {
    my $self        = shift;
    my $dbh         = shift;
    my $instruction = shift;

    my $field_values = $instruction->{data};
    my @fields       = sort keys %$field_values;
    my $sth          = ${$instruction->{sth_placeholder}};

    unless (defined $sth) {
	my $table = $instruction->{table};
	my @constraints = map { "$_=?" } @fields;

	my $sql   = sprintf(
	    "delete from %s where %s",
	    $table,
	    join(' and ',@constraints)
	    );
	$sth = $dbh->prepare($sql);	    
	${$instruction->{sth_placeholder}} = $sth;
    }

    my @values = @{$field_values}{@fields};
    my $rv;
    eval {
	$rv = $sth->execute(@values);
    };
    if ($@) {
	say "Failed running instruction: "..Dumper($instruction);
	say "Error: $@";
	croak $@;
    }
}

1;
