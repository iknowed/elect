#!/usr/local/bin/perl
push(@INC,".");
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$db->do("drop table pct cascade");
$db->doFile("sql/pct.sql");

$query = $db->do("select precinct,party,SEN,ASSM,SUPV,BART,gender,Perm from mvf");
while(my(@row) = $query->fetchrow()) {
	$pct = $row[0];
	$party = $row[1];
	$SEN = $row[2];
	$ASSM = $row[3];
	$SUPV = $row[4];
	$BART = $row[5];
	$gen = $row[6];
	$vbm = $row[7];
	$party =~ s/[\s]*$//g;
	$party =~ s/[\s]*$//g;
	next if($party ne "NP-0" && $party =~ /0$/);
	$party =~ s/\-[0-9]$//g;
	$party =~ s/\&/N/g;
	$pcts{$pct}->{$party}++;
	$tot{$pct}++;
	$sen{$pct} = $SEN;
	$assm{$pct} = $ASSM;
	$supv{$pct} = $SUPV;
	$bart{$pct} = $BART;
	$gen{$pct}++ if($gen eq "F");
	$vbm{$pct}++ if($vbm eq "Y");
}

foreach $pct ( sort keys %pcts ) {
	$p = $pcts{$pct};
	$reg = $tot{$pct};
	next if($reg == 0);
	$SEN = $sen{$pct};
	$ASSM = $assm{$pct};
	$SUPV = $supv{$pct};
	$BART = $bart{$pct};
	$gen = $gen{$pct};
	$vbm = $vbm{$pct};
	$BART =~ s/^A//;
	my(@ptys);
	foreach $party ( keys %{$p} ) {
		if($party ne "NP" && $party =~ /0$/) {
			next;	
		}
		$ptys{$party} = substr($p->{$party}/$reg,0,5);
	}
	$gen = substr($gen/$reg,0,5);
	$vbm = substr($vbm/$reg,0,5);
	$sql = "insert into pct (pct,sen,assm,supv,bart,reg,np,dem,rep,aip,grn,lib,nlp,pnf,rfm,fem,vbm) values ($pct,$SEN,$ASSM,$SUPV,$BART,$reg,$ptys{NP},$ptys{DEM},$ptys{REP},$ptys{AIP},$ptys{GRN},$ptys{LIB},$ptys{NLP},$ptys{PNF},$ptys{RFM},$gen,$vbm)";
	$result=$db->do($sql);
	if($pct > 9999) {
		$npct = $pct/100;
		$sql = "update mvf set precinct=$npct where precinct=$pct";
		$result = $db->do($sql);
	}
}
