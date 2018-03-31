
$tot = 422040;
$m = 169320;
$f = 168090;
$o = 84630;

print &pct($m,$tot) . "\n";
print &pct($f,$tot) . "\n";
print &pct($o,$tot) . "\n";
print &pct($tot,$tot) . "\n";

sub pct {
	my($a) = shift;
	my($b) = shift;
	my($pct) = 100.0 * (1.0*$a)/(1.0*$b);
	if($pct == 100) {
		return("100%");
	} else {
		return(substr($pct,0,index($pct,'.')+3)."%");
	}
}

