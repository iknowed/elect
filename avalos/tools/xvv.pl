use DBI;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );

$e = Elect->new();
$db = $e->{db};
$db->connect();

open(V,"<Voted Voter File.txt") || die "open: $!";
#elect=# create table vvf041102 ( voter_id int, e041102 char(1) );
$f = <V>;
while(<V>) {
	$line = $_;
	chop;
	chop;
	@V = split(/,/);
	$voter_id = $V[0];
	$e = $V[1];
	$e =~ s/\"/\'/g;
	$res = $db->do("insert into vvf041102 (voter_id,e041102) values ($voter_id,$e)");
	if(!$res) {
		print EXCEPT;
	}
}

sub	fix_date	{
	$datetime = shift;
	($date,$time) = split(/\ /,$datetime);
	($m,$d,$y) = split(/\//,$date);
	$datetime = $y . "-" . $m . "-" . $d ;
	return($datetime);
}
