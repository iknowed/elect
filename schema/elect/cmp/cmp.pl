#!/usr/local/bin/perl

use Postgres;
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$result = $db->do("drop sequence campaigns_cmp_seq");
$result = $db->do("drop table cmp cascade");

$result = $db->doFile("sql/cmp.sql");

