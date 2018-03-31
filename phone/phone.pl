#!/usr/bin/perl
require '../db.pl';
use URI::Escape;
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
	$QUERY_STRING =~ s/\+/ /g;
	(@elts) = split("\&",$QUERY_STRING);
	foreach (@elts) {
		($tag,$val) = split("\=");
		$Elts{$tag} = uri_unescape($val);
		#print "$tag: $Elts{$tag}<br>\n";
	}
	foreach $tag ( keys %Elts ) {
		$val = $Elts{$tag};
		#print "$tag: $val\n";
	}
	if($Elts{'ACTION'} eq 'CREATE') {
		&create(%Elts);
	}
	if($Elts{'ACTION'} eq 'DELETE') {
		&delete(%Elts);
	}
	if($Elts{'ACTION'} eq 'POPULATE') {
		&populate(%Elts);
	}
	print "</BODY></HTML>\n	";
}

sub	populate	{
	my($Elts) = %_;

	print "<HTML><HEAD><TITLE>Campaign</TITLE></HEAD><HTML><BODY>\n";
	$phid = $Elts{phid};

	$sql = "select query,phone.cmpid,cmp.campaign,phonelist from phone,cmp where phone.cmpid=cmp.cmpid and phid=$phid ";
	$sth = $conn->exec($sql);
	my(@row) = $sth->fetchrow;
	$query = $row[0];
	$cmpid = $row[1];
	$campaign = $row[2];
	$phonelist = $row[3];
	$phonetbl = $campaign."_".$phonelist;

	$sql = "drop table $phonetbl";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "select voter_id into $phonetbl from mvf where ($query and phone is not null and phone > 1000000)";
	open(FOO,">/tmp/foo");
	print FOO $sql;
	close FOO;
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "alter table $phonetbl add column stat int";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "alter table $phonetbl add column stamp bigint";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "alter table $phonetbl add constraint status foreign key (stat) references pstat(pstatid)";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "create index $phonetbl_voter_id_ix on $phonetbl(voter_id)";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "create index $phonetbl_stat_ix on $phonetbl(stat)";
	$sth = $conn->exec($sql);
	$msg = $db->{err};
	$sql = "select pstatid from pstat where type='UNL'";
	$sth = $conn->exec($sql);
	my(@row) = $sth->fetchrow;
	$pstatid = $row[0];
	$msg = $db->{err};

	$sql = "update $phonetbl set stat=$pstatid";
	$sth = $conn->exec($sql);
	$msg = $db->{err};

	$sql = "select count(*) from $phonetbl";
	$sth = $conn->exec($sql);
	my(@row) = $sth->fetchrow;
	$n = $row[0];
	$msg = "populated table $phonetbl with query $query, $n voters<br>";
	&genform;
}

sub	delete {
	my($Elts) = %_;
	$query = $Elts{query} ;
	$query =~ s/'/\\'/g;
	$phid = $Elts{phid};
	$phonelist = $Elts{phonelist};
	$title = $Elts{title};
	undef($msg);
	if($phid =~ /^[\s]*$/) {
		$msg .= "please specify a phid<br>";
	} 
	if(!length($msg)) {
		$sql = "begin transaction";
		$sth = $conn->exec($sql);
		$msg .= "$db->{err}\n";
		$sql = "lock table phone";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$sql = "delete from phone where phid='$phid' ";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$sql = "end transaction";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$msg = "phone $phid deleted for phonecode $phone_code cmp $cmp query $sqy" unless $msg;
	}
	&genform;
}

sub	create {
	my($Elts) = %_;
	$query = $Elts{query} ;
	$query =~ s/'/\\'/g;
	$cmpid = $Elts{cmpid};
	$phonelist = $Elts{phonelist};
	$title = $Elts{title};
	undef($msg);
	if($cmpid =~ /^[\s]*$/) {
		$msg .= "please specify a campaign code<br>";
	} 
	if($query =~ /^[\s]*$/) {
		$msg .= "please specify a query<br>";
	} 
	if($phonelist =~ /^[\s]*$/) {
		$msg .= "please specify a phone code<br>";
	}
	if(!length($msg)) {
		$sql = "begin transaction";
		$sth = $conn->exec($sql);
		$msg .= "$db->{err}\n";
		$sql = "lock table phone";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		#$sql = "insert into phone values (\"". qq{$sqy} ."\",$cmp,$phone_code) (query,cmp,phone_code) ";
		$sql = "insert into phone (query,cmpid,phonelist,title) values ('$query',$cmpid,'$phonelist','$title') ";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$sql = "select max(phid) from phone";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		(@row) = $sth->fetchrow if $sth;
		$phid = $row[0];
		#$sql = "unlock table phone";
		#$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$sql = "end transaction";
		$sth = $conn->exec($sql); 
		$msg .= "$db->{err}\n";
		$msg = "phone $phid created for phonecode $phone_code cmp $cmp query $sqy" unless $msg;
	}
	&genform;
}

sub	genEditform	{

}
sub	genDelpage{

}

sub	genform	{
$sql = "select distinct(cmpid),campaign from cmp where (cmp.eleid=ele.eleid and ((ele.edate-CURRENT_DATE) > 0))";
$sth = $conn->exec($sql);
if($sth) {
	$cmpsel= "<TR>";
	$cmpsel .= "<TD>Campaign:</TD><TD><SELECT NAME='cmpid'>\n";
	while(my(@row) = $sth->fetchrow) {
		my($cmpid) = $row[0];
		my($campaign) = $row[1];
		$cmpsel .= "<OPTION VALUE='$cmpid'>$campaign\n"
	}
	$cmpsel .= "</SELECT></TD>";

} else {
	$cmpsel = "";
}
$sql = "select distinct(phid),phonelist,title,phone.cmpid,campaign from phone,cmp where phone.cmpid=cmp.cmpid";
$sth = $conn->exec($sql);
if($sth) {
$gensel = "<TR><TD>Phonelist:</TD><TD><SELECT NAME='phid'>\n";
while(my(@row) = $sth->fetchrow()) {
	$phid = $row[0];
	$phonelist=$row[1];
	$title=$row[2];
	$cmpid=$row[3];
	$campaign=$row[4];
	$gensel .= "<OPTION VALUE=$phid>$campaign $title\n";
}
$gensel .= "</SELECT></TD></TR>";
}
print << "EOF";
<HTML>
<HEAD><TITLE>Phonelists</TITLE></HEAD>
<BODY>
<H2>Phonelist Editor</H2>
$msg
<br>
$db->{err}
<br>
<TABLE>
<TR><TD COLSPAN=3><HR></TD></TR>
<FORM ACTION='/elect/phone.pl' METHOD='GET'>
$cmpsel
<TR><TD>Phonelist Code</TD><TD><INPUT NAME='phonelist'></TR>
<TR><TD>Phonelist Title</TD><TD><INPUT NAME='title' SIZE=72></TR>
<TR><TD>Query:</TD><TR>
<TR><TD COLSPAN=3><TEXTAREA NAME='query' ROWS=10 COLS=72></TEXTAREA></TD></TR>
<TR><TD><INPUT TYPE='SUBMIT' VALUE='CREATE' NAME='ACTION' >
</TD></TR>
</FORM>
<TR><TD COLSPAN=3><HR></TD></TR>
<FORM ACTION='/elect/phone.pl' METHOD='GET'>
$gensel
<TR><TD><INPUT TYPE='SUBMIT' VALUE='POPULATE' NAME='ACTION' >
<INPUT TYPE='SUBMIT' VALUE='DELETE' NAME='ACTION'>
</FORM>
</TD></TR>
EOF
}
