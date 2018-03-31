#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence race_rid_seq"); 
$db->do("create sequence race_rid_seq");
$db->do("drop table race cascade");
$result = $db->doFile("sql/race.sql");

