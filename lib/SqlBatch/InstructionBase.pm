package SqlBatch::InstructionBase;

# ABSTRACT: Base class for an instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;

sub new {
    my ($class,$config,$content,%args)=@_;

    my $self = {
	_configuration => $config,
	arguments      => \%args,
	content        => $content,
	runstate       => {},
   };

    $self = bless $self, $class;
    return $self;    
}

sub show_warning {
    my $self = shift;
    my $text = shift;

    say STDERR "WARNING: $text";
}

sub show_error {
    my $self = shift;
    my $text = shift;

    say STDERR "ERROR: $text";
}

sub run_if_tags {
    my $self = shift;

    return %{$self->{arguments}->{run_if_tags} // {}}
}

sub run_not_if_tags {
    my $self = shift;

    return %{$self->{arguments}->{run_not_if_tags} // {}}
}

sub state_dump {
    my $self = shift;

    my @public_keys = map { ! /^_/} keys %$self;
    my %public      = map { $_ => $self->{$_}} @public_keys;

    return \%public;  
}

sub configuration {
    my $self = shift;
    return $self->{_configuration};
}

sub argument {
    my $self = shift;
    my $name = shift;
    return $self->{arguments}->{$name};
}

sub address {
    my $self = shift;
    my $new = shift;
    if (defined $new) {
	$self->{address} = $new;
    }
    return $self->{address};
}

sub content {
    my $self = shift;
    return $self->{content};
}

sub runstate {
    my $self = shift;
    my $new  = shift;

    if (defined $new) {
	$self->{runstate} = $new;
    } 
    
    return $self->{runstate};
}

sub databasehandle {
    my $self = shift;
    my $new  = shift;

    if (defined $new) {
	$self->{_databasehandle} = $new;
    } 

    return $self->{_databasehandle};
}

sub run {
    croak("Abstract methode");
}

1;
