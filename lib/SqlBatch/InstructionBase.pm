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
	args           => \%args,
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

sub state_dump {
    my $self = shift;

    my @public_keys = map { ! /^_/} keys %$self;
    my %public      = map { $_ => $self->{$_}} @public_keys;

    return \%public;  
}

sub config {
    my $self = shift;
    return $self->{_configuration};
}

sub argument {
    my $self = shift;
    my $name = shift;
    return $self->{arguments}->{$name};
}

sub content {
    my $self = shift;
    return $self->{content};
}

sub runstate {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    if (defined $key) {
	%{$self->{runstate}} = (%{$self->{runstate}}, $key => $value);
    } 
    
    return %{$self->{runstate}};
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
