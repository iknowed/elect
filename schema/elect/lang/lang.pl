#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence languages_lid_seq");
$db->do("create sequence languages_lid_seq");
$db->do("drop table languages cascade");
$db->do("drop table lang cascade");
$db->doFile("sql/lang.sql");

(@langs) = ("English","Spanish","Tagalog","Chinese","Russian","Samoan","Farsi","Arabic","Korean","Vietnamese");

foreach $lang (@langs) {
	$db->do("insert into languages (language) values ('".$lang."')");
	$result = $db->do($sql);
}
