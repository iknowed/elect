#!/usr/local/bin/perl
$ENV{PGUSER}='elect';
use DBI;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                                
$e = Elect->new();
$db = $e->{db};
$db->connect();
print <<EOF;
Content-Type: text/html


EOF

if($ENV{REQUEST_METHOD} eq "GET") {
	$QUERY_STRING = $ENV{QUERY_STRING};
}
if(($ENV{REQUEST_METHOD} eq "POST") && $ENV{CONTENT_LENGTH}) {
	while(<>) {
		$QUERY_STRING .= $_;
	}
}

if(!length($QUERY_STRING)) {
&genform;
} else {
	print "<HTML><HEAD><TITLE>Create Phonelist</TITLE></HEAD><HTML><BODY>\n";
	print "$QUERY_STRING<br>\n";
	(@elts) = split("\&",$QUERY_STRING);
	foreach (@elts) {
		($tag,$val) = split("\=");
		$Elts{$tag} = $val;
	}
	foreach $tag ( keys %Elts ) {
		$val = $Elts{$tag};
		print "$tag: $val\n";
	}
	print $Elts{ACTION} eq 'CREATE';
	if($Elts{ACTION} eq 'CREATE') {
		&create(%Elts);
	}
	if($Elts{ACTION} eq 'DELETE') {
		&delete(%Elts);
	}
	print "</BODY></HTML>\n	";
}

sub	edit	{
	my($Elts) = %_;
}
sub	delete {
	my($Elts) = %_;
	$eleid = $Elts{ele};
	$conf = $Elts{CONFIRM};
	if($conf) {
		$sql = "delete from ele where eleid='$eleid'";
		print "<br>$sql<br>\n";
		print "<br>$conf<br>\n";
		$sth = $db->do($sql);
	} else {
		$msg = "not confirmed\n";
	}
	&genform;
}
sub	create {
	my($Elts) = %_;
	$eyr = $Elts{YEAR};
	$emo = $Elts{MONTH};
	$eda = $Elts{DATE};
	$ele = "$eyr" . "-" . "$emo" . "-" . "$eda";
	$msg = "create $ele";
	$sql = "select count(eleid) from ele where edate='$ele'";
	$sth = $db->do($sql);
	my(@row) = $sth->fetchrow;
	if(!$row[0]) {
		$sql = "insert into ele (edate) values ('$ele')";
		$dbh = $db->do($sql);
	}
	&genform;
}

sub	genEditform	{

}
sub	genDelpage{

}

sub	genform	{
$sql = "select distinct(eleid),edate from ele";
$sth = $db->do($sql);
if($sth) {
	$eledel = "<TR>";
	$eledel .= "<FORM ACTION='/elect/ele.pl' METHOD='POST'>\n";
	$eledel .= "<TD><SELECT NAME='ele'>\n";
	while(my(@row) = $sth->fetchrow) {
		my($eleid) = $row[0];
		my($edate) = $row[1];
		$eledel .= "<OPTION VALUE='$eleid'>$edate</A>\n"
	}
	$eledel .= "</SELECT></TD>";
	$eledel .= "<TD><INPUT TYPE='SUBMIT' VALUE='DELETE' NAME='ACTION' ></TD>\n";
	$eledel .= "</FORM>\n";
} else {
	$eledel = "";
}
#$eleedit = $eledel;
#$eleedit =~ s/DELETE/EDIT/g;
$eledelconf = "<TD>Confirm delete:<INPUT TYPE='CHECKBOX' NAME='CONFIRM' VALUE='CONFIRM'></TD>\n";
$eledel =~ s#</FORM>#$eledelconf</FORM>#;
print << "EOF";
<HTML>
<HEAD><TITLE>Election Editor</TITLE></HEAD>
<BODY>
<H2>Election Editor</H2>
<hr>
$msg
<br>
$db->{err}
<br>
<TABLE>
$eleedit
<TR>
<FORM ACTION='/elect/ele.pl' METHOD='POST'>
<TD>
<SELECT NAME='YEAR'>
<OPTION>2004
<OPTION>2005
<OPTION>2006
</SELECT>
<SELECT NAME='MONTH'>
<OPTION>01
<OPTION>02
<OPTION>03
<OPTION>04
<OPTION>05
<OPTION>06
<OPTION>07
<OPTION>08
<OPTION>09
<OPTION>10
<OPTION>11
<OPTION>12
</SELECT>
<SELECT NAME='DATE'>
<OPTION>01
<OPTION>02
<OPTION>03
<OPTION>04
<OPTION>05
<OPTION>06
<OPTION>07
<OPTION>08
<OPTION>09
<OPTION>10
<OPTION>11
<OPTION>12
<OPTION>13
<OPTION>14
<OPTION>15
<OPTION>16
<OPTION>17
<OPTION>18
<OPTION>19
<OPTION>20
<OPTION>21
<OPTION>22
<OPTION>23
<OPTION>24
<OPTION>25
<OPTION>26
<OPTION>27
<OPTION>28
<OPTION>29
<OPTION>30
<OPTION>31
</SELECT>
<TD><INPUT TYPE='SUBMIT' VALUE='CREATE' NAME='ACTION'></TD>
</FORM>
$eledel
EOF
}
