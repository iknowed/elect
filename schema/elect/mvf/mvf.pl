#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$db->do("drop table mvf cascade");
$db->do("drop trigger vid_trigger on vid");
$db->do("drop function vid_trigger()");
$result = $db->doFile("sql/mvf.sql");
#$db->do("CREATE TRIGGER vid_trigger BEFORE INSERT ON mvf FOR EACH ROW EXECUTE PROCEDURE vid_trigger();");
