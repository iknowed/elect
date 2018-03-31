#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence vid_voter_id_seq");
$db->do("drop table vid cascade");
$db->do("drop trigger vid_trigger on vid");
$db->do("drop function vid_trigger()");
$result = $db->doFile("sql/vid.sql");
#$result = $db->doFile("sql/vid_trigger.sql");
