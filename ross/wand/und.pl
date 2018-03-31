#!/usr/local/bin/perl
                                                                               
$ENV{PGUSER}='elect';
use DBI;
use URI::Escape;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                               
$e = Elect->new();
$db = $e->{db};
$db->connect();
$cmpid = 15; 
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
);
$str = $idstrings{$id};
if($ENV{REQUEST_METHOD} eq "GET") {
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
	$sth = $db->do($sql);
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
	$sql = "insert into canv (sup,cmpid,usr,ip,stamp,voter_id) values ($idtype,$cmpid,\'$ENV{REMOTE_USER}\',\'$ENV{REMOTE_ADDR}\',now(),$voter_id)";
	$msg = "<h4>";
	if(length($voter_id)) {
		$db->do($sql);
		$msg .= "$voter_id ";
		if($db->{err}) {
			$msg .= $db->{err};
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
<TITLE>Ross Mirkarimi for Supervisor - Wand $str</TITLE>
<SCRIPT LANGUAGE="JavaScript">
function toForm() { document.form.voter_id.focus(); }
</SCRIPT>
</HEAD>
<BODY onLoad="toForm()">
$msg
<H2>$str</H2>
<FORM NAME='form' ACTION="/elect/ross/wand/$script">
<INPUT TYPE="TEXT" NAME='voter_id'>
<INPUT TYPE="SUBMIT" NAME="SUBMIT" VALUE="SUBMIT">
</FORM>
</BODY>
</HTML>
EOF
}
