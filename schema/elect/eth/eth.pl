#!/usr/local/bin/perl

use Postgres;
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$dbh = db_connect("elect");

$db->do("drop sequence ethnicities_eid_seq");
$db->do("create sequence ethnicities_eid_seq");
$db->do("drop table ethnicities cascade");
$db->do("drop table eth cascade");
$result = $db->doFile("sql/eth.sql");

(@eths) = ("Latino","Filipino","Chinese","Russian","Samoan","Iranian","Arab","Korean","Vietnamese","Jewish");

foreach $eth (@eths) {
	$sql = "insert into ethnicities (ethnicity) values ('".$eth."')";
	$result = $db->do($sql);
}
