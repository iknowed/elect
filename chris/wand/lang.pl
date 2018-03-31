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
%langs = (
English    =>   1,
Mandarin   =>   2,
Cantonese  =>   3,
Spanish    =>   4,
Tagalog    =>   5,
Russian    =>   6,
Japanese   =>   7,
Vietnamese =>   8,
Arabic     =>   9,
Farsi      =>  10,
Korean     =>  11,
Samoan     =>  12,
Burmese    =>  13
);
$langform = "<SELECT NAME='lang' size=1>\n";
foreach $lang (keys %langs) {
$lid = $langs{$lang};
$langform .= "<OPTION VALUE=$lid>$lang\n";
}
$langform .= "</SELECT>\n";
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
	$langform =~ s/VALUE=5/VALUE=5 SELECTED/;
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
   $lid = $Elts{lang};
   if($Elts{lang}) {
   	$langform =~ s/VALUE=$lid/VALUE=$lid SELECTED/;
   }
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
	$lang = $Elts{lang};
	foreach $l(keys %langs) {
		if($langs{$l} == $lang) {
			$language = $l;
		}
	}
	$voter_id = $Elts{voter_id};
	#$sql = "insert into canv (sup,cmpid,usr,ip,tstamp,voter_id,fb) values ($idtype,$cmpid,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id,1)";
	$sql = "insert into ext (voter_id,lid,ip,usr) values ($voter_id,$lang,'$ip','$usr')";
	$msg = "<h4>";
	if(length($voter_id)) {
		$conn->exec($sql);
		$msg .= "$voter_id ";
		if($conn->errorMessage) {
			$msg .= $conn->errorMessage;
		} else {
			$msg .= "identified as $language";
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
$langform
<INPUT TYPE="TEXT" NAME='voter_id'>
<INPUT TYPE="SUBMIT" NAME="SUBMIT" VALUE="SUBMIT">
</FORM>
</BODY>
</HTML>
EOF
}
