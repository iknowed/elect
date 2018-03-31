#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$db->do("drop table pvi cascade");
$db->doFile("sql/pvi.sql");

open(PVI,"<data/pvi");
while(<PVI>) {
	chomp;
	($pct,$score) = split(",");
	$sql = "insert into pvi values ($pct,$score)";
	$db->do($sql);
}
