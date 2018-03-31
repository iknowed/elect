#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$qy = $db->do("insert into ele (edate) values ('2003-12-09')");
$qy = $db->do("select eleid from ele where edate='2003-12-09'");
$eleid = $qy->fetchrow;
$db->do("insert into cmp (campaign,eleid) values ('MG4M',$eleid)");
$qy = $db->do("select cmpid from cmp where campaign='MG4M'");
$cmpid = $qy->fetchrow;

$qy = $db->do("select idtid from idtypes where type ='SUP'");
$idtid = $qy->fetchrow;
open(SUP,"</h/v");
$sups = 0;
$eday = 0;
$abs = 0;
while(<SUP>) { 
	(@flds) = split("\t");
	foreach ($f = 0 ; $f < $#flds ; $f++ ) {
		if($flds[$f] eq 'SUP') {
			$sups++;
			#$sql = "select v from e031209 where voter_id=$flds[57]";
			$sql = "insert into ids (voter_id,cmpid,idtid) values ($flds[57],$cmpid,$idtid)";
			$res = $db->do($sql);
			next unless $res;
			my $qy = $res->fetchrow;
			next unless $qy;
			if($qy eq "V") {
				$eday++;
			}	
			if($qy eq "A") {
				$abs++;
			}	
		}
	}
}
print "$sups $abs $eday\n";

print "supporters: $sups\n";
$abspct = substr(($abs/$sups),0,4);
print "absentee: $abs $abspct %\n";
$edaypct = substr(($eday/$sups),0,4);
print "eday: $eday $edaypct %\n";
$suppct = substr((($eday+$abs)/$sups),0,4);
print "Sup turnout: $suppct%\n";
