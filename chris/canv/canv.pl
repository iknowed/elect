#!/usr/bin/perl
use Pg;
use DBI;
use URI::Escape;
my $pghost="spark";
my $pgport="5432";
my $pgoptions ="";
my $pgtty ="";
my $dbname ="elect";
my $login="elect";
my $pwd ="";
my $conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

$id{1} = "Support";
$id{2} = "Opposed";
$id{3} = "Undecided";

for($id = 1 ; $id <= 3 ; $id++) {
	$sql = "select precinct,voter_id,e060606,e051108,e041102,e040302,e031209 from mvf061023 where supv=6 and voter_id in ( select distinct voter_id from canv where sup=$id and cmpid=19)";
	$qy = $conn->exec($sql);
	while(my(@row) = $qy->fetchrow) {
		$i = 0;
		$pct = $row[$i++];
		$cnt = $row[$i++];
		my $e1 = $row[$i++];
		my $e2 = $row[$i++];
		my $e3 = $row[$i++];
		my $e4 = $row[$i++];
		my $e5 = $row[$i++];
		my $tot = 0;
		$tot++ if(($e1 eq "V") || ($e1 eq "A") || ($e1 eq "Y"));
		$tot++ if(($e2 eq "V") || ($e2 eq "A") || ($e2 eq "Y"));
		$tot++ if(($e3 eq "V") || ($e3 eq "A") || ($e3 eq "Y"));
		$tot++ if(($e4 eq "V") || ($e4 eq "A") || ($e4 eq "Y"));
		$tot++ if(($e5 eq "V") || ($e5 eq "A") || ($e5 eq "Y"));
		my $percent = (1.0*$tot)/(5.0);
		next unless($percent == .2);
		$Pct{$pct}{$id}++;
	}
}

print "1 and only 1 out of 5\n";
print "PCT,SUP,AGN,UND\n";
foreach $pct ( sort { $a <=> $b } keys %Pct ) {
print "$pct,$Pct{$pct}{1},$Pct{$pct}{2},$Pct{$pct}{3}\n";
}
