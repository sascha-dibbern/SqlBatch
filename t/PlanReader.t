#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use SqlBatch::PlanReader;
use Data::Dumper;

my $reader = SqlBatch::PlanReader->new(undef,undef);
my $file1  =<<'FILE1';
# Comment
undefined line
--SQL-- --id sql1
blabla
--END--

--INSERT-- --id=insert1
'a';'b'
'1';'2'
--END--

--SQL-- --id=sql2
blabla
--END--

--DELETE-- --id==delete1
'a';'b'
'1';'2'
--END--
FILE1

$reader->files(\$file1);
my @ep = $reader->execution_plan;
ok(scalar(@ep)==4,"Correct number of instructions");
#say Dumper(\@ep);

done_testing;
