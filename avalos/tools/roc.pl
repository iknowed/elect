#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
my(@gn_pct);
$qy = $db->do("select pct from res031209 where typ='T' order by th desc");
$gn_rnk = 1;
while(@res = $qy->fetchrow) {
	$pct = $res[0];
	push(@gn_pct,$pct);
}
my(@dem_pct);
foreach $pct (@gn_pct) {
	$qy = $db->do("select grn from pct where pct=$pct");
	@res = $qy->fetchrow;
	$d = $res[0];
	push(@dem_pct,$d);
}

my @rank_dem = ranks(@dem_pct);
my $dem = 0;
$above = 0;
$below = 0;	
for($i = 0 ; $i < $#rank_dem ; $i++ ) {
	$this = $rank_dem[$i];
	for($j = $i+1 ; $j < $#rank_dem; $j++ ) {
		$that = $rank_dem[$j];
		if($this > $that) {
			$a++;
		}
		if($that > $this) {
			$b++;
		}		
	}
	$above += $a;
	$below += $b;
	$a = 0;
	$b = 0;
}
print "above: $above\n";
print "below: $below\n";
$amb = $above - $below;
$apb = $above + $below;
print "above - below = $amb\n";
print "above + below = $apb\n";
$coef = $amb/$apb ;
print $coef . "%\n";;

sub ranks {
	my @positions = sort {$_[$b]<=>$_[$a]} (0 .. $#_);
	my @ranks = sort {$positions[$a]<=>$positions[$b]} (0 .. $#_);
	map {$_+1} @ranks;
}

