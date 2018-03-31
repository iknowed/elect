#!/usr/bin/perl
use Pg;
use DBI;
use GD::Graph::bars;
use GD::Graph::pie;
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty =""; $dbname ="elect";
$login="elect";
$pwd ="";
$conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

$n = 0;
$t = 0;
$sql = "select distinct(voter_id) from voters ";
$sth = $conn->exec($sql);
while(my(@row) = $sth->fetchrow) {
	my $voter_id = $row[0];
	my $sql = "select name_last,birth_place,precinct from mvf where voter_id=$voter_id";
	my $sth = $conn->exec($sql);
	my $res;
	my $name_last;
	my $birth_place;
	my $precinct;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$name_last = $row[0];
		$birth_place = $row[1];
		$precinct = $row[2];	
	}
	undef($sth);
	my $border_state;
	if(($birth_place eq "CA") || ($birth_place eq "AZ") || ($birth_place eq "NM") || ($birth_place eq "TX")) {
		$border_state = 1;
	}
	$sql = "select ethnicity from ethnicities,snames where (surname='$name_last' and snames.eid=ethnicities.eid)";
	$sth = $conn->exec($sql);
	my $latino_eth = 0;
	my $neth = 0;
	if($sth) {
		while(my(@row) = $sth->fetchrow) {
			$neth++;
			my $ethnicity = $row[0];
			$latino_eth += ($ethnicity eq "Hispanic");
		}
	}
	if($neth == 0) {
		$latino_eth = 0;
	} else {
		$latino_eth = 1.5 * ( $latino_eth / $neth );
	}
	$sql = "select language from bplaces,langs where bplace='$birth_place' and (bplaces.lid=langs.lid)";
	$sth = $conn->exec($sql);
	my $nlangs = 0;
	my $spanish = 0;
	if($sth) {
		while(my(@row) = $sth->fetchrow) {
			$nlangs++;	
			$lang = $row[0];
			if($lang eq "Spanish") { $spanish = 2; }
		}
	}
	undef($sth);
	if($spanish == 0) {
		if($latino_eth && $border_state) {
			$spanish = .5;
		}
	} else {
		if($nlangs >= 1) {
			$spanish = ($langs / $nlangs);
		}
	}
	$supv = substr($precinct,1,1);
	$supv = 11 if(substr($precinct,1,2) eq "11");
	$supv = 10 if(substr($precinct,1,1) eq "0");
	$sql = "select avg(p_hisp) from pct where supv=$supv";
	$sth = $conn->exec($sql);
	my $avg = 0;
	if($sth) {
		my(@row)  = $sth->fetchrow;
		$avg = int($row[0]*100);
	}
	undef($sth);
	$sql = "select p_hisp from pct where pct=$precinct";
	$sth = $conn->exec($sql);
	my $p_hisp = 0;
	if($sth) {
		my(@row)  = $sth->fetchrow;
		$p_hisp = int($row[0]*100);
	}
	undef($sth);
	$hisp_cut = 0;
	if($avg) {
		$hisp_cut = ($p_hisp/$avg) >= .5 ? 1 : 0;
	} 
		
	my $r = ($hisp_cut+$spanish+$latino_eth);
	if($r > 1.5) {
		$islat = 't';
		$t++;
	} else {
		$islat = 'f';
	}
	$sql = "update islatino set islat='$islat' where voter_id=$voter_id";
	$conn->exec($sql);
	print $db->{err} if($db->{err});
	if($n++ % 5000 == 0) { $per = int(($t/$n) * 100); print "$n : $per %\n"; }
}
