#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use Data::Dumper;

use SqlBatch::Plan;
use SqlBatch::Configuration;

my $conffile1  =<<'FILE1';
{
    "datasource" : "DBI:RAM:",
    "username" : "user",
    "password" : "pw",
    "force_autocommit" : "1"
}
FILE1
;

my $conf1 = SqlBatch::Configuration->new(\$conffile1);
my $dbh   = $conf1->database_handles->{autocommitted};

my @instructions1 = ();

my $plan1 = SqlBatch::Plan->new($conf1);

#my $filter1 = SqlBatch::PlanTagFilter->new();

my $insert_sth;
my $delete1_sth;
my $delete2_sth;

my @seq1 = (
    {
	type => 'SQL',
	sql  => 'create table t (a int,b varchar)',
    },
    {
	type => 'INSERT',
	table => 't',
        data => {
	    a => 1,
	    b => 'first',
	},
	sth_placeholder => \$insert_sth,
    },
    {
	type  => 'INSERT',
	table => 't',
        data  => {
	    a => 2,
	    b => 'second',
	},
	sth_placeholder => \$insert_sth,
    },
    {
	type  => 'INSERT',
	table => 't',
        data  => {
	    a => 3,
	    b => 'third',
	},
	sth_placeholder => \$insert_sth,
    },
    {
	type  => 'DELETE',
	table => 't',
        data  => {
	    a => 1,
	},
	sth_placeholder => \$delete1_sth,
    },
    {
	type  => 'DELETE',
	table => 't',
        data  => {
	    b => 'second',
	},
	sth_placeholder => \$delete2_sth,
    },
);

$plan1->add_instructions(@seq1);
eval {
    $plan1->run();
};
ok(! $@,"Running sequence");
say $@ if $@;

my $ary = $dbh->selectall_arrayref("select * from t");
ok(scalar(@$ary)==1,"Execution reached expected state");
#say Dumper($ary);

done_testing;
