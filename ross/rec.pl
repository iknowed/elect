#!/usr/local/bin/perl

#  option to declare SECOND!!!
#  Absentee PERM

$ENV{PGUSER}='elect';
use DBI;
use URI::Escape;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                                
$e = Elect->new();
$db = $e->{db};
$db->connect();
print <<"EOF";
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
	$Elts{USR} = $ENV{REMOTE_USER};
	$Elts{IP} = $ENV{REMOTE_ADDR};
	if($Elts{'ACTION'} eq 'PHONE') {
		&phone(%Elts);
	}
	if($Elts{'ACTION'} eq 'NEXT') {
		&next(%Elts);
	}
	if($Elts{'ACTION'} eq 'TIMEOUT') {
		&timeout(%Elts);
		&next(%Elts);
	}
	print "</BODY></HTML>\n	";
}

sub	timeout	{
	my($Elts) = %_;
	$voter_id = $Elts{voter_id};
	$phid = $Elts{phid};
	$cmpid = $Elts{cmpid};
	$phonetable = &getPhoneTable($phid,$cmpid);
	&beginTrans;
	&lockTable($phonetable);
	if(&isLocked($voter_id,$phonetable)) {
		&unlockVoter($voter_id,$phonetable);
	}
}

sub	getPhoneTable {
	my($phid,$cmpid) = @_;
	$phonelist = &getPhoneList($phid);
	$campaign = &getCampaign($cmpid);
	return($campaign. "_" .$phonelist);
}

sub	getCampaign {
	my($cmpid) = shift;

	$sql = "select campaign from cmp where cmpid=$cmpid";
	$sth = $db->do($sql);
	$msg .= $db->{ERR};
	if($sth) {
		my(@row) = $sth->fetchrow;
		$campaign= $row[0];
	}
	return($campaign);
}
sub	getPhoneList	{
	my($phid) = shift;

	$sql = "select phonelist from phone where phid=$phid";
	$sth = $db->do($sql);
	$msg .= $db->{ERR};
	if($sth) {
		my(@row) = $sth->fetchrow;
		$phonelist = $row[0];
	}
	return($phonelist);
}
sub	lockTable	{
	my($table) = shift;

	$sql = "lock table $table";
	$sth = $db->do($sql);
	return($db->{ERR});
}

sub	beginTrans	{
	$sql = "begin transaction";
	$sth = $db->do($sql);
	return($db->{ERR});
}
sub	endTrans	{
	$sql = "end transaction";
	$sth = $db->do($sql);
	return($db->{ERR});
}

sub	getidtypeID	{
	my($type) = shift;

	$sql = "select idtid from idtypes where type='$type'";
	$sth = $db->do($sql);
	$msg .= $db->{err};
	if($sth) {
		my(@row) = $sth->fetchrow;
		$id = $row[0];
	}
	return($id);
}
sub	getpstatID	{
	my($type) = shift;

	$sql = "select pstatid from pstat where type='$type'";
	$sth = $db->do($sql);
	$msg .= $db->{err};
	if($sth) {
		my(@row) = $sth->fetchrow;
		$id = $row[0];
	}
	return($id);
}
sub	isLocked	{
	my($voter_id,$phonetbl) = @_;

	$lok = getpstatID('LOK');

	$sql = "select stat from $phonetbl where voter_id = $voter_id";
	$sth = $db->do($sql);
	$msg .= $db->{err};
	my(@row) = $sth->fetchrow;
	$stat = $row[0];
	return($stat == $lok);
}
sub	isUnLocked	{
	my($voter_id,$phonetbl) = @_;

	$unl = getpstatID('UNL');

	$sql = "select stat from $phonetbl where voter_id = $voter_id";
	$sth = $db->do($sql);
	$msg .= $db->{err};
	my(@row) = $sth->fetchrow;
	$stat = $row[0];
	return($stat == $unl);
}
sub	isFinished	{
	my($voter_id,$phonetbl) = @_;

	$fin = getpstatID('FIN');

	$sql = "select stat from $phonetbl where voter_id = $voter_id";
	$sth = $db->do($sql);
	$msg .= $db->{err};
	my(@row) = $sth->fetchrow;
	$stat = $row[0];
	return($stat == $fin);
}

sub	lockVoter	{
	my($voter_id,$phonetbl) = @_;
	$lok = getpstatID('LOK');
	$t = time;
	$sql = "update $phonetbl set stat=$lok , stamp=$t where voter_id=$voter_id";
	$sth = $db->do($sql);
	return($db->{err});
}

sub	unlockVoter	{
	my($voter_id,$phonetbl) = @_;
	$unl = getpstatID('UNL');
	$t = time;
	$sql = "update $phonetbl set stat=$unl, stamp=$t where voter_id=$voter_id";
	$sth = $db->do($sql);
	return($db->{err});
}

sub	finVoter	{
	my($voter_id,$phonetbl) = @_;
	$fin = getpstatID('FIN');
	$t = time;
	$sql = "update $phonetbl set stat=$fin, stamp=$t where voter_id=$voter_id";
	$sth = $db->do($sql);
	return($db->{err});
}

sub	doCanv	{
	my($Elts) = $_;
	$sup = $Elts{SUP};	
	$sgn = length($Elts{SGN}) ? 1 : 0;
	$vol = length($Elts{VOL}) ? 1 : 0;
	$hpty = length($Elts{HPTY}) ? 1 : 0;
	$bldg = length($Elts{BLDG}) ? 1 : 0;
	$msg = length($Elts{MSG}) ? 1 : 0;
	$bak = length($Elts{BAK}) ? 1 : 0;
	$bad = length($Elts{BAD}) ? 1 : 0;
	$dnc = length($Elts{DNC}) ? 1 : 0;
	$ded = length($Elts{DED}) ? 1 : 0;
	$usr = $Elts{USR};
	$ip  = $Elts{IP};
	$lid = $Elts{lang};
	$notes = $Elts{NOTES};
	$idtype = getidtypeID($sup);
	#if(length($idtype) ||
	#	length($sgn) ||
	#	length($vol) ||
	#	length($msg) ||
	#	length($bak) ||
	#	length($bldg) ||
	#	length($hpty) ||
	#	length($cmpid) ||
	#	length($notes)) {
			$sql = "insert into canv (sup,sgn,vol,msg,bak,bldg,hpty,cmpid,notes,usr,ip,stamp,voter_id) values ($idtype,$sgn,$vol,$msg,$bak,$bldg,$hpty,$cmpid,\'$notes\',\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
			$sth = $db->do($sql);
			$msg .= $db->{err};
	#}
}

sub	doExt	{
	my($Elts) = $_;
	$voter_id = $Elts{voter_id};	
	$bad = length($Elts{BAD}) ? 1 : 0;
	$dnc = length($Elts{DNC}) ? 1 : 0;
	$ded = length($Elts{DED}) ? 1 : 0;
	$usr = $Elts{USR};
	$ip  = $Elts{IP};
	$lid = $Elts{lang};
	$notes = $Elts{NOTES};

	#if((length($lid) && $lid != 1) || 
	#	length($bad) || 
	#	length($dnc) || 
	#	length($ded)) {
			$sql = "insert into ext (lid,bad,dnc,ded,usr,ip,stamp,voter_id) values ($lid,$bad,$dnc,$ded,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
			$sth = $db->do($sql);
			$msg .= $db->{err};
	#}

}
sub	next	{
	my($Elts) = %_;
	$voter_id = $Elts{voter_id};	

	$cmpid = $Elts{cmpid};	
	$phid = $Elts{phid};	
	$sup = $Elts{SUP};	
	$sgn = length($Elts{SGN}) ? 1 : 0;
	$vol = length($Elts{VOL}) ? 1 : 0;
	$hpty = length($Elts{HPTY}) ? 1 : 0;
	$bldg = length($Elts{BLDG}) ? 1 : 0;
	$msg = length($Elts{MSG}) ? 1 : 0;
	$bad = length($Elts{BAD}) ? 1 : 0;
	$dnc = length($Elts{DNC}) ? 1 : 0;
	$ded = length($Elts{DED}) ? 1 : 0;
	$lid = $Elts{lang};
	$notes = $Elts{NOTES};

	&beginTrans;
	&lockTable("canv");
	&lockTable("ext");

	$campaign = getCampaign($cmpid);
	$phonelist = &getPhoneList($phid);
	$phonetable = &getPhoneTable($phid,$cmpid);
	if(&isLocked($voter_id,$phonetable)) {
		&lockTable($phonetable);
		&doCanv(%Elts);
		&doExt(%Elts);
	}
	$fin = getpstatID('FIN');
	&finVoter($voter_id,$phonetable);
	&endTrans;

	&phone(%Elts);
}

sub	phone {
	my($Elts) = %_;
	$ok = 0;
	#print "<HTML><HEAD><TITLE>PhoneList</TITLE></HEAD><HTML><BODY OnLoad="timeIt()">\n";
	$phid = $Elts{phid};

	$sql = "select campaign,phonelist,cmp.cmpid from phone,cmp where phone.cmpid=cmp.cmpid and phid=$phid";
	$sth = $db->do($sql);
	my(@row) = $sth->fetchrow;
	$cmp= $row[0];
	$phonelist = $row[1];
	$cmpid = $row[2];
	$phonetbl = $cmp."_".$phonelist;
	&beginTrans;
	&lockTable($phonetbl);

	$sql = "select count(voter_id) from $phonetbl,pstat where ($phonetbl.stat=pstat.pstatid and pstat.type='UNL')";
	$sth = $db->do($sql);
	my(@row) = $sth->fetchrow;
	$cnt = $row[0];
	if($cnt) {
		$sql = "select voter_id from $phonetbl,pstat where ($phonetbl.stat=pstat.pstatid and pstat.type='UNL')";
		$sth = $db->do($sql);
		my(@row) = $sth->fetchrow;
		$voter_id = $row[0];

		if($voter_id) {
			$lok = getpstatID('LOK');
			&lockVoter($voter_id,$phonetbl);
			&endTrans;

			$sql = "select name_first,name_last,phone,birth_place,house_number,street,party,age(birth_date),voter_id,perm from mvf where voter_id=$voter_id";
			$sth = $db->do($sql);
			$msg .= $db->{err};
			my(@row) = $sth->fetchrow;

			$street = $row[5];
			$house = $row[4];
			$sql = "select count(*) from mvf where street='$street' and house_number='$house'";
			$sth = $db->do($sql);
			$msg .= $db->{err};
			my(@r) = $sth->fetchrow;
			$n = $r[0];
			push(@row,$n);

			$ok = 1;
			&genphonePG(@row);
		} else {
			$msg = "can't find voter_id\n";
		}
	} else {
			$msg = "no more voters left in this phonelist\n";
	}
	&endTrans;
	if(!$ok) {	
		&genform;
	}
}

sub	genphonePG	{
	my(@voter) = @_;
	$fname = shift(@voter);
	$lname = shift(@voter);
	$phone = shift(@voter);
	$phone = substr($phone,0,3) . "-" . substr($phone,3,4);
	$bplace = shift(@voter);
	$hnum  = shift(@voter);
	$street = shift(@voter);
	$party = shift(@voter);
	@age = split(/\ /,shift(@voter));
	$voter_id = shift(@voter);
	$perm = shift(@voter);
	$naddr = shift(@voter);
	$a = $age[0];
	$sql = "select lid,language from langs";
	$sth = $db->do($sql);
	while(my (@row) = $sth->fetchrow) {
		$lid = $row[0];
		$language = $row[1];
		if($language eq "English") {
			$selected = "SELECTED";
		} else {
			$selected = "";
		}
		$langsel .= "<OPTION VALUE=$lid>$language</OPTION>";
	}
open(TO,"<to.js");
@to = <TO>;
$to = join("",@to);
$to =~ s/PHID/$phid/;
$to =~ s/VOTER_ID/$voter_id/;
$to =~ s/CMPID/$cmpid/;
	print <<"EOF";
<HTML>
<HEAD>
$to
<TITLE>Ross Mirkarimi for Supervisor -- Phonebank</TITLE>
</HEAD>
<BODY OnLoad="timeIt()">
<form name="timerform">
<input type="hidden" name="clock" size="7" value="15:00"><p>
</form>
<FORM ACTION='http://cybre.net/elect/ross/phone.pl' METHOD='GET'>
<INPUT TYPE='HIDDEN' NAME='voter_id' VALUE=$voter_id>
<INPUT TYPE='HIDDEN' NAME='cmpid' VALUE=$cmpid>
<INPUT TYPE='HIDDEN' NAME='phid' VALUE=$phid>
<TABLE BORDER=2>
	<TR COLSPAN=3><TD>
	<TABLE BORDER=2>
		<TR><TD>Fname, Lname: <TD>$fname $lname</TD></TR>
		<TR><TD>Phone:</TD><TD><b>$phone</b></TD></TR>
		<TR><TD>Addr:</TD><TD>$hnum $street</TD></TR>
		<TR><TD>Birth Place</TD><TD>$bplace</TD>
		<TR><TD>Age:<TD>$a</TD></TR>
		<TR><TD>Party:</TD><TD>$party</TD></TR>
		<TR><TD>Absentee:</TD><TD>$perm</TD></TR>
		<TR><TD># at addr:</TD><TD><A HREF='addr.pl?house=$hnum&street=$street'>$naddr</A></TD></TR>
	</TABLE>
	</TD>
	<TD>
	<TABLE BORDER=2>
		<TR><TD>Support:</TD><TD>
			<SELECT NAME='SUP'>
				<OPTION VALUE='' SELECTED>
				<OPTION VALUE='SUP'>Support
				<OPTION VALUE='NO2'>#2
				<OPTION VALUE='NO3'>#3
				<OPTION VALUE='UND'>Undecided
				<OPTION VALUE='AGN'>Opposed
			</SELECT></TD></TR>
		<TR><TD>Sign:</TD><TD><INPUT TYPE='CHECKBOX' NAME='SGN'></TD></TR>
		<TR><TD>Volunteer:</TD><TD><INPUT TYPE='CHECKBOX' NAME='VOL'></TD></TR>
		<TR><TD>House Party:</TD><TD><INPUT TYPE='CHECKBOX' NAME='HPTY'></TD></TR>
		<TR><TD>Organize Bldg:</TD><TD><INPUT TYPE='CHECKBOX' NAME='BLDG'></TD></TR>
		<TR><TD>Left Message:</TD><TD><INPUT TYPE='CHECKBOX' NAME='MSG'></TD></TR>
		<TR><TD>Call Back:</TD><TD><INPUT TYPE='CHECKBOX' NAME='BAK'></TD></TR>
	</TABLE>
	</TD>
	<TD>
	<TABLE BORDER=2>
		<TR><TD>Language:</TD><TD><SELECT NAME='lang'>$langsel</SELECT></TD></TR>
		<TR><TD>Bad Number:</TD><TD><INPUT TYPE='CHECKBOX' NAME='BAD'></TD></TR>
		<TR><TD>Don't Call:</TD><TD><INPUT TYPE='CHECKBOX' NAME='DNC'></TD></TR>
		<TR><TD>Deceased:</TD><TD><INPUT TYPE='CHECKBOX' NAME='DED'></TD></TR>
	</TABLE>
	</TD></TR>
</TABLE>
<TABLE BORDER=2>
	<TR><TD ROWNSPAN=3>Notes:<br><INPUT TYPE='SUBMIT' NAME='ACTION' VALUE='NEXT'></TD>
		 <TD><TEXTAREA NAME='NOTES' ROWS=3 COLS=40></TEXTAREA></TD></TR>
</TABLE>
</FORM>
EOF
}

sub	genform	{
print "<HTML><HEAD><TITLE>PhoneLists</HEAD><BODY>\n";
$sql = "select distinct(phid),phonelist,title,phone.cmpid,campaign from phone,cmp where phone.cmpid=cmp.cmpid";
$sth = $db->do($sql);
$gensel = "<TR><TD>Phonelist:</TD><TD><SELECT NAME='phid'>\n";
while(my(@row) = $sth->fetchrow()) {
	$phid = $row[0];
	$phonelist=$row[1];
	$title=$row[2];
	$cmpid=$row[3];
	$campaign=$row[4];
	$gensel .= "<OPTION VALUE=$phid>$campaign $title\n";
}
$gensel .= "</SELECT><INPUT TYPE='SUBMIT' VALUE='PHONE' NAME='ACTION' ></TD></TR> </FORM></TD></TR>";
print << "EOF";
<H2>Ross Mirkarimi for Supervisor Phonelists</H2>
$msg
<br>
$db->{err}
<br>
<TABLE>
<TR><TD COLSPAN=3><HR></TD></TR>
<FORM ACTION='http://cybre.net/elect/ross/phone.pl' METHOD='GET'>
$gensel
<TR><TD>
EOF
}


