#!/usr/bin/perl
require '../db.pl';
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                                
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
	print "<HTML><HEAD><TITLE>Campaign</TITLE></HEAD><HTML><BODY>\n";
	(@elts) = split("\&",$QUERY_STRING);
	foreach (@elts) {
		($tag,$val) = split("\=");
		$Elts{$tag} = $val;
	}
	foreach $tag ( keys %Elts ) {
		$val = $Elts{$tag};
		print "$tag: $val\n";
	}
	if($Elts{ACTION} eq 'EDIT') {
		&edit(%Elts);
	}
	if($Elts{'ACTION'} eq 'CREATE') {
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
	$cmpid = $Elts{cmp};
	$conf = $Elts{CONFIRM};
	if($conf) {
		$sql = "delete from cmp where cmpid='$cmpid'";
		print "<br>$sql<br>\n";
		print "<br>$conf<br>\n";
		$sth = $conn->exec($sql);
	} else {
		$msg = "not confirmed\n";
	}
	&genform;
}
sub	create {
	my($Elts) = %_;
	$cmp = $Elts{NAME};
	$ele = $Elts{ele};
	if($cmp =~ /^[\s]*$/) {
		$msg = "please specify a campaign code";
	} else {
		$sql = "select count(cmpid) from cmp where campaign='$cmp'";
		$sth = $conn->exec($sql);
		my(@row) = $sth->fetchrow;
		if(!$row[0]) {
			  $sql = "insert into cmp (campaign,eleid) values ('$cmp',$ele)";
			  $dbh = $conn->exec($sql);
			  open(TMP,">/tmp/foo");
			  print TMP $sql;
		}
		$sql = "select edate from ele where eleid=$ele";
		$sth = $conn->exec($sql);
		my(@row) = $sth->fetchrow;
		$edate = $row[0];
		$msg = "campaign $cmp created for election $edate";
	}
	&genform;
}

sub	genEditform	{

}
sub	genDelpage{

}

sub	genform	{
$sql = "select eleid from ele where ((edate-CURRENT_DATE) > 0) order by (edate-CURRENT_DATE)";
$sth = $conn->exec($sql);
my(@row) = $sth->fetchrow;
$defeleid = $row[0];
$sql = "select distinct(eleid),edate from ele";
$sth = $conn->exec($sql);
$edatesel .= "<TR>\n";
$edatesel .= "<TD>Election Date:</TD><TD> <SELECT NAME='ele'>\n";
while(my(@row) = $sth->fetchrow) {
	my($eleid) = $row[0];
	my($edate) = $row[1];
	if($eleid == $defeleid) {
		$selected = "SELECTED";
	} else {
		undef($selected);
	}
	$edatesel .= "<OPTION VALUE='$eleid' $selected>$edate\n";
}
$edatesel .= "</SELECT>\n";
$edatesel .= "</TD></TR>\n";
$sql = "select distinct(cmpid),campaign from cmp";
$sth = $conn->exec($sql);
if($sth) {
	$cmpdel = "<TR>";
	$cmpdel .= "<FORM ACTION='/elect/camp.pl' METHOD='POST'>\n";
	$cmpdel .= "<TD><SELECT NAME='cmp'>\n";
	while(my(@row) = $sth->fetchrow) {
		my($cmpid) = $row[0];
		my($campaign) = $row[1];
		$cmpdel .= "<OPTION VALUE='$cmpid'>$campaign</A>\n"
	}
	$cmpdel .= "</SELECT></TD>";
	$cmpdel .= "<TD>Campaign Code:</TD><TD><INPUT TYPE='SUBMIT' VALUE='DELETE' NAME='ACTION' ></TD>\n";
	$cmpdel .= "</FORM></TR><TR><TD COLSPAN=3><HR></TD></TR>\n";
} else {
	$cmpdel = "";
}
$cmpedit = $cmpdel;
$cmpedit =~ s/DELETE/EDIT/g;
$cmpdelconf = "<TD>Confirm delete:<INPUT TYPE='CHECKBOX' NAME='CONFIRM' VALUE='CONFIRM'></TD>\n";
$cmpdel =~ s#</FORM>#$cmpdelconf</FORM>#;
print << "EOF";
<HTML>
<HEAD><TITLE>Campaign Editor</TITLE></HEAD>
<BODY>
<H2>Campaign Editor</H2>
$msg
<br>
$db->{err}
<br>
<TABLE>
<TR><TD COLSPAN=3><HR></TD></TR>
$cmpedit
<FORM ACTION='/elect/camp.pl' METHOD='POST'>
$edatesel
<TR>
<TD>Campaign Code:</TD><TD><INPUT NAME='NAME' SIZE='16'></TD>
<TD><INPUT TYPE='SUBMIT' VALUE='CREATE' NAME='ACTION'></TD>
</TR>
<TR><TD COLSPAN=3><HR></TD></TR>
</FORM>
$cmpdel
EOF
}
