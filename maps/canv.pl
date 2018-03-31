#!/usr/bin/perl
use mapscript;
use Pg;
use DBI;
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty ="";
$dbname ="elect";
$login="elect";
$pwd ="";
$conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
$conn1 = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

$rmin = 255,$bmin = 0,$gmin = 0;
$rmax = 0,$bmax = 0,$gmax = 255;

$sql = "select distinct sup,type from canv,idtypes where cmpid=19 and canv.sup=idtypes.idtid";
$qy = $conn->exec($sql);
while(my(@row) = $qy->fetchrow) {
	push(@ids,$row[0]);
}

print<<EOF;
Content-Type: text/html

<HTML>
<HEAD>
<TITLE> </TITLE>
</HEAD>
<BODY>
<UL>
EOF

foreach $id(@ids) {
	print "<LI><IMG SRC='http://cybre.net/elect/maps.pl?cmpid=19&sup=$id'>\n";
}
print<<EOF;
</UL>
</BODY>
</HTML>
EOF
if(0) {
	$sql = "select count(mvf.voter_id),precinct from mvf, canv where cmpid=19 and sup=$id and mvf.voter_id=canv.voter_id group by precinct order by count(mvf.voter_id) desc";

	$qy = $conn->exec($sql);
	my $map = new mapscript::mapObj("canv.map") || die;
	$legend = new mapscript::legendObj;
	$legend->{height} = 500;
	$legend->{map} = $map;
	$legend{map} = $map;
	$map->{legend} = $legend;
$map{legend} = $legend;
	my $layer = $map->getLayer(0);
while(my (@row) = $qy->fetchrow) {
	$pct = $row[0];
	$pvi = $row[1];
	$Color = 255 - int (($pvi/100.0) * 210);
	print "PVI: $pct | $pvi | $Color | @{$mycolors[$Color]}\n";
	my($r,$g,$b) = @{$mycolors[$Color]};
	my $color = new mapscript::colorObj;
	my $c = new mapscript::classObj;
	$c->setExpression($pct);
	my $style = new mapscript::styleObj;
	$color->setRGB($r,$g,$b);
	$style->{color} = $color;
	my $outlinecolor = new mapscript::colorObj;
	$outlinecolor->setRGB(0,0,0);
	$style->{outlinecolor} = $outlinecolor;
	$c->insertStyle($style);
	$layer->insertClass($c,1);
}
$map->save("test.map");
$img = $map->draw || die;
$img->save("test.png") && die;

}
