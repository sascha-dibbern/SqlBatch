package DatabaseUtillity::Configuration;

# ABSTRACT: Configuration object

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use DBI;
use JSON::Parse 'json_file_to_perl';

sub new {
    my ($class, $config_file_path, $requirements, %overrides)=@_;

    my $self = {
	config_file_path => $config_file_path,
	overrides        => \%overrides,
	requirements     => $requirements,
    };

    $self = bless $self, $class;

    $self->load if defined $config_file_path;
    $self->validate;

    return $self;    
}

sub load {
    my $self = shift;

    my $path=$self->{config_file_path};

    unless (ref($path)) {
	croak "Configuration file $path not found" 
	    unless -e $path;
    }

    $self->{loaded} = json_file_to_perl($path);

}

sub validate {
    my $self = shift;
    
    for my $requirement (@{$self->{requirements}}) {
	my $value = $self->item();
	croak "Configuration item '$requirement' is not defined" unless defined $value;
    }    
}

sub item {
    my $self = shift;
    my $name = shift;

    return $self->{overrides}->{$name} if exists $self->{overrides}->{$name};

    return $self->{loaded}->{$name} if exists $self->{loaded}->{$name};

    croak "Undefined configuration item: $name";
}

sub items_hash {
    my $self = shift;
    
    return (%{$self->{loaded}},%{$self->{overrides}})
}

sub database_handle {
    my $self = shift;

    my $dbh = $self->{database_handle};

    unless (defined $dbh) {
	my $data_source = $self->item(datasource);
	my $username    = $self->item(username);
	my $password    = $self->item(password);
	my $attributes  = $self->item(database_attributes) // {};

	$dbh = DBI->connect($data_source, $username, $password, $attributes)
	     or croak $DBI::errstr;
	$self->{database_handle} = $dbh;

	my $init_sql = $dbdef->{init_sql} // [];
	
	for my $statement (@$init_sql) {
	    my $rv = $dbh->do($statement);	    
	}
    }
    
    return $dbh;
}

sub DESTROY {
    my $self = shift;

    my $dbh = $self->{database_handle};

    $dbh->disconnect
	if defined $dbh;
}

1;
