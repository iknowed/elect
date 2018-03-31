#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$sql = "select block,lot,name from ass";
$qy = $db->do{$sql);
while(my(@res) = $qy->fetchrow) {
	$block = $res[0];
	$lot = $res[1];
	($block,$lot) = split(" ",substr($_,3,9));
	next unless(length($lot) && length($block));
	$own = substr($_,14,30);
	$own =~ s/\'/\\'/g;
	$own =~ s/[\s]*$//;
	$own = "'" . $own . "'";
	$own =~ s/\s[A-Z]\s/\ /g;
	$block = "'" . $block . "'";
	$lot = "'" . $lot . "'";
	$sql = "insert into ass (block,lot,name) values ($block,$lot,$own)";
	my $res = $db->do($sql);
	if($res) {
		$good++;
	} else {
		$bad++;
	}	
}
