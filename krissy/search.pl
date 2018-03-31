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
&genSearchPG;
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
	if($Elts{'ACTION'} eq 'SEARCH') {
		&search(%Elts);
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

sub	search	{

	my($Elts) = $_;
	my(@qys);
	open(CANV,"<canv1.html");
	(@canv) = <CANV>;
	my $voter_id, $phone, $house_number, $street, $birth_place, $age, $party, $perm;
	length($Elts{LNAME}) && push(@qys,"name_last='$Elts{LNAME}'");
	length($Elts{FNAME}) && push(@qys,"name_first='$Elts{FNAME}'");
	length($Elts{PHONE}) && push(@qys,"phone='$Elts{PHONE}'");
	my $qy = join(" and ",@qys);
	my $sql = "select voter_id, name_first, name_last, phone, house_number, street, birth_place, age(birth_date), party, perm from mvf where $qy";
	$sql =~ tr/a-z/A-Z/;
	$sth = $db->do($sql);
	$sth && ((@row) = $sth->fetchrow);
	$i = 0;
	$voter_id = $row[$i++];	
	$Elts{voter_id}=$voter_id;
	$name_first = $row[$i++];	
	$Elts{name_first}=$name_first;
	$name_last = $row[$i++];	
	$Elts{name_last}=$name_last;
	$phone = $row[$i++];	
	$Elts{phone}=$phone;
	$house_number = $row[$i++];	
	$Elts{house_number}=$house_number;
	$street = $row[$i++];	
	$Elts{street}=$street;
	$birth_place = $row[$i++];	
	$Elts{birth_place}=$birth_place;
	$age = $row[$i++];	
	$Elts{age}=$age;
	$party = $row[$i++];	
	$Elts{party}=$party;
	$perm = $row[$i++];	
	$Elts{perm}=$perm;
	$sql = "select sup,sgn,vol,msg,na,bak,bldg,hpty,cmpid,usr,ip,stamp,notes from canv where voter_id=$voter_id";
	$sth = $db->do($sql);
	while($sth && ( my @row = $sth->fetchrow ) )  {
		$n = 0;
		$sup = $row[$n++];
		$sgn = ($row[$n++] && ($SGN_SELECTED=" \'SELECTED\' "));
		$vol = ($row[$n++] && ($VOL_SELECTED=" \'SELECTED\' "));
		$msg = ($row[$n++] && ($MSG_SELECTED=" \'SELECTED\' "));
		$na  = ($row[$n++] && ($NA_SELECTED=" \'SELECTED\' "));
		$bak = ($row[$n++] && ($BAK_SELECTED=" \'SELECTED\' "));
		$bldg = ($row[$n++] && ($BLDG_SELECTED=" \'SELECTED\' "));
		$hpty = ($row[$n++] && ($HPTY_SELECTED=" \'SELECTED\' "));
		$cmpid = $row[$n++];
		$usr = $row[$n++];
		$ip = $row[$n++];
		$stamp = $row[$n++];
		$notes = $row[$n++];
		$type = Elect::getID($sup);
		$type = "NULL" if($sup == 14);
		$s = "\$SUP_".$type."_SELECTED= \"SELECTED\"";
		eval $s;
		my $canvhtml = join("",@canv);
		$c = eval $canvhtml;
		push(@canvs,$c);
	}
	$Elts{canvs} = join("<hr>",@canvs);
	&genphonePG(\%Elts)
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
	&doCanv(%Elts);
	&doExt(%Elts);
	&doPhone(%Elts);
	&endTrans;	
	&genphonePG(%Elts);
}

sub	genSearchPG	{
	my(@voter) = @_;
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
open(CANV,"<canv1.html");
(@canv) = <CANV>;
$canvhtml = join("",@canv);
open(EXT,"<ext.html");
(@ext) = <EXT>;
$exthtml = join("",@ext);
$exthtml =~ s/LANGSEL/$langsel/;
	print <<"EOF";
<!DOCTYPE HTML SYSTEM>
<HTML>
<HEAD>
$to
<TITLE>Ross Mirkarimi for Supervisor -- Phonebank</TITLE>
</HEAD>
<BODY>
$errmsg
<FORM ACTION='http://cybre.net/elect/ross/search.pl' METHOD='GET'>
<INPUT TYPE='HIDDEN' NAME='cmpid' VALUE=$cmpid>
<TABLE BORDER=2>
	<TR COLSPAN=3><TD>
	<TABLE BORDER=2>
		<TR><TD>Last Name:</TD><TD><INPUT NAME='LNAME' SIZE=20></TD></TR>
		<TR><TD>First Name:</TD><TD><INPUT NAME='FNAME' SIZE=20></TD></TR>
		<TR><TD>Phone:</TD><TD><INPUT NAME='PHONE' SIZE=12></TD></TR>
	</TABLE>
	</TD>
	</TR>
</TABLE>
<TABLE BORDER=2>
	<TR><TD ROWNSPAN=3><br><INPUT TYPE='SUBMIT' NAME='ACTION' VALUE='SEARCH'></TD>
</TR>
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


sub	genphonePG	{
	my($Elts) = @_;
	my $fname = $Elts{name_first};
	my $lname = $Elts{name_last};
	my $phone = $Elts{phone};
	(length($phone) == 7) && (substr($phone,3,0) = "-");
	my $bplace = $Elts{birth_place};
	my $hnum  = $Elts{house_number};
	my $street = $Elts{street};
	my $party = $Elts{party};
	my @age = split(/\ /,$Elts{age});
	my $voter_id = $Elts{voter_id};
	my $perm = $Elts{perm};
	my $naddr = $Elts{naddr};
	my $canvhtml = $Elts{canvhtml};
	my $a = $age[0];
	my $sql = "select lid,language from langs";
	my $sth = $db->do($sql);
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
my $canvhtml = $Elts{canvs};
open(EXT,"<ext.html");
my (@ext) = <EXT>;
my $exthtml = join("",@ext);
$exthtml =~ s/LANGSEL/$langsel/;
	print <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
<HEAD>
<meta http-equiv="Content-Type" content='text/html; charset=UTF-8'>
$to
<TITLE>Ross Mirkarimi for Supervisor -- Phonebank</TITLE>
</HEAD>
<BODY OnLoad="timeIt()">
<form name="timerform">
<input type="hidden" name="clock" size="7" value="15:00"><p>
</form>
<FORM ACTION='http://cybre.net/elect/ross/search.pl' METHOD='GET'>
<INPUT TYPE='HIDDEN' NAME='voter_id' VALUE=$voter_id>
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
	</TABLE>
	</TD>
	</TR>
</TABLE>
$canvhtml
</FORM>
EOF
}

