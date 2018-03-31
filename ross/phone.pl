#!/usr/bin/perl -I . -I /www/port80/root/elect/ross
push(@INC,".","/www/port80/root/elect/ross");
use strict;
#  option to declare SECOND!!!
#  Absentee PERM

$ENV{PGUSER}='elect';
use Pg;
use DBI;
use URI::Escape;
my $pghost="spark";
my $pgport="5432";
my $pgoptions ="";
my $pgtty ="";
my $dbname ="elect";
my $login="elect";
my $pwd ="";
my $conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
#use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
my $bulk = 0;
if($ARGV[0] = 'BULK') {
	$bulk = 1;
}
open(CANV,"<canv.html");
my(@canv) = <CANV>;
my $canvhtml = join("",@canv);
open(EXT,"<ext.html");
my(@ext) = <EXT>;
my $exthtml = join("",@ext);
my $msg; 
my $phid;
my $cmpid;
#my $e = Elect->new();
print <<"EOF";
Content-Type: text/html


EOF
my $QUERY_STRING;
if($ENV{REQUEST_METHOD} eq "GET") {
	$QUERY_STRING = $ENV{QUERY_STRING};
}
if(($ENV{REQUEST_METHOD} eq "POST") && $ENV{CONTENT_LENGTH}) {
	while(<>) {
		$QUERY_STRING .= $_;
	}
}
my %Elts;
if(!length($QUERY_STRING)) {
&genform;
} else {
	$QUERY_STRING =~ s/\+/ /g;
	my(@elts) = split("\&",$QUERY_STRING);
	foreach (@elts) {
		my($tag,$val) = split("\=");
		$Elts{$tag} = uri_unescape($val);
		#print "$tag: $Elts{$tag}<br>\n";
	}
	$Elts{USR} = $ENV{REMOTE_USER};
	$Elts{IP} = $ENV{REMOTE_ADDR};
	$Elts{cmpid} = getCmpid($Elts{phid});
	&beginTrans;
	if($Elts{'ACTION'} eq 'TIMEOUT') {
		&timeout(%Elts);
	}
	if($Elts{voter_id}) {
		&next(%Elts);
	}
	&phone(%Elts);
	&endTrans;
	print "</BODY></HTML>\n	";
}

sub	timeout	{
	my($Elts) = %_;
	my $voter_id = $Elts{voter_id};
	$phid = $Elts{phid};
	my $cmpid = $Elts{cmpid};
	my $phonetable = &getPhoneTable($phid,$cmpid);
	&lockTable($phonetable);
	if(&isLocked($voter_id,$phonetable)) {
		&unlockVoter($voter_id,$phonetable);
	}
}

sub	getPhoneTable {
	my($phid,$cmpid) = @_;
	my $phonelist = &getPhoneList($phid);
	my $campaign = &getCampaign($cmpid);
	return($campaign. "_" .$phonelist);
}

sub	getCmpid {
	my($phid) = shift;

	my $sql = "select cmpid from phonelists where phid=$phid";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
	my $cmpid;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$cmpid= $row[0];
	}
	return($cmpid);
}

sub	getCampaign {
	my($cmpid) = shift;

	my $sql = "select campaign from cmp where cmpid=$cmpid";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
	my $campaign;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$campaign= $row[0];
	}
	return($campaign);
}

sub	getPhoneList	{
	my($phid) = shift;

	my $sql = "select phonelist from phonelists where phid=$phid";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
	my $phonelist;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$phonelist = $row[0];
	}
	return($phonelist);
}
sub	lockTable	{
	my($table) = shift;

	my $sql = "lock table $table";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}

sub	beginTrans	{
	my $sql = "begin transaction";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}
sub	endTrans	{
	my $sql = "end transaction";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}

sub	getidtypeID	{
	my($type) = shift;

	my $sql = "select idtid from idtypes where type='$type'";
	my $sth = $conn->exec($sql);
	$msg .= $conn->errorMessage;
	my $id;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$id = $row[0];
	}
	return($id);
}
sub	getID	{
	my($id) = shift;

	my $sql = "select type from idtypes where idtid=$id";
	my $sth = $conn->exec($sql);
	$msg .= $conn->errorMessage;
	my $id;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$id = $row[0];
	}
	return($id);
}
sub	getpstatID	{
	my($type) = shift;

	my $sql = "select pstatid from pstat where type='$type'";
	my $sth = $conn->exec($sql);
	$msg .= $conn->errorMessage;
	my $id;
	if($sth) {
		my(@row) = $sth->fetchrow;
		$id = $row[0];
	}
	return($id);
}
sub	isLocked	{
	my($voter_id,$phonetbl) = @_;

	my $lok = getpstatID('LOK');

	my $sql = "select stat from $phonetbl where voter_id = $voter_id";
	my $sth = $conn->exec($sql);
	$msg .= $conn->errorMessage;
	my(@row) = $sth->fetchrow;
	my $stat = $row[0];
	return($stat == $lok);
}
sub	isUnLocked	{
	my($voter_id,$phonetbl) = @_;

	my $unl = getpstatID('UNL');

	my $sql = "select stat from $phonetbl where voter_id = $voter_id";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
	my(@row) = $sth->fetchrow;
	my $stat = $row[0];
	return($stat == $unl);
}
sub	isFinished	{
	my($voter_id,$phonetbl) = @_;

	my $fin = getpstatID('FIN');

	my $sql = "select stat from $phonetbl where voter_id = $voter_id";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
	my(@row) = $sth->fetchrow;
	my $stat = $row[0];
	return($stat == $fin);
}

sub	lockVoter	{
	my($voter_id,$phonetbl) = @_;
	my $lok = getpstatID('LOK');
	my $t = time;
	my $sql = "update $phonetbl set stat=$lok, stamp=$t where voter_id=$voter_id";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}

sub	unlockVoter	{
	my($voter_id,$phonetbl) = @_;
	my $unl = getpstatID('UNL');
	my $t = time;
	my $sql = "update $phonetbl set stat=$unl, stamp=$t where voter_id=$voter_id";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}

sub	finVoter	{
	my($voter_id,$phonetbl) = @_;
	my $fin = getpstatID('FIN');
	my $t = time;
	my $sql = "update $phonetbl set stat=$fin, stamp=$t where voter_id=$voter_id";
	my $sth = $conn->exec($sql);
	return($conn->errorMessage);
}

sub	doCanv	{
	my($Elts) = $_;
	my $sup = $Elts{SUP};	
	my $sgn = length($Elts{SGN}) ? 1 : 0;
	my $cmpid = length($Elts{cmpid}) ? 1 : 0;
	my $voter_id = $Elts{voter_id};
	my $vol = length($Elts{VOL}) ? 1 : 0;
	my $hpty = length($Elts{HPTY}) ? 1 : 0;
	my $bldg = length($Elts{BLDG}) ? 1 : 0;
	my $msg = length($Elts{MSG}) ? 1 : 0;
	my $bak = length($Elts{BAK}) ? 1 : 0;
	my $bad = length($Elts{BAD}) ? 1 : 0;
	my $dnc = length($Elts{DNC}) ? 1 : 0;
	my $ded = length($Elts{DED}) ? 1 : 0;
	my $na = length($Elts{NA}) ? 1 : 0;
	my $usr = $Elts{USR};
	my $ip  = $Elts{IP};
	my $lid = $Elts{lang};
	my $notes = $Elts{NOTES};
	my $idtype = $sup ? getidtypeID($sup) : 14;
	$notes =~ s/\'/\\'/g;
	my $sql = "insert into canv (sup,sgn,vol,msg,bak,na,bldg,hpty,cmpid,notes,usr,ip,stamp,voter_id) values ($idtype,$sgn,$vol,$msg,$bak,$na,$bldg,$hpty,$cmpid,\'$notes\',\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
}

sub	doExt	{
	my($Elts) = $_;
	my $voter_id = $Elts{voter_id};	
	my $bad = length($Elts{BAD}) ? 1 : 0;
	my $dnc = length($Elts{DNC}) ? 1 : 0;
	my $ded = length($Elts{DED}) ? 1 : 0;
	my $usr = $Elts{USR};
	my $ip  = $Elts{IP};
	my $lid = $Elts{lang};
	my $notes = $Elts{NOTES};

	my $sql = "insert into ext (lid,bad,dnc,ded,usr,ip,stamp,voter_id) values ($lid,$bad,$dnc,$ded,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
	my $sth = $conn->exec($sql);
	my $msg .= $conn->errorMessage;
}
sub	next	{
	my($Elts) = %_;
	my $voter_id = $Elts{voter_id};	

	my $cmpid = $Elts{cmpid};	
	my $phid = $Elts{phid};	
	my $sup = $Elts{SUP};	
	my $sgn = length($Elts{SGN}) ? 1 : 0;
	my $vol = length($Elts{VOL}) ? 1 : 0;
	my $hpty = length($Elts{HPTY}) ? 1 : 0;
	my $bldg = length($Elts{BLDG}) ? 1 : 0;
	my $msg = length($Elts{MSG}) ? 1 : 0;
	my $bad = length($Elts{BAD}) ? 1 : 0;
	my $noa = length($Elts{NA}) ? 1 : 0;
	my $dnc = length($Elts{DNC}) ? 1 : 0;
	my $ded = length($Elts{DED}) ? 1 : 0;
	my $lid = $Elts{lang};
	my $notes = $Elts{NOTES};

	&lockTable("canv");
	&lockTable("ext");

	my $campaign = getCampaign($cmpid);
	my $phonelist = &getPhoneList($phid);
	my $phonetable = &getPhoneTable($phid,$cmpid);
	if(&isLocked($voter_id,$phonetable)) {
		&lockTable($phonetable);
		&doCanv(%Elts);
		&doExt(%Elts);
		&finVoter($voter_id,$phonetable);
	}

}

sub	phone {
	my($Elts) = %_;
	my $ok = 0;
	#print "<HTML><HEAD><TITLE>PhoneList</TITLE></HEAD><HTML><BODY OnLoad="timeIt()">\n";
	$phid = $Elts{phid};
	my $ok = 0;
	my $sql = "select campaign,phonelist,cmp.cmpid from phone,cmp where phone.cmpid=cmp.cmpid and phid=$phid";
	my $sth = $conn->exec($sql);
	my(@row) = $sth->fetchrow;
	my $cmp= $row[0];
	my $phonelist = $row[1];
	$cmpid = $row[2];
	my $phonetbl = $cmp."_".$phonelist;
	&lockTable($phonetbl);
	my $pstatid = getpstatID("UNL");

#		my $sql = "select count(distinct($phonetbl.voter_id)) from $phonetbl p1, $phonetbl p2, mvf where (p1.stat=$pstatid) and p2.voter_id not in ( select distinct(voter_id) from av where av.date_returned is not null) and (p1.voter_id=p2.voter_id and p1.voter_id=mvf.voter_id) ";
		#my $sql = "select count(distinct(p1.voter_id)) from $phonetbl p1 where p1.voter_id not in ( select distinct(voter_id) from av where av.date_returned is not null) and (p1.stat=2)";
	my $sql;
	if($phonetbl =~ /russ/) {
		$sql = "select count(distinct(p1.voter_id)) from $phonetbl p1 where (p1.stat=2) ";
 	} elsif($phonetbl =~ /undec/ || $phonetbl =~ /repub/i) {
		$sql = "select count(distinct(p1.voter_id)) from $phonetbl p1, mvf where (p1.voter_id=mvf.voter_id)";
	} else {
		$sql = "select count(distinct(p1.voter_id)) from $phonetbl p1 where (p1.stat=2) and p1.voter_id not in ( select voter_id from canv where ( sup != 14 and sup != 4 )) ";
	}

	my $sth = $conn->exec($sql);
	my(@row) = $sth->fetchrow;
	my $cnt = $row[0];
	my $order = "desc";
	if($cnt) {
		if(($phonetbl eq "ross_abs_latino") ||
		   ($phonetbl eq "ross_eday_latino") ||
		   ($phonetbl eq "ross_cn_abs") ||
		   ($phonetbl eq "ross_senior_abs") ||
		   ($phonetbl eq "ross_senior_eday") ||
		   ($phonetbl eq "ross_oct_regs") ||
		   ($phonetbl eq "ross_rus_abs")) {
			$order = "asc";
	
		} else {
			$order = "desc";
		}
		#my $sql = "select distinct(mvf.voter_id),birth_date from $phonetbl p1, $phonetbl p2, mvf where (p1.stat=$pstatid) p3.voter_id not in ( select distinct(voter_id) from av where av.date_returned is not null)) and (p1.voter_id=p2.voter_id and mvf.voter_id=p1.voter_id) order by mvf.birth_date $order";
		my $sql;
		if($phonetbl =~ /russ/) {
			$sql = "select distinct(p1.voter_id),mvf.birth_date from $phonetbl p1, mvf where (p1.voter_id=mvf.voter_id) and (p1.stat=2) order by mvf.birth_date $order";
 		} elsif($phonetbl =~ /undec/ || $phonetbl =~ /repub/i) {
			$sql = "select distinct(p1.voter_id),mvf.birth_date from $phonetbl p1, mvf where (p1.voter_id=mvf.voter_id)  and (p1.stat=2) order by mvf.birth_date $order";
		} else {
			$sql = "select distinct(p1.voter_id),mvf.birth_date from $phonetbl p1, mvf where (p1.voter_id=mvf.voter_id) and (p1.stat=2) and p1.voter_id not in ( select voter_id from canv where ( sup != 14 and sup != 4 )) order by mvf.birth_date $order";
		}
		my $sth = $conn->exec($sql);
		my(@row) = $sth->fetchrow;
		my $voter_id = $row[0];

		if($voter_id) {
			my $lok = getpstatID('LOK');
			&lockVoter($voter_id,$phonetbl);

			my $sql = "select name_first,name_last,phone,birth_place,house_number,street,party,age(birth_date),voter_id,perm from mvf where voter_id=$voter_id";
			my $sth = $conn->exec($sql);
			my $msg .= $conn->errorMessage;
			my(@row) = $sth->fetchrow;

			my $street = $row[5];
			my $house = $row[4];
			my $sql = "select count(*) from mvf where street='$street' and house_number='$house'";
			my $sth = $conn->exec($sql);
			my $msg .= $conn->errorMessage;
			my(@r) = $sth->fetchrow;
			my $n = $r[0];
			push(@row,$n);

			$ok = 1;
			&genphonePG(@row);
		} else {
			$msg = "can't find voter_id\n";
		}
	} else {
			$msg = "no more voters left in this phonelist\n";
	}
	if(!$ok) {	
		&genform;
	}
}

sub	genphonePG	{
	my(@voter) = @_;
	my $fname = shift(@voter);
	my $lname = shift(@voter);
	my $phone = shift(@voter);
	my $phone = substr($phone,0,3) . "-" . substr($phone,3,4);
	my $bplace = shift(@voter);
	my $hnum  = shift(@voter);
	my $street = shift(@voter);
	my $party = shift(@voter);
	my @age = split(/\ /,shift(@voter));
	my $voter_id = shift(@voter);
	my $perm = shift(@voter);
	my $naddr = shift(@voter);
	my $a = $age[0];
	my $sql = "select lid,language from langs";
	my $sth = $conn->exec($sql);
	my $langsel;
	while(my (@row) = $sth->fetchrow) {
		my $lid = $row[0];
		my $language = $row[1];
		my $selected;
		if($language eq "English") {
			$selected = "SELECTED";
		} else {
			$selected = "";
		}
		$langsel .= "<OPTION VALUE=$lid>$language</OPTION>";
	}
open(TO,"<to.js");
my @to = <TO>;
my $to = join("",@to);
$to =~ s/PHID/$phid/;
$to =~ s/VOTER_ID/$voter_id/;
$to =~ s/CMPID/$cmpid/;
open(CANV,"<canv.html");
my (@canv) = <CANV>;
my $canvhtml = join("",@canv);
open(EXT,"<ext.html");
my (@ext) = <EXT>;
my $exthtml = join("",@ext);
$exthtml =~ s/LANGSEL/$langsel/;
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
print "<HTML><HEAD><TITLE>PhoneLists</TITLE></HEAD><BODY>\n";
my $sql = "select distinct(phid),phonelist,title,phone.cmpid,campaign from phone,cmp where phone.cmpid=cmp.cmpid";
my $sth = $conn->exec($sql);
my $gensel = "<TR><TD>Phonelist:</TD><TD><SELECT NAME='phid'>\n";
while(my(@row) = $sth->fetchrow()) {
	my $phid = $row[0];
	my $phonelist=$row[1];
	my $title=$row[2];
	my $cmpid=$row[3];
	my $campaign=$row[4];
	$gensel .= "<OPTION VALUE=$phid>$campaign $title\n";
}
$gensel .= "</SELECT><INPUT TYPE='SUBMIT' VALUE='PHONE' NAME='ACTION' ></TD></TR>";
my $emsg = $conn->errorMessage;
print << "EOF";
<H2>Ross Mirkarimi for Supervisor Phonelists</H2>
$msg
<br>
$emsg
<br>
<FORM ACTION='http://cybre.net/elect/ross/phone.pl' METHOD='GET'>
<TABLE>
<TR><TD COLSPAN=3><HR></TD></TR>
$gensel
</TABLE></FORM></BODY></HTML>
EOF
}


