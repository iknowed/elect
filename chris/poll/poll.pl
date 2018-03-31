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
$cut="061018";
my(@wheres,@langs,@eths,@histbool,@genders,@supvs,@parties,@bplaces,@bplace,@excc,@incc);
my($agemin,$agemax,$pvimin);
my($pvimax,$medmin,$medmax);
my($regageminmo,$regagemaxmo,$REGAGEMIN);
my($regageminyr,$regagemaxyr,$REGAGEMAX);
my($tenant);
my($HIST)='V';
my($HISTBOOL)='AND';
my($LIST) = 'W';
my($EMAIL);
my $req;
if($ENV{QUERY_STRING} || ($ENV{REQUEST_METHOD} eq "POST")) {
	if($ENV{REQUEST_METHOD} eq "POST") {
		$req = <>;
	} else {
		$req = $ENV{QUERY_STRING};
	}
	#langs=1&gender=F&supv=&party=12653&agemin=40&agemax=18
	$tables{mvf} = 1;
	foreach(split(/&/,$req)) {
		if(/^langs/) {
			$tables{lang} = 1;
			$tables{langs} = 1;
			my ($foo,$lang) = split(/=/);
			push(@langs,$lang);
		}
		if(/^gender/) {
			my ($foo,$gender) = split(/=/);
			push(@genders,$gender);
		}
		if(/^ten/) {
			$tables{ten} = 1;
			my ($foo,$ten) = split(/=/);
			$tenant = $ten;
		}
		if(/^list/) {
			my ($foo,$list) = split(/=/);
			$LIST = $list;
		}
		if(/^supv/) {
			my ($foo,$supv) = split(/=/);
			push(@supvs,$supv);
		}
		if(/^email/) {
			my ($foo,$email) = split(/=/);
			$EMAIL = $email;
		}
		if(/^perm/) {
			my ($foo,$perm) = split(/=/);
			push(@perms,$perm);
		}
		if(/^cong/) {
			my ($foo,$cong) = split(/=/);
			push(@congs,$cong);
		}
		if(/^assm/) {
			my ($foo,$assm) = split(/=/);
			push(@assms,$assm);
		}
		if(/^sen/) {
			my ($foo,$sen) = split(/=/);
			push(@sens,$sen);
		}
		if(/^bart/) {
			my ($foo,$bart) = split(/=/);
			push(@barts,$bart);
		}
		if(/^zip/) {
			my ($foo,$zip) = split(/=/);
			push(@zips,$zip);
		}
		if(/^precinct/) {
			my ($foo,$precinct) = split(/=/);
			push(@precincts,$precinct);
		}
		if(/^inc_canvs/) {
			my ($foo,$inc_canv) = split(/=/);
			push(@inc_canvs,$inc_canv);
		}
		if(/^exc_canvs/) {
			my ($foo,$exc_canv) = split(/=/);
			push(@exc_canvs,$exc_canv);
		}
		if(/^party/) {
			my ($foo,$party) = split(/=/);
			$party =~ s/%26/&/;
			push(@parties,$party);
		}
		if(/^hist/ && !/bool/) {
			s/%3A/:/g;
			my ($foo,$hist) = split(/=/);
			push(@hists,$hist);
		}
		if(/^histbool/) {
			my ($foo,$histbool) = split(/=/);
			$HISTBOOL = $histbool;
		}
		if(/^bplace/) {
			$tables{bplaces} = 1;
			my ($foo,$bplace) = split(/=/);
			push(@bplaces,$bplace);
		}
		if(/^eths/) {
			$tables{ethnicities} = 1;
			$tables{eth} = 1;
			my ($foo,$eth) = split(/=/);
			push(@eths,$eth);
		}
		if(/^agemin/) {
			($foo,$agemin) = split(/=/);
		}
		if(/^agemax/) {
			($foo,$agemax) = split(/=/);
		}
		if(/^pvimin/) {
			($foo,$pvimin) = split(/=/);
		}
		if(/^pvimax/) {
			($foo,$pvimax) = split(/=/);
		}
		if(/^medmin/) {
			($foo,$medmin) = split(/=/);
		}
		if(/^medmax/) {
			($foo,$medmax) = split(/=/);
		}

		if(/^regageminmo/) {
			($foo,$regageminmo) = split(/=/);
			$REGAGEMIN = 1;
		}
		if(/^regageminyr/) {
			($foo,$regageminyr) = split(/=/);
			$REGAGEMIN = 1;
		}

		if(/^regagemaxmo/) {
			($foo,$regagemaxmo) = split(/=/);
			$REGAGEAX = 1;
		}
		if(/^regagemaxyr/) {
			($foo,$regagemaxyr) = split(/=/);
		}
	}
	#$from = join(",",keys %tables);
	if($#langs > -1) {
		my(@l);
		foreach $lid (@langs) {
			push(@l,"(  mvf$cut.voter_id in ( select voter_id from lang where lang.lid=$lid ) )");
		}
		if($#langs == 0) {
			push(@owheres," $l[0] ");
		} else {
			push(@owheres, join(" OR ",@l));
		}
	}
	if($#genders > -1) {
		my(@g);
		foreach $gender (@genders) {
			if($gender eq "O") {
				push(@g,"(  gender is NULL )");
			} else {
				$g = $gender;
				$g =~ tr/MF/mf/;
				push(@g,"( ( gender = '$gender') OR ( gender = '$g' ) )");
			}
		}
		if($#genders== 0) {
			push(@wheres,$g[0]);
		} else {
			push(@wheres,join(" or " , @g));
		}
	}
	if($LIST eq "P") {
		push(@wheres," ( phone is not NULL ) ");
	}
	if($LIST eq "E") {
		push(@wheres," ( email is not NULL ) ");
	}
	if(length($EMAIL)) {
		if($email eq 'E') {
			push(@wheres," ( email is not NULL ) ");
		}
		if($email eq 'N') {
			push(@wheres," ( email is NULL ) ");
		}
	}
	if($#perms > -1) {
		my(@p);
		foreach $perm (@perms) {
			if($perm eq "Y") {
				$HIST = "A";
				push(@perm,"(  perm = 'Y' )");
			} 
			if($perm eq "N") {
				$HIST = "V";
				push(@perm,"(  perm = 'N' )");
			}
		}
		if($#perm == 0) {
			push(@wheres,$perm[0]);
		} else {
			push(@wheres,join(" or " , @perm));
		}
	}
	if($#supvs > -1) {
		my(@s);
		foreach $supv (@supvs) {
			push(@s,"(  supv = $supv )");
		}
		if($#supvs== 0) {
			push(@wheres,$s[0]);
		} else {
			push(@wheres," ( " .join(" or " ,@s) . " ) ");
		}
	}
	if($#barts > -1) {
		my(@s);
		foreach $bart (@barts) {
			push(@s,"(  bart = $bart )");
		}
		if($#barts== 0) {
			push(@wheres,$s[0]);
		} else {
			push(@wheres,join(" or ",@s));
		}
	}
	if($#congs > -1) {
		my(@s);
		foreach $cong (@congs) {
			push(@s,"(  cong = $cong )");
		}
		if($#congs== 0) {
			push(@wheres,$s[0]);
		} else {
			push(@wheres,join(" or " ,@s));
		}
	}
	if($#assms > -1) {
		my(@s);
		foreach $assm (@assms) {
			push(@s,"(  assm = $assm )");
		}
		if($#assms== 0) {
			push(@wheres,$s[0]);
		} else {
			push(@wheres,join(" or ",@s));
		}
	}
	if($#sens > -1) {
		my(@s);
		foreach $sen (@sens) {
			push(@s,"(  sen = $sen )");
		}
		if($#sens== 0) {
			push(@wheres,$s[0]);
		} else {
			push(@wheres,join(" or ", @s));
		}
	}
	if($#parties > -1) {
		my(@p);
		foreach $party(@parties) {
			push(@p,"(  party= '$party')");
		}
		if($#p == 0) {
			push(@wheres,$p[0]);
		} else {
			push(@wheres," ( " . join(" OR ", @p) . " ) ");
		}
	}
	if($#hists > -1) {
		my(@H);
		foreach $hist(@hists) {
			my($e,$v) = split(/:/,$hist);
			push(@H,"( $e = '$v' ) ");
		}
		if($#hists == 0) {
			push(@wheres,$H[0]);
		} else {
			push(@wheres," ( " . join(" $HISTBOOL ",@H) . " ) ");
		}
	}
	if($#bplaces > -1) {
		my(@b);
		$tables{bplaces} = 1;
		foreach $bplace(@bplaces) {
			push(@b,"( birth_place = '$bplace' )");
		}
		if($#bplaces == 0) {
			push(@owheres,$b[0]);
		} else {
			push(@owheres,join(" OR ",@b));
		}
	}
	if($#eths > -1) {
		my(@e);
		foreach $eid(@eths) {
			push(@e,"(  mvf$cut.voter_id in ( select voter_id from eth where eth.eid=$eid ) )");
		}
		if($#eths== 0) {
			push(@owheres,$e[0]);
		} else {
			push(@owheres,join(" OR ",@e));
		}
	}
	if($#inc_canvs > -1) {
		foreach $inc_canv(@inc_canvs) {
			if($inc_canv =~ /^[0-9]+$/) {
				push(@incc," ( sup = $inc_canv ) ");
			} else {
				if($inc_canv =~ /[0-9]+$/) {
					$_ = $inc_canv;
					($fld,$val) = split(/:/);
					push(@incc," ( $fld = $val ) ");
				} else {
					push(@incc," ( $inc_canv = 1 ) ");
				}
			}
		}
	}
	if($#exc_canvs > -1) {
		foreach $exc_canv(@exc_canvs) {
			if($exc_canv =~ /^[0-9]+$/) {
				push(@excc," ( sup = $exc_canv ) ");
			} else {
				if($exc_canv =~ /[0-9]+$/) {
					$_ = $exc_canv;
					($fld,$val) = split(/:/);
					push(@excc," ( $fld = $val ) ");
				} else {
					push(@excc," ( $exc_canv = 1 ) ");
				}
			}
		}
	}
	if(length($tenant)) {
			push(@wheres,"(  mvf$cut.voter_id=ten.voter_id and ten.tenant='$tenant' )");
	}
	if(length($regageminmo) || length($regageminyr)) {
		my $w;
		if(length $regageminyr) {
			$w = " $regageminyr years ";
		}
		if(length regageminmo) {
			$w .= " $regageminmo months ";
		}
		push(@wheres," ( age(reg_date) > '$w' ) ");
	}
	if(length($regagemaxmo) || length($regagemaxyr)) {
		my $w;
		if(length $regagemaxyr) {
			$w = " $regagemaxyr years ";
		}
		if(length $regagemaxmo) {
			$w .= " $regagemaxmo months ";
		}
		push(@wheres," ( age(reg_date) < '$w' ) ");
	}
	if($agemin) {
		push(@wheres," ( age(birth_date) > '$agemin years' ) ");
	}
	if($agemax) {
		push(@wheres," ( age(birth_date) < '$agemax years' ) ");
	}
	if($pvimin) {
		push(@wheres," ( mvf$cut.precinct=pvi.precinct and pvi.pvi > $pvimin  ) ");
	}
	if($pvimax) {
		push(@wheres," ( mvf$cut.precinct=pvi.precinct and pvi.pvi < $pvimax  ) ");
	}
	if($medmin) {
		push(@wheres," ( mvf$cut.precinct=pct.pct and pct.median > $medmin  ) ");
	}
	if($medmax) {
		push(@wheres," ( mvf$cut.precinct=pct.pct and pct.median < $medmax  ) ");
	}

	if($#precincts > -1) {
		my(@p);
		foreach $precinct(@precincts) {
			push(@p,"(  precinct = $precinct )");
		}
		if($#p == 0) {
			push(@wheres,$p[0]);
		} else {
			push(@wheres," ( " . join(" OR ", @p) . " ) ");
		}
	}
	if($#zips > -1) {
		my(@p);
		foreach $zip(@zips) {
			push(@p,"(  substr(zip,1,5) = '$zip')");
		}
		if($#p == 0) {
			push(@wheres,$p[0]);
		} else {
			push(@wheres," ( " . join(" OR ", @p) . " ) ");
		}
	}
	$foo = $#wheres;
	if($#wheres == 0) {
		$where = $wheres[0];
	} else {
		$where = join(" AND ",@wheres);
	}
	if($#owheres >= 0) {
		$where .= " AND ( " . join(" OR ",@owheres) . " ) ";
	}
	if($#excc > -1) {
		push(@cwheres,"mvf$cut.voter_id not in ( select voter_id from canv where cmpid=19 and ( " . join(" OR ",@excc) . " ) ) ");
	}
	if($#incc > -1) {
		push(@cwheres,"mvf$cut.voter_id in ( select voter_id from canv where cmpid=19 and ( " . join(" OR ",@incc) . " ) ) ");
	}
	$cwhere = join(" OR ",@cwheres);
	if($#cwheres > -1) {
		if(length($where)) {
			$where .= " AND ( $cwhere ) ";
		} else {
			$where = " ( $cwhere ) ";
		}
	}
	$where = " mvf$cut.voter_id in ( select voter_id from poll ) ";

select(STDOUT);
$| = 1;
print<<EOF;
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>$fname | $lname | $radius</TITLE>
</HEAD>
<BODY>
<TABLE>
EOF

#$debug = 1;
$debug && print "<br>req: $req\n";
$debug && print "<br>tenant: $tenant\n";
print "<br>\@ wheres: $where\n";
$debug && print "<br>wheres: $where\n";
$w = "where ( $where ) " if (length($where));
$and = "and" if(length($where));
$sql = "select count(distinct(voter_id)) from mvf$cut $w ";
$debug && print "<br>sql: $sql\n";
$qy = $conn->exec($sql);
print "$sql<br>\n";
my(@row) = $qy->fetchrow;
print "<TR><TD COLSPAN=2>Total registered voters:\n&nbsp; &nbsp; &nbsp; &nbsp;$row[0]</TD></TR>\n";
$debug && print "<TR><TD COLSPAN=2>$sql</TD></TR>\n";

my $tot = $row[0];
$w = "where ( $where ) " if (length($where));
$and = "and" if(length($where));
$sql = "select gender,count(distinct(mvf$cut.voter_id)) from mvf$cut  $w group by gender order by count(distinct(mvf$cut.voter_id)) desc";    
$qy = $conn->exec($sql);
print "<TR><TD>Gender:\n";
$n = 0;
undef(@data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$gender = $row[0];
	$gender = "\?" unless length $gender;
	$count  = $row[1];
	push(@data,"tag$n=$gender");
	push(@data,"val$n=$count");
	$n++;
	next unless($count);
	print "<TR><TD>$gender:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";    
} 
print "</TABLE>\n";
print "<br>F/M = DOE coded, f/m = Census guess<br>\n";
push(@data,"type=pie");
push(@data,"title=Gender");
$Data = join("&",@data);
$gen .= "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>\n";
	
print $gen;

$debug && print "<TR><TD COLSPAN=2>$sql</TD></TR>\n";

undef(@data);
$w = "where ( $where ) " if (length($where));
$and = "and" if(length($where));
$sql = "select perm,count(distinct(mvf$cut.voter_id)) from mvf$cut  $w group by perm order by count(distinct(mvf$cut.voter_id)) desc";    
$qy = $conn->exec($sql);
print "<TR><TD>Permanent Absentee:\n";
$n = 0;
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$perm = $row[0];
	$count  = $row[1];
	push(@data,"tag$n=$perm");
	push(@data,"val$n=$count");
	$n++;
	next unless($count);
	print "<TR><TD>$perm:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";    
} 
print "</TABLE>\n";
push(@data,"title=Absentee");
push(@data,"type=pie");
$Data = join("&",@data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>";
$debug && print "<BR>$sql\n";

print "<TR><TD>Party:\n";
$w = "where ( $where ) " if (length($where));
$sql = "select party,count(distinct(mvf$cut.voter_id)) from mvf$cut  $w group by party order by count(distinct(mvf$cut.voter_id)) desc limit 5";
$qy = $conn->exec($sql);
$n = 0;
undef(@data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$pty = $row[0];
	$count  = $row[1];
	push(@data,"tag$n=$pty");
	push(@data,"val$n=$count");
	$n++;
	next unless($count);
	print "<TR><TD>$pty:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
}
print "</TABLE>\n";
push(@data,"title=Party+Registration");
push(@data,"type=pie");
$Data = join("&",@data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>\n";

print "<TR><TD>Supe District:\n";
$w = "where ( $where ) " if (length($where));
$sql = "select supv,count(distinct(mvf$cut.voter_id)) from mvf$cut  $w group by supv order by count(distinct(mvf$cut.voter_id)) desc ";
$qy = $conn->exec($sql);
$n = 0;
undef(@data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$supv = $row[0];
	$count  = $row[1];
	push(@data,"tag$n=$supv");
	push(@data,"val$n=$count");
	$n++;
	next unless($count);
	print "<TR><TD>$supv:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
}
print "</TABLE>\n";
push(@data,"title=Supe+District");
push(@data,"type=pie");
$Data = join("&",@data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>";

$w = " where ";
$w = "where ( $where ) " if (length($where));
$and = " and "  if (length($where));
$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut  $w $and birth_place in ( select st from us )";
$qy = $conn->exec($sql);
my(@row) = $qy->fetchrow;
print "<TR><TD COLSPAN=2>US born:\n&nbsp; &nbsp; &nbsp; &nbsp;$row[0] ".&pct($row[0],$tot)."</TD></TR>\n";
$debug && print "<BR>$sql\n";

$w = " where ";
$w = "where ( $where ) " if (length($where));
$and = " and "  if (length($where));
$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut  $w $and birth_place is null";
$qy = $conn->exec($sql);
my(@row) = $qy->fetchrow;
print "<TR><TD COLSPAN=2>Birthplace NULL:\n&nbsp; &nbsp; &nbsp; &nbsp;$row[0] ".&pct($row[0],$tot)."</TD></TR>\n";
$debug && print "<BR>$sql\n";

$w = "where ( $where ) " if (length($where));
$sql = "select bplace,count(distinct(mvf$cut.voter_id)) from mvf$cut,bplaces $w $and ( code=birth_place and birth_place not in ( select st from us )) group by bplace order by count(distinct(mvf$cut.voter_id)) desc";
$qy = $conn->exec($sql);
print "<TR><TD COLSPAN=2>Foreign born:\n";
$n = 0;
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$bp = $row[0];
	$count  = $row[1];
	next unless($count);
	print "<TR><TD>$bp:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
	last if(($n++ > 5) && ($count < 100));
}
print "</TABLE>\n";
print "</TD></TR>\n";

$w = "where ( $where ) " if (length($where));
$sql = "select ethnicities.ethnicity,count(distinct(mvf$cut.voter_id)) from mvf$cut $w $and eth.eid=ethnicities.eid and mvf$cut.voter_id=eth.voter_id group by ethnicities.ethnicity order by count(distinct(mvf$cut.voter_id)) desc";
$qy = $conn->exec($sql);
print "<TR><TD COLSPAN=2>Ethnicity (derived)\n<br>";
$n = 0;
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$ethnicity= $row[0];
	$count  = $row[1];
	next unless($count);
	print "<TR><TD>$ethnicity:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
	last if(($n++ > 5) && ($count < 100));
}
print "</TABLE>\n";
print "</TD></TR>\n";


$w = "where ( $where ) and " if (length($where));
$w = " where " unless length($where);
$sql = " select count(mvf$cut.voter_id),langs.language from mvf$cut,langs,lang $w  ( mvf$cut.voter_id=lang.voter_id and lang.lid=langs.lid ) group by langs.language order by count(mvf$cut.voter_id) desc";
$qy = $conn->exec($sql);
print "<TR><TD COLSPAN=2>Language (derived)\n<br>";
$n = 0;
print "<TABLE CELLPADDING=3 BORDER=1>\n";
while(my(@row) = $qy->fetchrow) {
	$count  = $row[0];
	$language = $row[1];
	next unless($count);
	print "<TR><TD>$language:</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
	last if(($n++ > 5) && ($count < 100));
}
print "</TABLE>\n";
print "</TD></TR>\n";

print "<TR><TD COLSPAN=3>Email</TD></TR>\n";
$w = "where ( $where ) " if (length($where));
$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut $w $and email is null";
#print "<TR><TD>$sql</TD></TR>\n";
$qy = $conn->exec($sql);
my(@r) = $qy->fetchrow;
my $nullemails = $r[0];
$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut $w $and email is not null";
#print "<TR><TD>$sql</TD></TR>\n";
$qy = $conn->exec($sql);
my(@r) = $qy->fetchrow;
my $emails = $r[0];
undef(@data);
push(@data,"tag0=email");
push(@data,"val0=$emails");
push(@data,"tag1=nullemail");
push(@data,"val1=$nullemails");
push(@data,"title=Email");
push(@data,"type=pie");
$Data = join("&",@data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
print "<TR><TD>email:</TD><TD ALIGN='RIGHT'>$emails</TD><TD>".&pct($emails,$tot)."</TD></TR>\n";
print "<TR><TD>nullemail:</TD><TD ALIGN='RIGHT'>$nullemails</TD><TD>".&pct($nullemails,$tot)."</TD></TR>\n";
print "</TABLE>\n";
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>";


print "<TR><TD COLSPAN=3>PVI</TD></TR>\n";
print "<TR><TD>\n";
print "<TABLE CELLPADDING=3 BORDER=1>\n";
foreach $o ( @{[ "desc" , "asc" ]} ) {
	$sql = "select pvi,pvi.precinct,count(distinct(mvf$cut.voter_id)) from mvf$cut where pvi.precinct in ( select distinct(precinct) from mvf$cut $w $and pvi.precinct=mvf$cut.precinct) and mvf$cut.precinct=pvi.precinct group by pvi.precinct,pvi.pvi order by pvi $o limit 5";
	$qy = $conn->exec($sql);
	if($o eq "desc") {
		print "<TR><TD COLSPAN=3>Max PVI</TD></TR>\n";
	} else {
		print "<TR><TD COLSPAN=3>Min PVI</TD></TR>\n";
	}
	print "<TR><TD>Precinct</TD><TD>PVI</TD><TD>N Voters</TD></TR>\n";
	while(my(@row) = $qy->fetchrow) {
		$pvix = $row[0];
		$precinct = $row[1];
		$n = $row[2];
		print "<TR><TD ALIGN='RIGHT'>$precinct:</TD><TD ALIGN='RIGHT'>$pvix</TD><TD ALIGN='RIGHT'>$n</TD></TR>";
	}
}
print "</TABLE></TD></TR>\n";

$w = "where ( $where ) " if (length($where));
$sql = "select ten.tenant,count(mvf$cut.voter_id) from mvf$cut $w $and ten.voter_id=mvf$cut.voter_id group by ten.tenant order by count(mvf$cut.voter_id) desc";
$debug && print "$sql\n";
$qy = $conn->exec($sql);
print "<TR><TD>Tenant/Homeowner\n";
$n = 0;
undef(@data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
print "<TR><TD>Tenure</TD><TD>Number</TD><TD>%age</TD></TR>";
while(my(@row) = $qy->fetchrow) {
	$ten = $row[0];
	if($ten eq 't') {
		$ten = "Tenant";
	} else {
		$ten = "Homeowner";
	}
	$count  = $row[1];
	push(@data,"tag$n=$ten");
	push(@data,"val$n=$count");
	$n++;
	next unless($count);
	print "<TR><TD>$ten</TD><TD ALIGN='RIGHT'>$count</TD><TD>".&pct($count,$tot)."</TD></TR>\n";
}
print "</TABLE>\n";
push(@data,"title=Tenant/Homeowner");
push(@data,"type=pie");
$Data = join("&",@data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$Data'></TD></TR>\n";

print "<TR><TD COLSPAN=3>Age:</TD></TR>\n";
print "<TR><TD COLSPAN=2>\n";
$pctot = 0;
$i = 0;
undef(@Data);
print "<TABLE CELLPADDING=3 BORDER=1>\n";
for($a = 18 ; $a <= 108 ; $a += 10 ) {
	$b = $a+10;
	$w = " where ";
	$w = "where ( $where ) " if (length($where));
	$and = " and "  if (length($where));
	$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut  $w $and ((now() - birth_date) >= '$a years' and ((now()-birth_date) < '$b years'))";
	$qy = $conn->exec($sql);
	my(@row) = $qy->fetchrow;
	$n = $row[0];
	push(@Data,"tag$i=$a"."-".$b);
	push(@Data,"val$i=$n");
	$i++;
	print "<TR><TD>$a - $b:</TD><TD>$n</TD><TD>".&pct($n,$tot)."</TD></TR>\n";
}
print "</TABLE>\n";
push(@Data,"type=bar");
push(@Data,"title=Age");
push(@Data,"x=400");
push(@Data,"y=200");
$data = join("&",@Data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$data'></TD></TR>";


print "<TR><TD COLSPAN=3>Registration Age:</TD></TR>\n";
$pctot = 0;
$i = 1;
$n = 0;
$seq = 0;
undef(@Data);
print "<TR><TD COLSPAN=2><TABLE CELLPADDING=3 BORDER=1>\n";
for($a = 0 ; $a <= 40; $a += $i) {
	if($a == 10) {
		$i = 5;
	}
	$b = $a+$i;
	$w = " where ";
	$w = "where ( $where ) " if (length($where));
	$and = " and "  if (length($where));
	$sql = "select count(distinct(mvf$cut.voter_id)) from mvf$cut  $w $and ((now() - reg_date) >= '$a years' and ((now()-reg_date) < '$b years'))";
	$qy = $conn->exec($sql);
	my(@row) = $qy->fetchrow;
	$n = $row[0];
	my $t = "tag$seq=$b";
	push(@Data,$t);
	push(@Data,"val$seq=$n");
	$seq++;
	print "<TR><TD>$a - $b:</TD><TD>$n</TD><TD>".&pct($n,$tot)."</TD></TR>\n";
}
print "</TABLE>\n";
push(@Data,"type=bar");
push(@Data,"x_label=Years+Registered");
push(@Data,"y_label=Number+of+Voters");
push(@Data,"title=Reg+Age");
push(@Data,"x=400");
push(@Data,"y=200");
$data = join("&",@Data);
print "</TD><TD><IMG SRC='http://cybre.net/test/chart.pl?$data'></TD></TR>";

print "<TR><TD COLSPAN=3>Median Age:<br>\n";
$med = ($tot / 2);
$w = " ";
$w = "where ( $where ) " if (length($where));
$and = " and "  if (length($where));
$sql = "select age(birth_date) from mvf$cut  $w $and ( birth_date != '1900-01-01' ) order by age(birth_date) offset $med limit 1";
$debug && print "$sql\n";
$qy = $conn->exec($sql);
my(@row) = $qy->fetchrow;
$n = $row[0];
print "<br>&nbsp; &nbsp; &nbsp; &nbsp; $n<br>\n";

$opts = "<OPTION VALUE='M'>Mail\n<OPTION VALUE='P'>Phone\n<OPTION VALUE='W'>Walk\n<OPTION VALUE='E'>Email<OPTION VALUE='R'>RoboCall";
$opts =~ s/VALUE='$LIST'/SELECTED VALUE='$LIST'/;

if($LIST eq "W") {
undef(@arg);
$arg[1] = "SUP [ ]";
$arg[2] = "SGN [ ]";
$arg[3] = "VOL [ ]";
$arg[4] = "BLDG[ ]";
$arg[5] = "BAD [ ]";
}
if($LIST eq "P") {
undef(@arg);
$arg[1] = "SUP [ ]";
$arg[2] = "UND[ ]";
$arg[3] = "OTH [ ]";
$arg[4] = "BAD [ ]";
$arg[5] = "NH  [ ]";
$arg[6] = "SGN [ ]";
$arg[7] = "VOL [ ]";
}

print <<EOF;
</TD></TR></TABLE>
<FORM ACTION='http://jah.cybre.net/test/do.pl' METHOD='POST'>
<INPUT TYPE='HIDDEN' NAME='where' VALUE="$w">
List Type: <SELECT NAME='type'>
$opts
</SELECT>
<br>
Tag: <INPUT NAME='tag'>
Title: <INPUT NAME='title'>
<br>
Household mail: <INPUT TYPE='CHECKBOX' NAME='hh' CHECKED>
Cleanse lists: <INPUT TYPE='CHECKBOX' NAME='cleanse' CHECKED>
<br>
<table>
<TR><TD>Canv1</TD><TD>Canv2</TD><TD>Canv3</TD><TD>Canv4</TD><TD>Canv5</TD><TD>Canv6</TD><TD>Canv7</TD><TD>Canv8</TD></TR>
<TR><TD><INPUT SIZE=10 NAME='arg1' VALUE='$arg[1]'></TD><TD><INPUT SIZE=10 NAME='arg2' VALUE='$arg[2]'></TD><TD><INPUT SIZE=10 NAME='arg3' VALUE='$arg[3]'></TD><TD><INPUT SIZE=10 NAME='arg4' VALUE='$arg[4]'></TD><TD><INPUT SIZE=10 NAME='arg5' VALUE='$arg[5]'></TD><TD><INPUT SIZE=10 NAME='arg6' VALUE='$arg[6]'></TD><TD><INPUT SIZE=10 NAME='arg7' VALUE='$arg[7]'></TD><TD><INPUT SIZE=10 NAME='arg8' VALUE='$arg[8]'></TR>
</TABLE>
<INPUT type='SUBMIT' name='list'>
<INPUT type='RESET'>
</FORM>
	</BODY></HTML>\n
EOF
} else { 

$eth = "<SELECT SIZE=3 NAME='eths' TITLE='Ethnicity derived from surname' MULTIPLE>\n";
$sql = "select ethnicity,eid from ethnicities";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$eth .= "<OPTION VALUE=$r[1]>$r[0]\n";
}
$eth .= "</SELECT>\n";

$lang = "<SELECT SIZE=3 TITLE='Language derived from birth place and ethnicity' NAME='langs' MULTIPLE>\n";
$sql = "select language,lid from langs";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$lang .= "<OPTION VALUE=$r[1]>$r[0]\n";
}
$lang .= "</SELECT>\n";

$party = "<SELECT SIZE=5 TITLE='Political party registration' NAME='party' MULTIPLE>\n";
$sql = "select distinct(party),count(party) from mvf$cut group by party order by count(party) desc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$r[0] =~ s/\ //g;
$party .= "<OPTION VALUE='$r[0]'>$r[0]: $r[1]\n";
}
$party .= "</SELECT>\n";

$precinct = "<SELECT SIZE=5 TITLE='precinct' NAME='precinct' MULTIPLE>\n";
$sql = "select distinct(precinct),count(precinct) from mvf$cut group by precinct order by precinct asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$r[0] =~ s/\ //g;
$precinct .= "<OPTION VALUE='$r[0]'>$r[0]: $r[1]\n";
}
$precinct .= "</SELECT>\n";

$zip = "<SELECT SIZE=5 TITLE='zip' NAME='zip' MULTIPLE>\n";
$sql = "select distinct(substr(zip,1,5)),count(substr(zip,1,5)) from mvf$cut group by substr(zip,1,5) order by substr(zip,1,5) asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$r[0] =~ s/\ //g;
$zip .= "<OPTION VALUE='$r[0]'>$r[0]: $r[1]\n";
}
$zip .= "</SELECT>\n";


$supv = "<SELECT SIZE=11 NAME='supv' TITLE='Supervisorial District' MULTIPLE>\n";
$sql = "select distinct(supv) from mvf$cut order by supv asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$supv.= "<OPTION VALUE=$r[0]>$r[0]\n";
}
$supv.= "</SELECT>\n";

$cong = "<SELECT SIZE=2 NAME='cong' TITLE='Congressional District' MULTIPLE>\n";
$sql = "select distinct(cong) from mvf$cut order by cong asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$cong.= "<OPTION VALUE=$r[0]>$r[0]\n" if(length $r[0]);
}
$cong.= "</SELECT>\n";

$sen = "<SELECT SIZE=2 NAME='sen' TITLE='State Senate District' MULTIPLE>\n";
$sql = "select distinct(sen) from mvf$cut order by sen asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$sen .= "<OPTION VALUE=$r[0]>$r[0]\n" if(length $r[0]);
}
$sen .= "</SELECT>\n";

$assm = "<SELECT SIZE=2 NAME='assm' TITLE='State Assembly District' MULTIPLE>\n";
$sql = "select distinct(assm) from mvf$cut order by assm asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$assm.= "<OPTION VALUE=$r[0]>$r[0]\n" if(length $r[0]);
}
$assm.= "</SELECT>\n";

$bart = "<SELECT SIZE=2 NAME='bart' TITLE='Bay Area Regional Transit (BART) District' MULTIPLE>\n";
$sql = "select distinct(bart) from mvf$cut order by bart asc";
$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$bart.= "<OPTION VALUE=$r[0]>$r[0]\n" if(length $r[0]);
}
$bart.= "</SELECT>\n";

$bplace = "<SELECT SIZE=3 NAME='bplace' TITLE='Birth Place' MULTIPLE>\n";
$sql = " select bplace,count(bplace),code from bplaces,mvf$cut where code not in ( select st from us ) and bplaces.code=mvf$cut.birth_place group by bplace,code order by count(bplace) desc ";

$qy = $conn->exec($sql);
while(my(@r) = $qy->fetchrow) {
$bplace .= "<OPTION VALUE=$r[2]>$r[0]: $r[1]\n";
}
$supv.= "</SELECT>\n";

$gender = "<SELECT TITLE='Gender' SIZE=2 NAME='gender' MULTIPLE>\n";
$gender .= "<OPTION VALUE='F'>Female\n";
$gender .= "<OPTION VALUE='M'>Male\n";
$gender .= "<OPTION VALUE='O'>Other\n";
$gender .= "</SELECT>\n";


$perm = "<SELECT TITLE='Vote By Mail (perm absentee) or Election DAY' SIZE=2 NAME='perm'>\n";
$perm .= "<OPTION VALUE='Y'>VBM\n";
$perm .= "<OPTION VALUE='N'>EDAY\n";
$perm .= "</SELECT>\n";

$hist =  "<p>Voting History\n";
$hist .= "<br>06 Jun 2006";
$hist .= "<INPUT TYPE='CHECKBOX' ' NAME='hist' VALUE='e060606:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e060606:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e060606:N'>No";
$hist .= "<br>\n";
$hist .= "08 Nov  2005";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e051108:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e051108:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e051108:N'>No";
$hist .= "<br>\n";
$hist .= "02 Nov  2004";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e041102:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e041102:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e041102:N'>No";
$hist .= "<br>\n";
$hist .= "02 Mar  2004";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e040302:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e040302:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e040302:N'>No";
$hist .= "<br>\n";
$hist .= "09 Dec  2003";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031209:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031209:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031209:N'>No";
$hist .= "<br>\n";
$hist .= "04 Nov  2003";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031104:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031104:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031104:N'>No";
$hist .= "<br>\n";
$hist .= "07 Oct  2003";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031007:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031007:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e031007:N'>No";
$hist .= "<br>\n";
$hist .= "10 Dec  2002";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021210:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021210:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021210:N'>No";
$hist .= "<br>\n";
$hist .= "05 Nov  2002";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021105:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021105:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e021105:N'>No";
$hist .= "<br>\n";
$hist .= "05 Mar  2002";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e020305:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e020305:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e020305:N'>No";
$hist .= "<br>\n";
$hist .= "11 Dec  2001";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011211:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011211:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011211:N'>No";
$hist .= "<br>\n";
$hist .= "06 Nov  2001";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011106:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011106:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e011106:N'>No";
$hist .= "<br>\n";
$hist .= "12 Dec  2000";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001212:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001212:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001212:N'>No";
$hist .= "<br>\n";
$hist .= "07 Nov  2000";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001107:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001107:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e001107:N'>No";
$hist .= "<br>\n";
$hist .= "07 Mar  2000";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e000307:V'>Eday";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e000307:A'>VBM";
$hist .= "<INPUT TYPE='CHECKBOX'  NAME='hist' VALUE='e000307:N'>No";
$hist .= "<br>\n";

$ten = "<SELECT NAME='ten' SIZE='2'>\n";
$ten .= "<OPTION VALUE='t'>Tenant\n";
$ten .= "<OPTION VALUE='f'>Homeowner\n";
$ten .= "</SELECT>\n";

$email = "<SELECT NAME='email' SIZE='2'>\n";
$email .= "<OPTION VALUE='A'>all\n";
$email .= "<OPTION VALUE='E'>email\n";
$email .= "<OPTION VALUE='N'>null\n";
$email .= "</SELECT>\n";

$histbool = "<SELECT TITLE='All = AND together voting history, Any = OR them' SIZE=2 NAME='histbool'>\n";
$histbool .= "<OPTION VALUE='AND'>All";
$histbool .= "<OPTION SELECTED VALUE='OR'>Any";
$histbool .= "</SELECT>";

$listtype = "<SELECT SIZE=2 TITLE='List Type' NAME='list'>\n";
$listtype .= "<OPTION VALUE='W'>WALK<br>\n<OPTION VALUE='P'>Phone<OPTION VALUE='M'>Mail\n<OPTION VALUE='E'>Email\n<OPTION VALUE='M'>Mail\n<OPTION VALUE='R'>RoboCall\n";
$listtype .= "</SELECT>";
$listtype =~ s/VALUE='$LIST'/SELECTED VALUE='$LIST'/;
print<<EOF;
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>
Demographic Query
</TITLE>
</HEAD>
<FORM METHOD="GET" ACTION="poll.pl">
<TABLE>
<TR>
<TD>Language:<br> $lang</TD>
<TD>Ethnicity:<br> $eth</TD>
<TD>Birth Place:<br> $bplace</TD>
<TD>Gender:<br> $gender</TD>
</TR>
<TR>
<TD>Supe District:<br> $supv</TD>
<TD>
<TABLE>
<TR><TD>Cong District:</TD><TD ALIGN='RIGHT'>$cong</TD></TR>
<TR><TD>Assm District:</TD><TD ALIGN='RIGHT'>$assm</TD></TR>
<TR><TD>Sen  District:</TD><TD ALIGN='RIGHT'>$sen</TD></TR>
<TR><TD>BART District:</TD><TD ALIGN='RIGHT'>$bart</TD></TR>
</TABLE>
</TD>
<TD>
<TABLE>
<TR><TD ALIGN='CENTER'>Min</TD><TD></TD><TD ALIGN='CENTER'>Max</TD></TR>
<TR> <TD ALIGN='CENTER'><INPUT TITLE='Minimum voter age' SIZE=5 NAME='agemin'></TD><TD ALIGN='CENTER'>&gt; Age &lt;</TD><TD ALIGN='CENTER'><INPUT SIZE=5 TITLE='Maximum voter age' NAME='agemax'></TD></TR>
<TR><TD ALIGN='CENTER'><INPUT TITLE='Minimum Progressive Voter Index by precinct' SIZE=5 NAME='pvimin'></TD><TD ALIGN='CENTER'>&gt; PVI &lt;</TD><TD ALIGN='CENTER'><INPUT TITLE='Maximum Progressive Voter Index by precinct' SIZE=5 NAME='pvimax'> </TD></TR>
<TR><TD ALIGN='CENTER'><INPUT TITLE='Minimum median income by precinct' SIZE=5 NAME='medmin'></TD><TD ALIGN='CENTER'>&gt; \$MI &lt;</TD><TD ALIGN='CENTER'><INPUT TITLE='Maximum median income by precinct' SIZE=5 NAME='medmax'> </TD></TR>
<TR><TD ALIGN='CENTER'>Min</TD><TD ALIGN='CENTER'></TD><TD ALIGN='CENTER'>Max</TD></TR>
</TABLE>
<TD>Party:<br> $party</TD>
</TR>
<TR>
<TD COLSPAN=2>
<TABLE>
<TR>
<TD>
Absentee:
</TD><TD>
$perm
</TD>
<TR>
<TD>
Tenant/Homeowner:
</TD>
<TD>
$ten
</TD></TR>
<TR>
<TD>Email:
</TD>
<TD>
$email
</TD>
</TR>
<TR>
<TD>
List Type:
</TD>
<TD>
$listtype
</TD>
</TR>
</TABLE>
</TD>
<TD>$hist</TD>
<TD ALIGN='TOP'>History<br>Boolean<br>$histbool</TD>
</TR>
<TR>
<TD COLSPAN=3>
Yr <INPUT TITLE='Minimum Years since registration change' SIZE=5 NAME='regageminyr'>  Mo <INPUT TITLE='Minimum Months since registration change' SIZE=5 NAME='regageminmo'> &gt; Reg Age &lt; Yr <INPUT SIZE=5 TITLE='Maximum Years since registration change' NAME='regagemaxyr'> Mo <INPUT TITLE='Maximum Months since registration change' SIZE=5 NAME='regagemaxmo'>
<P>
Include:
<SELECT SIZE=5 NAME='inc_canvs' MULTIPLE>
<OPTION VALUE=1>SUP
<OPTION VALUE=2>AGN
<OPTION VALUE=3>UND
<OPTION VALUE=4>DNC
<OPTION VALUE=5>BAD#
<OPTION VALUE=sgn>Sign
<OPTION VALUE=vol>Volunteer
<OPTION VALUE=vbm>VBM
<OPTION VALUE=msg>Left Message
<OPTION VALUE=gotv:1>GOTV1
<OPTION VALUE=gotv:2>GOTV2
<OPTION VALUE=gotv:3>GOTV3
<OPTION VALUE=bad:1>No Address
<OPTION VALUE=bad:2>No Access
<OPTION VALUE=voted>Voted
</SELECT>
Exclude:
<SELECT SIZE=5 NAME='exc_canvs' MULTIPLE>
<OPTION VALUE=1>SUP
<OPTION VALUE=2>AGN
<OPTION VALUE=3>UND
<OPTION VALUE=4>DNC
<OPTION VALUE=5>BAD#
<OPTION VALUE=sgn>Sign
<OPTION VALUE=vol>Volunteer
<OPTION VALUE=vbm>VBM
<OPTION VALUE=msg>Left Message
<OPTION VALUE=gotv:1>GOTV1
<OPTION VALUE=gotv:2>GOTV2
<OPTION VALUE=gotv:3>GOTV3
<OPTION VALUE=bad:1>No Address
<OPTION VALUE=bad:2>No Access
<OPTION VALUE=voted>Voted
</SELECT>
</TD>
<TD>Precinct<br>$precinct<br>Zip 5<br>$zip</TD>
</TR>
</TABLE>
<br>
<INPUT type='SUBMIT' TITLE='Do Query'>
<br>
<INPUT type='RESET'>
</FORM>
<br>
</HTML>
EOF
}

sub pct {
	my($a) = shift;
	my($b) = shift;
	my($pct) = 100.0 * (1.0*$a)/(1.0*$b);
	if($pct == 100) {
		return("100%");
	} else {
		return(substr($pct,0,index($pct,'.')+3)."%");
	}
}
