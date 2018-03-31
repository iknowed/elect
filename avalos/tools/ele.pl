#!/usr/local/bin/perl

use Postgres;
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$dbh = db_connect("elect");

$db->do("drop sequence elect_ele_seq");
$db->do("create sequence elect_ele_seq");
$db->do("drop table ele cascade");


$result = $db->doFile("sql/ele.sql");
print $dbh->errorMessage() if(!$result);


