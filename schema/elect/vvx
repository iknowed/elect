#!/usr/local/bin/perl
push(@INC,".");
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
open(VVX,">vvx");
$qy = $db->do("select voter_id,v from e031209 order by voter_id");
while(my @res = $qy->fetchrow) {
	$vid = $res[0];
	$v = $res[1];
	print VVX "$vid,'$v'\n";
}
close VVX;
