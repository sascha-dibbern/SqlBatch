package SqlBatch::Configuration;

# ABSTRACT: Configuration object

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use DBI;
use JSON::Parse 'json_file_to_perl';
use Data::Dumper;

sub new {
    my ($class, $config_file_path, %overrides)=@_;

    if (exists $overrides{database_attributes}) {
	croak "Override for 'database_attributes' must be an hash-ref" 
	    unless (ref($overrides{database_attributes}) eq 'HASH');
    }
       
    my $self = {
	config_file_path => $config_file_path,
	overrides        => \%overrides,
	requirements     => {
	    datasource          => 1,
	    username            => 1,
	    password            => 1,
	},
    };

    $self = bless $self, $class;

    $self->load if defined $config_file_path;
    $self->validate;

    return $self;    
}

sub load {
    my $self = shift;

    my $path = $self->{config_file_path};

    unless (ref($path)) {
	croak "Configuration file '$path' not found" 
	    unless -e $path;
    }

    $self->{loaded} = json_file_to_perl($path);
}

sub requirement_assertion {
    my $self = shift;
    my $id   = shift;

    for my $item_id (keys %{$self->{requirements}}) {
	if ($self->{requirements}->{$item_id}) {
	    croak "Configuration item '$item_id' is not defined" 
		unless defined $self->item($item_id);
	}
    }    
}

sub validate {
    my $self = shift;
    my %h     = $self->items_hash();
    my @hkeys = keys %h;
    map {$self->requirement_assertion($_) } @hkeys;
}

sub verbosity {
    my $self = shift;
    return $self->item('verbosity') // 0;
}

sub item {
    my $self = shift;
    my $name = shift;

    return $self->{overrides}->{$name} if exists $self->{overrides}->{$name};

    return $self->{loaded}->{$name} if exists $self->{loaded}->{$name};

    return undef;
}

sub items_hash {
    my $self = shift;
    
    return (%{$self->{loaded}},%{$self->{overrides}})
}

sub database_handles {
    my $self = shift;

    my $dbhs = $self->{database_handles};

    unless (defined $dbhs) {
	my $data_source = $self->item('datasource');
	my $username    = $self->item('username');
	my $password    = $self->item('password');
	my $attributes  = $self->item('database_attributes') // {};

	my $dbh_ac = DBI->connect(
	    $data_source, $username, $password, 
	    { %$attributes, RaiseError => 1, AutoCommit => 1 }
	    ) or croak $DBI::errstr;

	my $dbh_nac;
	if ($self->item('force_autocommit')) {
	    # Hack for DBI:RAM and other untransactional databases
	    $dbh_nac=$dbh_ac;
	} else {
	    $dbh_nac= DBI->connect(
		$data_source, $username, $password, 
		{ %$attributes, RaiseError => 1, AutoCommit => 0 }
		) or croak $DBI::errstr;
	}

	$dbhs = {
	    autocommitted    => $dbh_ac,
	    nonautocommitted => $dbh_nac,
	};

	$self->{database_handles} = $dbhs;

	my $init_sql = $self->{init_sql} // [];
	
	for my $statement (@$init_sql) {
	    my $rv = $dbhs->{autocommitted}->do($statement);	    
	}
    }
    
    return $dbhs;
}

sub DESTROY {
    my $self = shift;

    my $dbh = $self->{database_handle};

    $dbh->disconnect
	if defined $dbh;
}

1;
