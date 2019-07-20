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
use SqlBatch::Plan;

sub new {
    my ($class, @argv)=@_;

    my $configfile;
    my $directory     = ".";
    my $datasource;
    my $username;
    my $password;
#    my $dryrun;
    my $tags          = "";
    my $from_file;
    my $to_file;
    my $exclude_files;
    my $fileextension = "sb";
    my $verbosity     = 0;

    GetOptionsFromArray (
	\@argv,
	"configfile:s"      => \$configfile,
	"directory:s"       => \$directory,
	"datasource:s"      => \$datasource,
	"username:s"        => \$username,
	"password:s"        => \$password,
#	"dryrun"            => \$dryrun,
	"tags:s"            => \$tags,
	"from_file:s"       => \$from_file,
	"to_file:s"         => \$to_file,
	"exclude_files:s"   => \$exclude_files,	    
	"fileextension:s"   => \$fileextension,	    
	"verbosity:i"       => \$verbosity,
# Future features
#	"from_id:s"         => \$from_id,
#	"to_id:s"           => \$to_id,
	) if (scalar(@argv));

    my @tags          = split /,/,$tags;
    my @exclude_files = split /,/,$exclude_files;

    my $config = SqlBatch::Configuration(
	$configfile,
	datasource       => $datasource,
	username         => $username,
	password         => $password,
	directory        => $directory,
#	dryrun           => $dry_run,
	tags             => \@tags // [],
	from_file        => $from_file,
	to_files         => $to_file,
	exclude_files    => \@exclude_files // [],
	fileextension    => $fileextension,
	verbosity        => $verbosity,
	);
    $config->load;

    my $self   = {
	config => $config,
    };

    return bless $self, $class;
}

sub config {
    my $self = shift;
    my $new  = shift;
    
    $self->{config} = $new 
	if defined $new;

    return $self->{config};
}

sub run {
    my $self = shift;

    my $config = $self->config();
    my $dir    = $config->item('directory');
    my $plan   = SqlBatch::Plan->new($config);
    my $filter = SqlBatch::PlanTagFilter->new(@{$config->item('tags')});    
    $plan->add_filter($filter);
    my $reader = SqlBatch::PlanReader->new(
	$dir,
	$plan,
	$config,
	);

    $plan->run();
}

1;

