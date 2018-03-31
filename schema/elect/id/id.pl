#!/usr/local/bin/perl
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence idtypes_idtid_seq");
$db->do("create sequence idtypes_idtid_seq");
$db->do("drop sequence id_idid_seq");
$db->do("create sequence id_idid_seq");
$db->do("drop table idtypes cascade");
$db->do("drop table ids cascade");

# phone, walk, canvass, mail
$db->doFile("sql/id.sql");

$sql = "insert into idtypes (type) values ('SUP')";
$result = $db->do($sql);
print $result;

$sql = "insert into idtypes (type) values ('AGN')";
$result = $db->do($sql);
print $result;

$sql = "insert into idtypes (type) values ('UND')";
$result = $db->do($sql);
print $result;

$sql = "insert into idtypes (type) values ('DNC')";
$result = $db->do($sql);
print $result;

$sql = "insert into idtypes (type) values ('BAD')";
$result = $db->do($sql);
print $result;


