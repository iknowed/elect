use Postgres;
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

open(V,"<data/AV Envelopes.txt") || die "open: $!";
$_ = <V>;
chop;
chop;
s/\"//g;
@F = split(/,/);
for ( $f = 0 ; $f <= $#F ; $f++ ) {
	if($F[$f] =~ /^[0-9]/) {
		$F[$f] = "E" . $F[$f];
	}
}
$good = 0;
$bad = 0;
open(EXCEPT,">except");
while(<V>) {
	$line = $_;
	chop;
	chop;
	if(/[^\"0-9\,],/ || /,[^\"0-9\,]/) {
		s/([^"0-9\,])(,)/$1/;
		s/(,)([^"0-9\,])/$2/;
	}
	s/"/'/g;
	@V = split(/,/);
	for($i = 0 ; $i <= $#F ; $i++ ) {
		if($F[$i] eq "voter_id") {
			$voter_id = $V[$i];
		}
		if($F[$i] =~ /date/) {
			$V[$i] =  &fix_date($V[$i]) ;
		} elsif(!($V[$i] =~ /\'/)) {
			if(!length($V[$i])) {
				$V[$i] = " ";
			}
			$V[$i] = "\'$V[$i]\'";
		}
		push(@cols,$F[$i]);
		push(@vals,$V[$i]);
	}
#	print "$sth\n";
#	print $sql . "\n";
	my $sql = "insert into av ";
	$sql .= "(" . join(",",@cols) . ")  ";
	$sql .= " values (" . join(",",@vals) . ")  ";
	undef(@cols);
	undef(@vals);
	$db->do("insert into vid (voter_id) values ($voter_id)");
	$sth = $db->do($sql);
	if($sth != null ) {
		$good++;
	} else {
		$bad++;	
		print EXCEPT "$_\n";
	}
	$sql = "";
#	print "$sth\n";
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
