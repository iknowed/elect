#!/usr/local/bin/perl
$ENV{PGUSER}='elect';
use DBI;
use URI::Escape;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
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
                                                                                
print <<EOF;
Content-Type: text/html


<HTML><HEAD><TITLE>Voters by Address</TITLE></HEAD><BODY>
EOF

if($ENV{REQUEST_METHOD} eq "GET") {
	$QUERY_STRING = $ENV{QUERY_STRING};
}
if(($ENV{REQUEST_METHOD} eq "POST") && $ENV{CONTENT_LENGTH}) {
	while(<>) {
		$QUERY_STRING .= $_;
	}
}

	print "<HTML><HEAD><TITLE>Campaign</TITLE></HEAD><HTML><BODY>\n";
	$QUERY_STRING =~ s/\+/ /g;
	(@elts) = split("\&",$QUERY_STRING);
	foreach (@elts) {
		($tag,$val) = split("\=");
		$Elts{$tag} = uri_unescape($val);
		#print "$tag: $Elts{$tag}<br>\n";
	}
	foreach $tag ( keys %Elts ) {
		$val = $Elts{$tag};
		#print "$tag: $val\n";
	}
	$street = $Elts{street};
	$hnum = $Elts{house};
	$sql = "select name_first,name_last,phone,birth_place,party,voter_id,apartment_number,age(birth_date) from mvf where street='$street' and house_number=$hnum";

	$sth = $conn->exec($sql);
	$msg .= $conn->errorMessage;
	while(my(@row) = $sth->fetchrow) {
		$fname = shift(@row);
		$lname = shift(@row);
		$phone = shift(@row);
		$bplace = shift(@row);
		$party = shift(@row);
		$voter_id = shift(@row);
		$apartment_number = shift(@row);
		$age = shift(@row);
		(@a) = split(/ /,$age);
		$age = $a[0];
		if($apartment_number =~ /[\d]/) {
			$house = "$hnum $street # $apartment_number";
		} else {
			$house = "$hnum $apartment_number $street";
		}
		$a = $age[0];
print << "EOF";
<TABLE BORDER=2>
     <TR><TD>Fname, Lname: <TD>$fname $lname</TD></TR>
      <TR><TD>Phone:</TD><TD><b>$phone</b></TD></TR>
      <TR><TD>Addr:</TD><TD>$house</TD></TR>
      <TR><TD>Birth Place</TD><TD>$bplace</TD>
      <TR><TD>Age:<TD>$age</TD></TR>
      <TR><TD>Party:</TD><TD>$party</TD></TR>
</TABLE>
EOF
	}
