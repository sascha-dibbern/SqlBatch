package SqlBatch::PlanReader;

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use Text::CSV_XS;

sub new {
    my ($class, $directory, $plan_filter, %opt)=@_;

    my $self = {
	%opt,
	plan_filter => $plan_filter,
 	directory   => $directory,
    };

    return bless $self, $class;
}

sub gross_execution_plan {
    my $self = shift;

    unless (defined $self->{gross_execution_plan}) {
	say "Loading gross plan";

	my @file_paths = $self->files;

	my @gross_plan;
	for my $current_file (@file_paths) {
	    $self->{current_file} = $current_file;
	    my $task_plan = $self->parse_tasks_file;
	    @gross_plan = (@gross_plan, @$task_plan);
	}
	
	$self->{gross_execution_plan} = \@gross_plan;
    }
    
    return wantarray ? @{$self->{gross_execution_plan}} : $self->{gross_execution_plan};
}

sub execution_plan {
    my $self = shift;

    my $gp = $self->gross_execution_plan();
    my $plan;
    if (defined $self->{plan_filter}) {
	$plan = $self->{plan_filter}->filter($gp);
    } else {
	$plan = $gp;
    }

    return wantarray ? @$plan : $plan;
}

sub files {
    my $self = shift;

    my @override= @_;
    if (scalar(@override)) {
	$self->{files} = \@override;
    }

    unless (defined $self->{files}) {
	my $from_file     = $self->{from_file};
	my $to_file       = $self->{to_file};
	my $exclude_files = $self->{exclude_files};
	my %exclusions    = map { $_ => 1 } @$exclude_files;
	my $dir           = $self->{directory};
	
	opendir(my $dh, $dir) || croak "Can't opendir $dir: $!";
	my @all_files = sort grep { -f "$dir/$_" } readdir($dh);
	closedir $dh;
	
	my $check_for_first = defined $from_file ? 0 : 1;
	my $check_for_last  = defined $to_file   ? 0 : 1;
	my $past_first = $check_for_first ? 0 : 1;
	
	my @files = grep {
	    my $file    = $_;
	    my $addfile;
	    if ($check_for_first) {
		$past_first = 1 if ($file eq $from_file);
		$addfile    = 1;
	    }
	    if ($past_first) {
		unless (defined $exclusions{$file}) {
		    $addfile = 1;
		}
	    }
	    if ($check_for_last) {
		$addfile = 0;
	    }
	    $addfile
	} @all_files;
	
	my @paths      = map { $self->{directory}.'/'.$_ } @files;
	$self->{files} = \@paths;
    }

    return wantarray ? @{$self->{files} } : $self->{files} ;
}

sub parse_tasks_file {
    my $self         = shift;
    my $current_file = shift // $self->{current_file};

    open(FH,"<",$current_file) || croak "File $current_file could not be openned";
    my @alllines = <FH>;
    close FH;

    # Remove comments
    my @lines = grep { ! /^#/ } @alllines;
    $self->{lines_to_parse} = \@lines;
    
    my %tags;
    my @sequence;

    while (scalar(@lines)) {
	my $line = shift @lines;
	my %instruction;

	if ($line =~ /^--SQL--/) {
	    my %args     = $self->_parse_section_args("--SQL--",$line);
	    %instruction = $self->_sql_instruction(%args);
	} elsif ($line =~ /^--INSERT--/) {
	    my %args     = $self->_parse_section_args("--INSERT--",$line);
	    %instruction = $self->_insert_csv_instruction(%args);
	} elsif ($line =~ /^--DELETE--/) {
	    my %args     = $self->_parse_section_args("--DELETE--",$line);
	    %instruction = $self->_delete_csv_instruction(%args);
	} else {
	    say "Ignored line with content: $line";
	    next;
	}

	$instruction{origin_file} = $current_file;
	push @sequence,\%instruction;

    }

    return wantarray ? @sequence : \@sequence;
}

sub _parse_section_args {
    my $self    = shift;
    my $section = shift;
    my $line    = shift;

    chomp $line;
    $line =~ /$section(.*)/;
    my $rest = $1;
    my @arg_strings = grep { ! $_ eq '' } split /\s/,$rest;

    my $id        = 'Undefined id';
    my $separator = ';';
    my $quote     = '"';
    my $end       = 'END';
    my $tags      = '';

    GetOptionsFromArray(
	\@arg_strings,
	'id:s',
	'separator:s',
	'quote:s',
	'end:s',
	'tags:s',
	);

    $end         = '--'.$end.'--';
    my @tags     = split /,/,$tags;
    my %pos_tags = map { $_ => 1 } grep { ! /^-/ } @tags;
    my %neg_tags = map { 
	my $tag = $_;
	$tag =~ s/^-//;
	$tag => 1 
    } grep { ! /^-/ } @tags;

    my %args = (
	id            => $id,
	separator     => $separator,
	quotes        => $quote,
	end           => $end,
	run_only_if_tags => \%pos_tags,
	run_not_if_tags  => \%neg_tags,
    );

    return %args;
}

sub _sql_instruction {
    my $self  = shift;
    my %args  = @_;

    my $lines = $self->{lines_to_parse};
    my @sqllines;
    while (my $line = shift @$lines) {
	say $line;
	last if ($line =~/^$args{end}/);

	# Add line to SQL-statement
	push @sqllines,$line;
    }

    return (
	%args,
	type => "SQL",
	sql  => join("\n",@sqllines),
    );    

}

sub _insert_csv_instruction {
    my $self  = shift;
    my %args  = @_;
    my $lines = $self->{lines_to_parse};

    return (
	%args,
	type  => "INSERT",
	items => $self->_parse_csv($lines,%args),
	);
}

sub _delete_csv_instruction {
    my $self  = shift;
    my %args  = @_;
    my $lines = $self->{lines_to_parse};

    return (
	%args,
	type  => "DELETE",
	items => $self->_parse_csv($lines,%args),
	);
}

sub _parse_csv {
    my $self  = shift;
    my $lines = shift;
    my %args  = @_;

    my $end = $args{end};
    my @csvlines;
    while (my $line = shift @$lines) {
	last if ($line =~/^$end/);

	# Add line to SQL-statement
	push @csvlines,$line;
    }

    my $string = join("",@csvlines);
    open my $fh, "<:encoding(utf8)", \$string;

    # Read/parse CSV    
    my $csv = Text::CSV_XS->new (
	{ 
	    sep => $args{separator},
	    quote => $args{quote},
	    binary => 1, 
	    auto_diag => 1,
	    decode_utf8 => 1,
	}
	);
    my @cols = @{$csv->getline ($fh)};
    $csv->column_names (@cols);

    my @rows;
    while (my $row = $csv->getline_hr ($fh)) {
	push @rows, $row;
    }
    
    close $fh;
    return \@rows;
} 

1;
