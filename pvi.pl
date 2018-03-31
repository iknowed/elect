open(PVI,"<pvi");
my(@pvi) = <PVI>;
close PVI;
for(my $idx = 0 ; $idx < $#pvi ; $idx += 6) {
	$idx++ if($idx == 612);
	$idx++ if($idx == 1273);
	$idx++ if($idx == 1934);
	$idx++ if($idx == 2595);
	$idx += 2 if($idx == 3256) ;
	$npvi = $pvi[$idx+3];
	chop($npvi);
	$pct = $pvi[$idx];
	if($pct == 3315) {
		print "here\n";
	}
	chop($pct);
	if(!($pct =~ /[\d]{4}/)) {
		print "here";
	}
	$sql = "update pct set npvi=$npvi where pct=$pct";
	print "$sql;\n";
}
