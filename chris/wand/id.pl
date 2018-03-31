#!/usr/bin/perl
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
                                                                               
use DBI;
use URI::Escape;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                               
$cmpid = 19; 
(@elts) = split("/",$0);
$id = $elts[$#elts];
$script = $id;
$id =~ s/\..*$//;
$id =~ tr/a-z/A-Z/;
$id =~ s/$ENV{SERVER_ROOT}//;
%idstrings = (
	SUP => "Supporters #1",
	AGN => "Against",
	UND => "Undecided",
	DNC => "Do Not Call",
	BAD => "Bad Number",
	NO2 => "Number 2",
	NO3 => "Number 3",
	MSG => "Left Message",
	SGN => "House Sign",
	VOL => "Volunteer",
	NH => "Not Home",
	VBM => "Vote By Mail",
	GOTV1 => "GOTV1",
	GOTV2 => "GOTV2",
	GOTV3 => "GOTV3",
	MSG => "Left Message",
	VOT => "Voted"
);
$str = $idstrings{$id};
if($ENV{REQUEST_METHOD} eq "GET" || length($ENV{QUERY_STRING})) {
   $QUERY_STRING = $ENV{QUERY_STRING};
}
if(($ENV{REQUEST_METHOD} eq "POST") && $ENV{CONTENT_LENGTH}) {
   while(<>) {
      $QUERY_STRING .= $_;
   }
}

if(!length($QUERY_STRING)) {
	&doForm($id);;
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
   $Elts{id} = $id;
	&doID(%Elts);
}

sub	getIDtype 	{
	my($id) = shift;
	$sql = "select idtid from idtypes where type='$id'";
	$sth = $conn->exec($sql);
	if($sth) {
		my(@row) = $sth->fetchrow;
		return($row[0]);
	}
}

sub	doID {
	my($Elts) = %_;
	$idtype = getIDtype($id);
	$usr = $Elts{USR};
	$ip = $Elts{IP};
	$voter_id = $Elts{voter_id};
	if($id =~ /GOTV/) {
		$gotv = $id;
		$gotv =~ s/GOTV//;
		$sql = "insert into canv (gotv,cmpid,usr,ip,stamp,voter_id,fb) values ($gotv,$cmpid,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id,1)";
	} else {
		#$sql = "insert into canv (sup,cmpid,usr,ip,stamp,voter_id,fb) values ($idtype,$cmpid,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id,1)";
		$sql = "insert into canv (sup,cmpid,usr,ip,stamp,voter_id,fb) values ($idtype,$cmpid,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id,1)";
	}
	$msg = "<h4>";
	if(length($voter_id)) {
		$conn->exec($sql);
		$msg .= "$voter_id ";
		if($conn->errorMessage) {
			$msg .= $conn->errorMessage;
		} else {
			$msg .= "identified as $str";
		}
	} else {
		$msg .= "please enter voter_id";
	}
	$msg .= "</H4>\n";	
	&doForm;
}

sub	doForm	{
	my($id) = shift;
print << "EOF";
content-type: text/html


<HTML>
<HEAD>
<TITLE>Chris Daly 2006 - Wand $str</TITLE>
<SCRIPT LANGUAGE="JavaScript">
function toForm() { document.form.voter_id.focus(); }
</SCRIPT>
</HEAD>
<BODY onLoad="toForm()">
$msg
<H2>$str</H2>
<FORM NAME='form' ACTION="$script">
<INPUT TYPE="TEXT" NAME='voter_id'>
<INPUT TYPE="SUBMIT" NAME="SUBMIT" VALUE="SUBMIT">
</FORM>
</BODY>
</HTML>
EOF
}
