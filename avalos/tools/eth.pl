#!/usr/local/bin/perl
use Pg;
use DBI;

$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty ="";
$dbname ="elect";
$login="elect";
$pwd ="";
my $conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

$conn->exec("drop sequence ethnicities_eid_seq");
$conn->exec("create sequence ethnicities_eid_seq");
$conn->exec("drop table ethnicities cascade");
$conn->exec("drop table eth cascade");

open(SQL,"<sql/eth.sql");
my $sql = join("",<SQL>);
	$conn->exec($sql);
if($conn->errorMessage) 
{
	print $conn->errorMessage . "\n";
}
