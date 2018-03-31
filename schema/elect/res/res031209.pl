#!/usr/local/bin/perl
push(@INC,".");
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$db->do("drop table res031209 cascade");
$db->doFile("sql/res031209.sql");

open(RES,"<data/psv1.csv");
$f = <RES>;
chop($f);
chop($f);
(@F) = split(",",$f);
while(<RES>) {
	chomp;
	chop;
	s/([AV])/'$1'/;
	s/[\s]*M*L[\s]*//g;
	my(@V) = split(",");
	$sql = "insert into  res031209 ($f) values ($_)";
	$res = $db->do($sql);
}

$sql = "select * from res031209 order by pct, typ";
$qy = $db->do($sql);
while(my @one = $qy->fetchrow) {
	my @two = $qy->fetchrow;	
	$pct = $one[0];
	$reg = $one[2];
	my @vals;
	push(@vals,$pct);
	push(@vals,"'T'");
	push(@vals,$reg);
	for($i = 3 ; $i  <= $#one ; $i++ ) {
		push(@vals,$one[$i]+$two[$i]);
	}
	$val = join(",",@vals);
	$sql = "insert into  res031209 ($f) values ($val)";
	$res = $db->do($sql);
	print $db->{err};
}
