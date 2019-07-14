package SqlBatch::Application;

use v5.16;
use strict;
use warnings;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use SqlBatch::Configuration;
use SqlBatch::PlanTagFilter;
use SqlBatch::PlanReader;

sub new {
    my ($class, $argv, %opt)=@_;

    my $configfile;
    my $directory=".";
    my $configfile;
    my $datasource;
    my $username;
    my $password;
    my $dryrun;
    my $tags;
    my $from_file;
    my $to_file;
    my $exclude_files;

    GetOptionsFromArray (
	$argv,
	"configfile:s"      => \$configfile,
	"directory:s"       => \$directory,
	"datasource:s"      => \$datasource,
	"username:s"        => \$username,
	"password:s"        => \$password,
	"dryrun"            => \$dryrun,
	"tags:s"            => \$tags,
	"from_file:s"       => \$from_file,
	"to_file:s"         => \$to_file,
	"exclude_files:s"   => \$exclude_files,	    
	) if (defined $argv);

    my @tags          = split /,/ $tags;
    my @exclude_files = split /,/ $exclude_files;

    my $config = DatabaseUtillity::Configuration(
	$configfile,
	datasource       => $datasource,
	username         => $username,
	password         => $password,
	directory        => $directory,
	dryrun           => $dry_run,
	tags_only        => \@tags_only // [],
	from_file        => $from_file,
	to_files         => $to_file,
	exclude_files    => \@excldue_files // [],
	);
    $config->load;

    my $self   = {
	config => $config,
    };

    return bless $self, $class;
}

sub config {
    my $self = shift;

    return $self->{config};
}

sub run {
    my $self = shift;

    my $config = $self->config();
    my $dir    = $config->item('directory');
    my $filter = DatabaseUtillity::PlanTagFilter->new(@{$config->item('tags')});    
    my $reader = DatabaseUtillity::PlanReader->new(
	$dir,
	$filter,
	$config->items_hash(),
	);

    my $plan   = $reader->gross_execution_plan());
}

1;

