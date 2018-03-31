use Postgres;
use Elect;
$ENV{PGUSER}='elect';
$e = Elect->new();
$db = $e->{db};
$db->connect();

open(V,"<AVEnvelopes_D5.csv") || die "open: $!";
$_ = <V>;
chop;
chop;
s/\"//g;
@F = split(/,/);
$good = 0;
$bad = 0;
open(EXCEPT,">except");
while(<V>) {
	$line = $_;
	chop;
	chop;
	@V = split(/,/);
	$fields{$#V}++;
#	print "$sth\n";
#	print $sql . "\n";
	next unless(length($V[3]));
	$V[3] = "'".$V[3]."'";
	my $sql = "insert into av (voter_id,date_returned) values ($V[1],$V[3])";
	#$sql .= "(" . join(",",@cols) . ")  ";
	#$sql .= " values (" . join(",",@vals) . ")  ";
	undef(@cols);
	undef(@vals);
	#$db->do("insert into vid (voter_id) values ($voter_id)");
	$sth = $db->do($sql);
	if($db->{err}) {
	#	print $_ ."\n".$db->{err};
		$sql =~ s/ av / avex /;
		$db->do($sql);
		if($db->{err}) {
			print "$_\n$db->{err}\n";
		}
	}
	if($sth != null ) {
		$good++;
	} else {
		$bad++;	
		print EXCEPT "$_\n";
	}
	$sql = "";
#	print "$sth\n";
}
foreach $size ( sort { $a <=> $b } keys %fields ) { 
	print "$size: $fields{$size}\n";	
}
close  EXCEPT;
#$tot = $bad + $good;
#$bpct = 100 * ( $bad / $total );
#$gpct = 100 * ( $good / $total );
#print "good: $good $gpct%\n";
#print "bad: $bad $bpct%\n";
sub	fix_date	{
	$datetime = shift;
	($date,$time) = split(/\ /,$datetime);
	($m,$d,$y) = split(/\//,$date);
	$datetime =  $y . "-" . $m . "-" . $d ;
	if($datetime eq "--") {
		$datetime = "NULL";
	} else {
		$datetime = "'" . $datetime . "'";
	}
	return($datetime);
}
