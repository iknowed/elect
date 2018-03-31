use Postgres;
use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();
$db->do("drop table av cascade");
$result = $db->doFile("sql/av.sql");
#$db->do("CREATE TRIGGER vid_trigger BEFORE INSERT ON av FOR EACH ROW EXECUTE PROCEDURE vid_trigger();");
