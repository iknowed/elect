use Pg;
use DBI;
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty =""; $dbname ="elect";
$login="elect";
$pwd ="";
$conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

1;
