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
my $errmsg;
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
&genphonePG;
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

sub	getcmpid {
	my($campaign) = shift;

	$sql = "select cmpid from cmp where campaign='$campaign'";
	$sth = $db->do($sql);
	$msg .= $db->{ERR};
	if($sth) {
		my(@row) = $sth->fetchrow;
		$cmpid = $row[0];
	}
	return($cmpid);
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
	$na  = length($Elts{NA}) ? 1 : 0;
	$bad = length($Elts{BAD}) ? 1 : 0;
	$mad = length($Elts{MAD}) ? 1 : 0;
	$mov	= length($Elts{MOV}) ? 1 : 0;
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
			$sql = "delete from canv where voter_id=$voter_id";
			$sth = $db->do($sql);
			$sql = "insert into canv (sup,sgn,vol,msg,na,bak,bldg,hpty,cmpid,notes,usr,ip,stamp,voter_id) values ($idtype,$sgn,$vol,$msg,$na,$bak,$bldg,$hpty,$cmpid,\'$notes\',\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
			$sth = $db->do($sql);
			$msg .= $db->{err};
	#}
}

sub	doPhone	{
	my($Elts) = $_;
	$cmpid = $Elts{cmpid};	
	$voter_id = $Elts{voter_id};	
	$sql = "select campaign||'_'||phonelist from phone,cmp where (phone.cmpid=$cmpid and (phone.cmpid=cmp.cmpid))";
	$sth = $db->do($sql);
	while($sth && (my(@row) = $sth->fetchrow)) {
		$phonetbl = $row[0];
		$sql = "update $phonetbl set stat=3 where voter_id=$voter_id";
		$sti = $db->do($sql);
	}
}

sub	doExt	{
	my($Elts) = $_;
	$voter_id = $Elts{voter_id};	
	$bad = length($Elts{BAD}) ? 1 : 0;
	$mad = length($Elts{MAD}) ? 1 : 0;
	$mov	= length($Elts{MOV}) ? 1 : 0;
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
			$sql = "delete from ext where voter_id=$voter_id";
			$sth = $db->do($sql);
			$sql = "insert into ext (lid,bad,mad,mov,dnc,ded,usr,ip,stamp,voter_id) values ($lid,$bad,$mad,$mov,$dnc,$ded,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
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
	$phone = $Elts{PHONE};
	$Elts{LNAME} =~ s/\'//g;
	$lname 	= $Elts{LNAME};
	$fname 	= $Elts{FNAME};
	$lid = $Elts{lang};
	$notes = $Elts{NOTES};

	&beginTrans;
	&lockTable("canv");
	&lockTable("ext");

	$campaign = getCampaign($cmpid);
	$phone =~ s/\-//g;
	$fname =~ tr/a-z/A-Z/;
	$lname =~ tr/a-z/A-Z/;
	$sql = "select voter_id from mvf where	phone=$phone and name_last='$lname' and name_first='$fname'";
	$sth = $db->do($sql);
	my(@row) = $sth->fetchrow;
	if($sth) {
		$voter_id = $row[0];
	}
	if(!$voter_id) {
		$errmsg = "<H2> $phone $lname $fname NOT FOUND</H2>";
	}
	$Elts{voter_id} = $voter_id;
	if($voter_id) {
		&doCanv(%Elts);
		&doExt(%Elts);
		&doPhone(%Elts);
	} 
	&endTrans;	
	&genphonePG(%Elts);
}

sub	genphonePG	{
	my(@voter) = @_;
	$cwd = `/bin/pwd`;
	chop($cwd);
	(@dirs) = split(/\//,$cwd);
	$campaign = pop(@dirs);
	$cmpid = getcmpid($campaign);
		
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
open(CANV,"<canv.html");
(@canv) = <CANV>;
$canvhtml = join("",@canv);
open(EXT,"<ext.html");
(@ext) = <EXT>;
$exthtml = join("",@ext);
$exthtml =~ s/LANGSEL/$langsel/;
	print <<"EOF";
<HTML>
<HEAD>
$to
<TITLE>Ross Mirkarimi for Supervisor -- Phonebank</TITLE>
</HEAD>
<BODY OnLoad="timeIt()">
$errmsg
<form name="timerform">
<input type="hidden" name="clock" size="7" value="15:00"><p>
</form>
<FORM ACTION='http://cybre.net/elect/ross/oldphone.pl' METHOD='GET'>
<INPUT TYPE='HIDDEN' NAME='cmpid' VALUE=$cmpid>
<TABLE BORDER=2>
	<TR COLSPAN=3><TD>
	<TABLE BORDER=2>
		<TR><TD>Lname:</TD><TD><INPUT NAME='LNAME' SIZE=20></TD></TR>
		<TR><TD>Fname:</TD><TD><INPUT NAME='FNAME' SIZE=20></TD></TR>
		<TR><TD>Phone:</TD><TD><INPUT NAME='PHONE' SIZE=12></TD></TR>
	</TABLE>
	</TD>
	<TD>
$canvhtml
	</TD>
	<TD>
$exthtml
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
open(CANV,"<canv.html");
(@canv) = <CANV>;
$canvhtml = join("",@canv);
open(EXT,"<ext.html");
(@ext) = <EXT>;
$exthtml = join("",@ext);
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


