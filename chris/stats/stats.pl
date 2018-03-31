#!/usr/bin/perl
use Pg;
use DBI;
use GD::Graph::bars;
use GD::Graph::pie;
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty =""; $dbname ="elect";
$login="elect";
$pwd ="";
$conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
$conn1 = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

my(@wheres,@langs,@eths,@histbool,@genders,@supvs,@parties,@bplaces,@bplace);
my($agemin,$agemax,$pvimin);
my($pvimax,$medmin,$medmax);
my($regageminmo,$regagemaxmo,$REGAGEMIN);
my($regageminyr,$regagemaxyr,$REGAGEMAX);
my($tenant);
my($HIST)='V';
my($HISTBOOL)='AND';
my($PHONEWALK) = 'W';
my($EMAIL);
my $req;
if($ENV{QUERY_STRING} || ($ENV{REQUEST_METHOD} eq "POST")) {
	if($ENV{REQUEST_METHOD} eq "POST") {
		$req = <>;
	} else {
		$req = $ENV{QUERY_STRING};
	}
	#langs=1&gender=F&supv=&party=12653&agemin=40&agemax=18
	$tables{mvf} = 1;
	foreach(split(/&/,$req)) {
		if(/^langs/) {
			$tables{lang} = 1;
			$tables{langs} = 1;
			my ($foo,$lang) = split(/=/);
			push(@langs,$lang);
		}
	}
print<<EOF;
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>$fname | $lname | $radius</TITLE>
</HEAD>
<BODY>
<TABLE>
EOF


print "</TD></TR></TABLE>\n";

print <<EOF;
	</BODY></HTML>\n
EOF
} else { 

print<<EOF;
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>
Canvass Statistics Report
</TITLE>
<script language="javascript" type="text/javascript" src="/js/datetimepicker.js">
</script>
</HEAD>
<FORM METHOD="GET" ACTION="stats.pl">
<input id="from" type="text" size="25"><a href="javascript:NewCal('from','ddmmmyyyy',true,12)"><img src="/js/cal.gif" width="16" height="16" border="0" alt="Pick a date"></a>
<input id="to" type="text" size="25"><a href="javascript:NewCal('to','ddmmmyyyy',true,12)"><img src="/js/cal.gif" width="16" height="16" border="0" alt="Pick a date"></a>
</FORM>
</HTML>
EOF
}
