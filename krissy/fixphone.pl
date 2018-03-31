#!/usr/local/bin/perl
                                                                               
#  option to declare SECOND!!!
#  Absentee PERM
                                                                               
$ENV{PGUSER}='elect';
use DBI;
use URI::Escape;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
                                                                               
                                                                               
                                                                               
$e = Elect->new();
$db = $e->{db};
$db->connect();
$cmpid = 15; 

$sql = "select campaign||'_'||phonelist from phone,cmp where (phone.cmpid=$cmpid and (phone.cmpid=cmp.cmpid))";
$sth = $db->do($sql);
while(my(@row) = $sth->fetchrow) {
      $phonetbl = $row[0];
      $sql = "update $phonetbl set stat=3 from canv where ($phonetbl.voter_id=canv.voter_id)";
      $sti = $db->do($sql);
   }

