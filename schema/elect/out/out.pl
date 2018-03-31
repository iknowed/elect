#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence outreachtypes_ortid_seq");
$db->do("create sequence outreachtypes_ortid_seq");

$db->do("drop sequence outreach_orid_seq");
$db->do("create sequence outreach_orid_seq");

$db->do("drop table outreachtypes cascade");
$db->do("drop table outreach cascade");
$db->do("drop table out cascade");

$result = $db->doFile("sql/out.sql");

$db->do("insert into outreachtypes (type,feedback) values ('phone',true)");
$db->do("insert into outreachtypes (type,feedback) values ('phone',false)");
$db->do("insert into outreachtypes (type,feedback) values ('drop',false)");
$db->do("insert into outreachtypes (type,feedback) values ('canvass',true)");
$db->do("insert into outreachtypes (type,feedback) values ('canvass',false)");
$db->do("insert into outreachtypes (type,feedback) values ('mail',true)");
$db->do("insert into outreachtypes (type,feedback) values ('mail',false)");
