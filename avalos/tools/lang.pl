#!/usr/local/bin/perl
use Pg;
use DBI;
use threads;
use Thread::Queue;

$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty ="";
$dbname ="elect";
$login="elect";
$pwd ="";
my $conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
my $sql = "delete from lang";
my $qy = $conn->exec($sql);
my $sql = "select voter_id, birth_place from voters";
my $qy = $conn->exec($sql);

while(my (@res) = $qy->fetchrow) {
	my $voter_id = $res[0];
	my $birth_place = $res[1];
	my $sql = "select eid from eth where voter_id=$voter_id";
	my $qy1 = $conn->exec($sql);
	my (@res1) = $qy1->fetchrow;
	my $eid = $res1[0];
	my $arg = "$voter_id|$birth_place|$eid";
	&ix($arg);
}


sub	ix	{
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty ="";
$dbname ="elect";
$login="elect";
$pwd ="";
	my $conn1 = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
	my($arg) = shift;
	my($voter_id,$birth_place,$eid) = split(/\|/,$arg);
	if($eid) {
		my $sql = "select lid from ethnicities where eid=$eid";
		#print "$sql\n";
		my $qy1 = $conn1->exec($sql); length($conn1->errorMessage) && print $conn1->errorMessage."\n";
		my(@res2) = $qy1->fetchrow;
		my $lid = $res2[0];
		my $sql = "insert into lang (lid,voter_id) values ($lid,$voter_id)";
		#print "$sql\n";
		$qy1 = $conn1->exec($sql); 
		length($conn1->errorMessage) && print $conn1->errorMessage."\n";
	} else {
		my $sql = "select lid from bplaces where code='$birth_place'";
		#print "$sql\n";
		my $qy1 = $conn1->exec($sql); 
		$conn1->errorMessage && print $conn1->errorMessage."\n";
		my(@res2) = $qy1->fetchrow;
		my $lid = $res2[0];
		if($lid) {
			my $sql = "insert into lang (lid,voter_id) values ($lid,$voter_id)";
			#print "$sql\n";
			my $qy1 = $conn1->exec($sql); 
			$conn1->errorMessage && print $conn1->errorMessage."\n";
		} else {
			my $sql = "insert into lang (lid,voter_id) values (1,$voter_id)";
			#print "$sql\n";
			my $qy1 = $conn1->exec($sql); 
			$conn1->errorMessage && print $conn1->errorMessage."\n";
		}
	}
}
