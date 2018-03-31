#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$db->do("drop table ten");
$result = $db->doFile("sql/ten.sql");
$db->do("insert into ten select voter_id from voters");
print $db->{err};
