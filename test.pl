#!/usr/bin/perl
use strict;
use warnings;
use Pg;
my $pghost="spark";
my $pgport="5432";
my $pgoptions ="";
my $pgtty =""; 
my $dbname ="elect";
my $login="elect";
my $pwd ="";
my $conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);

my $sql = q( SELECT a.attname as "Column", pg_catalog.format_type(a.atttypid, a.atttypmod) as "Datatype" FROM pg_catalog.pg_attribute a WHERE a.attnum > 0 AND NOT a.attisdropped AND a.attrelid = ( SELECT c.oid FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relname ~ '^(voters)$' AND pg_catalog.pg_table_is_visible(c.oid)) order by a.attname desc);

my $res = $conn->exec($sql);
while(my(@row) = $res->fetchrow) {
	foreach(@row) {
		if($row[0] =~ /^e[09][\d]{5}/) {
			print "$row[0]\n";
		}
	}
}
