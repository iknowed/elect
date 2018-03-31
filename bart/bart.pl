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
$conn1 = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);


open(BART,"<bart.csv");
while(<BART>) {
	s/PCT //;
	s/\"//g;
	($pct_e,$m_e,$f_e) = split(/,/);
	<BART>;
	s/PCT //;
	s/\"//g;
	($pct_a,$m_a,$f_a) = split(/,/);
	$m = $m_e + $m_a;
	$f = $f_e + $f_a;
	$mpct = substr(100*(1.0*$m)/((1.0*$m)+(1.0*$f)),0,3);
	$sql = "update pct92 set mpct = $mpct where pct='".$pct_a."'";
	$conn->exec($sql);
}
