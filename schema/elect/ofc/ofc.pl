#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop sequence ofc_ofcid_seq");
$db->do("create sequence ofc_ofcid_seq");
$db->do("drop table ofc cascade");
$db->doFile("sql/ofc.sql");

$offices = [ "Mayor","District Attorney","City Attorney","Treasurer","Assessor","Public Defender","Sheriff","Supervisor","School Board","Community College Board","DCCC","GCC","RCCC","Judge","BART","Assembly","State Senate"];

foreach $office (@{$offices}) {
	$db->do("insert into ofc (ofc) values ('$office')");
	$result = $db->do($sql);
}
