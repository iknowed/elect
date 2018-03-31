#!/usr/local/bin/perl
use DBI;
use Elect;
use LWP::UserAgent;

$e = Elect->new();
$db = $e->{db};
$db->connect();

$ua = LWP::UserAgent->new;
$url1 = "http://ssdi.genealogy.rootsweb.com/cgi-bin/ssdi.cgi";
$one = "$host/PollLookup41.nsf/SearchData?openform";

$sql = "select name_first,name_last,birth_date,mvf.voter_id from mvf,ded,e031209 e where (ded.dead='t' and (e.v='A' or e.v='V') and e.voter_id=ded.voter_id and ded.voter_id=mvf.voter_id)";

$qy = $db->do($sql);
open(DED,">dead.html");
while(my(@res) = $qy->fetchrow) {
	$name_first = $res[0];
	$name_last = $res[1];
	$birth_date = $res[2];
	$voter_id = $res[3];
	($yr,$mo,$dy) = split("-",$birth_date);
	$post_data = "firstname=$name_first&lastname=$name_last&birth=$yr&bmo=$mo&bda=$dy";
	my $req = HTTP::Request->new(POST => $url1);
	$req->content_type("application/x-www-form-urlencoded");
	$req->content($post_data);
	my $res = $ua->request($req);
	$c = $res->content;
	(@lines) = split("\n",$c);
	print "$name_first $name_last $birth_date: ";
	if(($c =~ /Nothing found/)) {
		$sql = "update ded set dead='f' where voter_id=$voter_id";	
		"is not dead\n";
	} else {
		$reallydead=0;
		for($i = 121; !($lines[$i] =~ /\/table/i) ; $i++) {
			(@d)= split("</td><td>",$lines[$i]);
			if($d[7] =~ /, CA/) {
				$reallydead=1;
				print "is dead\n";
			}
			print OUT $lines[$i];
		}
		#if($reallydead) {
		#	$sql = "insert into ded (voter_id,dead) values ($voter_id,'t')";	
		#}
	}
	next;
	if($res->code != 200) {
		print "$res->message\n";
	}
	$db->do($sql);	
}
