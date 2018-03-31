#!/usr/local/bin/perl
$ENV{PGUSER}='elect';
$ENV{REMOTE_USER}='green';
$ENV{REMOTE_ADDR}='63.197.145.74';
open(LOG,"<log");
$ENV{REQUEST_METHOD}='GET';
while(<LOG>) {
	next unless (/ross/ && /phone.pl/);
	next if(/oldphone.pl/);
	next unless(/ACTION=NEXT/);
	(@fields) = split("\ ");
	($path,$qs) = split('\?',$fields[6]);
	$ENV{QUERY_STRING}=$qs;
	print "$qs\n";
	system("/usr/local/bin/perl phone.pl BULK &> /dev/null");
}
