#!/usr/bin/perl
use Pg;
use DBI;
use URI::Escape;
$pghost="spark";
$pgport="5432";
$pgoptions ="";
$pgtty ="";
$dbname ="elect";
$login="elect";
$pwd ="";
$conn = Pg::setdbLogin($pghost, $pgport, $pgoptions, $pgtty, $dbname, $login, $pwd);
$date = `/bin/date`;
$cmpid=19;
#$cut="061023";
$mvf="voters";
if(length($ENV{QUERY_STRING})) {
	$_ = $ENV{QUERY_STRING};
} else {
	$_ = <>;
}

open(QS,">/tmp/qs");
print QS;
close QS;
$postdata = $_;
(@args) = split(/&/);
open(FOO,">/tmp/foo1");
print FOO;
close  FOO;
my $content_type = "application/pdf";
foreach (@args) {
	($tag,$val) = split(/\=/);
	$tag = uri_unescape($tag);
	$val =~ s/%%20/%/g;
	$val = uri_unescape($val);
	$tag =~ s/\+/ /g;
	$val =~ s/\+/ /g;
	$Args{$tag} = $val;
	if($tag eq "where") { 
		$where = $val;
	}
	if($tag eq "from") { 
		$from = $val;
	}
	if($tag =~ /^arg/) {
		$tag =~ s/arg//;
		$arg[$tag] = $val;
	}
}

$sql = "select typeid from listtypes where code='$Args{type}'";
$qy = $conn->exec($sql);
my(@row) = $qy->fetchrow;
$type = $row[0];

$query = $where;
$query =~ s/\'/\\\'/g;
$sql = "insert into lists (tag,title,cmpid,generated,tbl,query,type) values ('$Args{tag}','$Args{title}',$cmpid,1,'$mvf','$query',$type)";
$qy = $conn->exec($sql);
print FOO "$sql\n";
if($Args{type} eq 'W') {
		&walk($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'M') {
&mail($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'P') {
&phone($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'E') {
&email($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'R') {
&robo($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'V') {
&voterid($Args{where},$Args{title},$Args{hh},$$);
}
if($Args{type} eq 'S') {
&sweep($Args{where},$Args{title},$Args{hh},$$);
}
$tmpfile = "/tmp/$$";
open(PDF,"<$tmpfile") || die "open: $!";
binmode(PDF);
print "content-type:  $content_type\n\n";
binmode(STDOUT);
while(<PDF>) { print STDOUT; }
close PDF;
close STDOUT;
#unlink($tmpfile);



sub	phone	{
	my($where,$title,$hh,$pid) = @_;
#print FOO "$where , $pid\n";
#$camp = "Q For Mayor";
my %voters,%precincts;
my $lang = "";
$sql = "select bplace,code from bplaces";
my $qz = $conn->exec($sql);
my %bplaces;
while(my(@row) = $qz->fetchrow) {
	$code = $row[1];
	$bplace = $row[0];
	$bplaces{$code} = $bplace;
}
$sql = "select bplace,code from bplaces";
my $qz = $conn->exec($sql);
my %bplaces;
while(my(@row) = $qz->fetchrow) {
	$code = $row[1];
	$bplace = $row[0];
	$bplaces{$code} = $bplace;
}
$sql = "select st from us";
my $qz = $conn->exec($sql);
my %us;
while(my(@row) = $qz->fetchrow) {
	$st = $row[0];
	$us{$st} = 1;
}
$f = "$from,lang,langs";
$sql = "select distinct($mvf.voter_id),phone,street,type,house_number,apartment_num,now()-birth_date,birth_place,gender,party,name_prefix,name_last,name_first,gender,perm_category,e060606,e051108,e041102,e040302,e031209,precinct,langs.language from $f $where and lang.lid=langs.lid and $mvf.voter_id=lang.voter_id order by precinct,phone";
open(FOO,">>/tmp/foo1");
print FOO "\n$sql\n";
close FOO;
my $qy = $conn->exec($sql);
#$arg[0]="arg0";
#$arg[1]="arg1";
#$arg[2]="arg2";
#$arg[3]="arg3";
#$arg[4]="arg4";
#$arg[5]="arg5";
#$arg[6]="arg6";
#$arg[7]="arg7";
my %blocks;
$page_max = 26;
#.fp 3 Free3of9 goes after .po
$page_header_orig=<<EOF;
.ll 7.5i
.in .25i
.po .25i

.TS
expand;
L C C L
L C.
Pct PCT	CAMP	TITLE	DATE	Pg \\n%
BLOCK Block	STREET	EVENODD	
.TE


.TS
expand;
L | L | L | C | C | C | C | C | C | C
L L L C C C C C C C.
Num [apt]	First	Last	Party	Gender	Age	Birth	VBM	History	voter_id
=
.ll 7.5i
.po .25i
EOF
$addrcnt=0;$oddcnt=0;
my %Streets;
while(my (@voter) = $qy->fetchrow) {
$i = 0;
$voter_id = $voter[$i++];
$phone = $voter[$i++];
$street = $voter[$i++];
$type = $voter[$i++];
$house_number = $voter[$i++];
$apartment_number = $voter[$i++];
$birth_date = $voter[$i++];
$birth_place = $voter[$i++];
$gender = $voter[$i++];
$party = $voter[$i++];
$name_prefix = $voter[$i++];
$name_last = $voter[$i++];
$name_first = $voter[$i++];
$gender = $voter[$i++];
$perm  = $voter[$i++];
$e1 = $voter[$i++];
$e2 = $voter[$i++];
$e3 = $voter[$i++];
$e4 = $voter[$i++];
$e5 = $voter[$i++];
$precinct = $voter[$i++];
$language = $voter[$i++];
my $tot = 0;
$tot++ if(($e1 eq "V") || ($e1 eq "A"));
$tot++ if(($e2 eq "V") || ($e2 eq "A"));
$tot++ if(($e3 eq "V") || ($e3 eq "A"));
$tot++ if(($e4 eq "V") || ($e4 eq "A"));
$tot++ if(($e5 eq "V") || ($e5 eq "A"));
my $pct = (1.0*$tot)/(5.0);
#$lang = $voter[$i++];


	$phone =~ s/^415//;
	if(length($phone) == 7) {
		substr($phone,3,0) = "-";
	}
	($days) = ( $birth_date =~ m/^([\d]+) /);
        $age = int(($days / 365)+.5);
	$party =~ s/[\s]*//g;
	$party = substr($party,0,3);
	if($party eq "NP-") {
		$party = "DTS";
	}
	$birth_place = $bplaces{$birth_place} unless $us{$birth_place};
	$name_prefix =~ s/ //g;
	$name_last =~ s/\s//g;
	$vid = "*$voter_id*";
	$st = substr($street,0,10);
	$apartment_number = "|$apartment_number|" if(length($apartment_number));
	my $v = "$house_number  $apartment_number	$name_first	$name_last	$party	$gender	$age	$birth_place	$perm	[$e1|$e2|$e3|$e4|$e5]	$voter_id\n";
	if(!length($arg[7])) { 
		$arg[7] = $precinct; 
	}
	if(!length($arg[5])) { 
		$arg[5] = $language; 
	}
	$v .= "$st	$phone	$arg[1]	$arg[2]	$arg[3]	$arg[4]	$arg[5]	$arg[6]	$arg[7]	\\s16\\f3$vid\\fR\\s0\n_\n";
	if($arg[7] == $precinct) {
		undef($arg[7]);
	}
	if($arg[5] == $language) {
		undef($arg[5]);
	}
	push(@pcts ,$precinct);
	push(@addrs,$v);
}
#print "$#addrs\n";
$tmpfile = "/tmp/$pid";
open(CK,">addr");
$addrCnt = 1;
$oddCnt = 1;
$district = &pct2dist($pct);
#$pageMax = 15;

if($#addrs != -1) {
	$precinct = $pcts[0];
	if(length($a)) { 
		$a .= ".TE\n.bp\n";
	}
	$h = $page_header_orig;
	$h =~ s/CAMP/$camp/;
	$h =~ s/PCT/$precinct/;
	$h =~ s/TITLE/$title/;
	#$h =~ s/Pct/$precinct/;
	$h =~ s/Block//;
	$h =~ s/DATE/$date/;
	$h =~ s/BLOCK//;
	$h =~ s/STREET//;
	$h =~ s/EVENODD/Phone List/;
	$a .= $h;
	$addrCnt = 1;
}
$i = 0;
foreach $n (@addrs) {
	if($addrCnt++ == $page_max) {	
		$precinct = $pcts[$i];
		if(length($a)) {
			$a .= ".TE\n.bp\n";
		}
		$h = $page_header_orig;
		$h =~ s/Block//;
		$h =~ s/CAMP/$camp/;
		$h =~ s/PCT/$precinct/;
		#$h =~ s/Pct/$precinct/;
		$h =~ s/TITLE/$title/;
		$h =~ s/DATE/$date/;
		$h =~ s/BLOCK//;
		$h =~ s/STREET//;
		$h =~ s/EVENODD/Phone List/;
		$a .= $h;
		$addrCnt = 1;
	}
	$a .= $n;
	$i++;
}
open(ADDR,"|/usr/bin/groff -t | ps2pdf - > $tmpfile");
print ADDR "$a\n.TE";
close(ADDR);
#print CK "$a\n.TE";
#print ADDR "$a\n.TE";
#print "$ef\n";
#print "$of\n";
close ADDR;
}

sub	pad	{
	my($fld,$len) = @_;
	$fld =~ s/^[\s]*//g;
	$fld =~ s/[\s]*$//g;
	if(length($fld) < $len) {
		$fld .= " " x ($len - length($fld));
	}
	return($fld);
}

sub	pct2dist	{
	my ($pct) = shift;
	if(int($pct / 1000) == 1) {
		return(11);
	}
	$dist = int ( ( $pct - (1000 * int( $pct / 1000 ) ) ) / 100) ;
	if($dist == 0) { $dist = 10; }
	return($dist);
}

sub	getBarcode	{
	my $aff = shift;
	my $ua = LWP::UserAgent->new;	
	my $req = HTTP::Request->new(GET => "http://cybre.net/bc/bc39.pl?$aff");
	my $res = $ua->request($req);
	if($res->is_success) {
		open(PNG,">/home/marc/aff/$aff.png");
		binmode(PNG);
		print PNG $res->content;
		close PNG;
	}
	return("file:///home/marc/aff/$aff.png");
}

sub	wrapUpBlock	{
	my($Blocks,$blockOn,$streetOn,$as) = @_;
	my @a = @{$as};
	return if($blockOn == -1 || ($#a == -1));
	$Blocks{$streetOn}{$blockOn}->{A} = \@a;	
}


sub	walk	{
	my($where,$title,$hh,$pid) = @_;

	$date = `/bin/date`;
	chop($date);
	#$camp = "Chris Daly 2004";
	my $sql = "select distinct precinct from $from $where";
	my $qy = $conn->exec($sql);
	while(my $pct = $qy->fetchrow) {
		my %voters,%precincts;
		$sql = "select phone,street, type, house_number, $mvf.voter_id, apartment_num, now()-birth_date,birth_place, gender, party, name_prefix,name_last,name_first,gender,perm_category, e060606, e051108, e041102, e040302, e031209, precinct from $from $where order by precinct asc, street, house_number";
	
		if(!length($pvi)) {
			my $sql = "select pvi_new from pvi where pct=$pct";
			$qy = $conn->exec($sql);
			(@r) = $qy->fetchrow;
			$pvi = $r[0];
		}
		$q = "select count(distinct($mvf.voter_id)) from $mvf $where ";
		my $qq = $conn->exec($q);
		if($qq) {
		(@r) = $qq->fetchrow;
		$cnt = $r[0];
	}
	#print "count: $cnt\n";
	my $qy = $conn->exec($sql);
	
	
	$sql = "select bplace,code from bplaces";
	my $qz = $conn->exec($sql);
	my %bplaces;
	while(my(@row) = $qz->fetchrow) {
		$code = $row[1];
		$bplace = $row[0];
		$bplaces{$code} = $bplace;
	}
	$sql = "select bplace,code from bplaces";
	my $qz = $conn->exec($sql);
	my %bplaces;
	while(my(@row) = $qz->fetchrow) {
		$code = $row[1];
		$bplace = $row[0];
		$bplaces{$code} = $bplace;
	}
	my %us;
	while(my(@row) = $qz->fetchrow) {
		$st = $row[0];
		$us{$st} = 1;
	}
	my %blocks;
	$page_max = 26;
	$page_header_orig=<<EOF;
.ll 7.5i
.in .25i
.po .25i
.fp 3 Free3of9
.TS
expand;
L C C L
L C.
Pct PCT	CAMP	TITLE	DATE	Pg \\n%
BLOCK Block	STREET	EVENODD Walk List
.TE
.TS
expand;
L | L | L | C | C | C | C | C | C | C
L | L | L | C | C | C | C | C | C | C
L L L C C C C C C C.
Num [apt]	First	Last	Phone	Party	Gen	Age	Bplace	Abs	History
Street	Last							voter_id	Barcode
=
.ll 7.5i
.po .25i
EOF
	
	#$page_max = 20;
	$evencnt=0;$oddcnt=0;
	my %Streets;
	while(my (@voter) = $qy->fetchrow) {
		$cnt--;
		$i = 0;
		$phone = $voter[$i++];
		$street = $voter[$i++];
		$type = $voter[$i++];
		$house_number = $voter[$i++];
		$voter_id = $voter[$i++];
		$apartment_number = $voter[$i++];
		$birth_date = $voter[$i++];
		$birth_place = $voter[$i++];
		$gender = $voter[$i++];
		$party = $voter[$i++];
		$name_prefix = $voter[$i++];
		$name_last = $voter[$i++];
		$name_first = $voter[$i++];
		$gender = $voter[$i++];
		$perm  = $voter[$i++];
		$e1 = $voter[$i++];
		$e2 = $voter[$i++];
		$e3 = $voter[$i++];
		$e4 = $voter[$i++];
		$e5 = $voter[$i++];
		$precinct = $voter[$i++];
		my $tot = 0;
		$tot++ if(($e1 eq "V") || ($e1 eq "A"));
		$tot++ if(($e2 eq "V") || ($e2 eq "A"));
		$tot++ if(($e3 eq "V") || ($e3 eq "A"));
		$tot++ if(($e4 eq "V") || ($e4 eq "A"));
		$tot++ if(($e5 eq "V") || ($e5 eq "A"));
		my $pct = (1.0*$tot)/(5.0);
		$lang = $voter[$i++];
	
	
		if(!length($phone)) {
			$phone = " ";
		}
		($days) = ( $birth_date =~ m/^([\d]+) /);
        	$age = int(($days / 365)+.5);
		$party =~ s/[\s]*//g;
		$party = substr($party,0,3);
		$thisStreet = "$street $type";
		$thisBlock =  100 * ( int ( $house_number / 100 ) );
	
		if(($thisBlock ne $blockOn) || ($thisStreet ne $streetOn)) {
			&wrapUpBlock(\%Blocks,$blockOn,$streetOn,\@evens,\@odds);
			undef(@evens);
			undef(@odds);
			$blockOn = $thisBlock;
			$streetOn = $thisStreet;
		} 
		$name_prefix =~ s/ //g;
		$name_last =~ s/\s//g;
		$phone =~ s/^415//;
		if(length($phone)>4) {
			substr($phone,3,0) = '-';
		}
		$bplace = $bplaces{$birth_place};
		$sql = "select ethnicities.ethnicity where ethnicities.eid in (select distinct(ethnicities.eid) from snames,ethnicities where snames.surname='$name_last' and ethnicities.eid=snames.eid)";
		$sth = $conn->exec($sql);
		my($eth);
		if($sth) {
			my(@eths) = $sth->fetchrow;
			$neths = $sth->ntuples();	
			if($neths == 1) {
				$eth = $eths[0];
			} 
		}
		$birth_place = $bplace unless $us{$birth_place};
		#if(length($eth)) {
		#	$birth_place = $birth_place . "/$eth";
		#}
		#if((length($birth_place)) && !($Elect::States{$birth_place})) {
		#	$birth_place .= "/".$Elect::Places{$birth_place};
		#}
		$vid = "*$voter_id*";
		$apartment_number = "|$apartment_number|" if(length($apartment_number));
		my $v = "$house_number  $apartment_number	$name_first	$name_last	$phone	$party	$gender	$age	$birth_place	$perm	[$e1|$e2|$e3|$e4|$e5]\n";
		$v .= "$arg[1]	$arg[2]	$arg[3]	$arg[4]	$arg[5]	$arg[6]	$arg[7]	$arg[8]	";
		$v .= "$voter_id	\\s16\\f3$vid\\fR\\s0\n_\n";
		if($house_number % 2) {
			push(@odds,$v);
		} else {
			push(@evens,$v);
		}
	}
	&wrapUpBlock(\%Blocks,$blockOn,$streetOn,\@evens,\@odds);
	#print "count: $cnt\n";
	$eF = ">$pct"."E.html";
	$oF = ">$pct"."O.html";
	$pvi = int($pvi);
	open(OUT,"|/usr/bin/groff -t | /usr/bin/ps2pdf - > /tmp/$pid ") || die "open: $!";
	$evenCnt = 1;
	$oddCnt = 1;
	$district = &pct2dist($pct);
	#$pageMax = 15;
	
	$evenCnt=0;
	$oddCnt=0;
	foreach $street ( sort keys %Blocks ) {
		%Streets = %{$Blocks{$street}};
		foreach $block ( sort keys %Streets ) {
			my @evens = @{$Blocks{$street}{$block}{E}};
			my @odds = @{$Blocks{$street}{$block}{O}};
			if($#evens != -1) {
				if(length($e)) { 
					$e .= ".TE\n.bp\n";
				}		
				$pg = $evenCnt / $page_max;
				$h = $page_header_orig;
				$h =~ s/CAMP/$camp/;
				$h =~ s/PVI/$pvi/;
				$h =~ s/TITLE/$title/;
				$h =~ s/PCT/$precinct/;
				$h =~ s/DATE/$date/;
				$h =~ s/BLOCK/$block/;
				$h =~ s/STREET/$street/;
				$h =~ s/EVENODD/EVEN/;
				$e .= $h;
				$evenCnt = 1;
			}
			if($#odds != -1) {
				if(length($o)) { 
					$o .= ".TE\n.bp\n";
				}
				$pg = $evenCnt / $page_max;
				$h = $page_header_orig;
				$h =~ s/CAMP/$camp/;
				$h =~ s/PCT/$precinct/;
				$h =~ s/PVI/$pvi/;
				$h =~ s/TITLE/$title/;
				$h =~ s/DATE/$date/;
				$h =~ s/BLOCK/$block/;
				$h =~ s/STREET/$street/;
				$h =~ s/EVENODD/ODD/;
				$o .= $h;
				$oddCnt = 1;
			}
			#print "|$street|$block|E: $#evens O: $#odds\n";
			foreach $n (@evens) {
				if($evenCnt++ == $page_max) {	
					if(length($e)) {
						$e .= ".TE\n.bp\n";
					}
					$pg = $evenCnt / $page_max;
					$h = $page_header_orig;
					$h =~ s/CAMP/$camp/;
					$h =~ s/PCT/$precinct/;
					$h =~ s/TITLE/$title/;
					$h =~ s/DATE/$date/;
					$h =~ s/BLOCK/$block/;
					$h =~ s/STREET/$street/;
					$h =~ s/EVENODD/EVEN/;
					$h =~ s/EVENODD/EVEN/;
					$e .= $h;
					$evenCnt = 1;
				}
				$e .= $n;
			}
			foreach $n (@odds) {
				if($oddCnt++ == $page_max) {	
					if(length($o)) {
						$o .= ".TE\n.bp\n";
					}
					$pg = $evenCnt / $page_max;
					$h = $page_header_orig;
					$h =~ s/CAMP/$camp/;
					$h =~ s/TITLE/$title/;
					$h =~ s/PCT/$precinct/;
					$h =~ s/DATE/$date/;
					$h =~ s/BLOCK/$block/;
					$h =~ s/STREET/$street/;
					$h =~ s/EVENODD/ODD/;
					$o .= $h;
					$oddCnt = 1;
				}
				$o .= $n;
			}
			$a .= $e . ".TE\n.bp\n" if(length($e));
			$a .= $o . ".TE\n.bp\n" if(length($o));
			undef($e);
			undef($o);
		}
	}
}
print OUT "$a\n";
close OUT;
#close OUT;
}


sub	voterid {
	my($where,$title,$hh,$pid) = @_;
	$sql = "select distinct(voter_id) from $from $where and length(phone) = 10";
	$qy = $conn->exec($sql);
	open(TMP,">/tmp/$pid");
	while(my(@row) = $qy->fetchrow) {
		print TMP "$row[0]\n";
	}
	close TMP;
	$content_type = "text/plain";
}

sub	robo	{
	my($where,$title,$hh,$pid) = @_;
	$sql = "select distinct(phone) from $from $where and length(phone) = 10";
	$qy = $conn->exec($sql);
	open(TMP,">/tmp/$pid");
	while(my(@row) = $qy->fetchrow) {
		print TMP "$row[0]\n";
	}
	close TMP;
	$content_type = "text/plain";
}

sub	sweep {
	my($where,$title,$hh,$pid) = @_;
	$sql = "select distinct($mvf.voter_id),phone,name_first,name_middle,name_last,gender,age(birth_date) from $from $where and phone is not null and length(phone) = 10 order by voter_id";
	$qy = $conn->exec($sql);
	open(TMP,">/tmp/$pid");
	print TMP "PHONE,VOTER_ID,NAME_FIRST,NAME_MIDDLE,NAME_LAST,GENDER,AGE\n";
	while(my(@row) = $qy->fetchrow) {
		$row[6] =~ s/ years.*$//;
		print TMP join(",",@row)."\n";
	}
	close TMP;
	$content_type = "text/plain";
}


sub	email	{
	my($where,$title,$hh,$pid) = @_;
	$sql = "select distinct(email),name_first,name_last,voter_id,birth_date from $from $where and email is not null";
	$qy = $conn->exec($sql);
	open(TMP,">/tmp/$pid");
	while(my(@row) = $qy->fetchrow) {
		print TMP join(",",@row) ."\n";
	}
	close TMP;
	$content_type = "text/plain";
}

sub	mail	{
	my($where,$title,$hh,$pid) = @_;

	$qc = "select count(distinct(voter_id)) from $from $where ";
	$q = $conn->exec($qc);
	(@r) = $q->fetchrow;
	$qy = "select distinct(voter_id),name_prefix,name_first,name_last,house_number,street,type,apartment_num,pre_dir,house_fraction,zip from $from $where order by street,type,house_number,apartment_num,zip";
	$q = $conn->exec($qy);
	my(%households);
	$file = ">/tmp/$pid";
	open(OUT,$file);
	print OUT "NUM_AT_hh,VOTER_ID,NAME_PFX,NAME_F,NAME_L,HOUSE_NUM,STREET,TYPE,APT,PRE_DIR,HOUSE_FRACTION,ZIP\n";
	while(my(@row) = $q->fetchrow) {
		my $i = 0;
		my $voter_id = $row[$i++];
		my $name_prefix = $row[$i++];
		my $name_first = $row[$i++];
		my $name_last = $row[$i++];
		my $house_number = $row[$i++];
		my $street = $row[$i++];
		my $type = $row[$i++];
		my $apartment_number = $row[$i++];
		my $pre_dir = $row[$i++];
		my $house_fraction =  $row[$i++];
		my $zip  = $row[$i++];
		my $key = "$house_number\t$street\t$type\t$apartment_number\t$pre_dir\t$house_fraction\t$zip";
		if(length($hh)) {
			push(@{$households{$key}},"$voter_id\t$name_prefix\t$name_first\t$name_last");
		} else {
			my $line = "-1,$voter_id,$name_prefix,$name_first,$name_last,$house_number,$street,$type,$apartment_number,$pre_dir,$house_fraction,$zip\n";
			print OUT $line;
		}
	}
	if(length($hh)) {
		(@Keys) = keys %households;
		$n = $#Keys;
		foreach $key( keys %households ) {
			my (@a) = @{$households{$key}};
			my($id,$np,$nf,$nl);
			($id,$np,$nf,$nl) = split(/\t/,$a[0]);
			($num,$st,$ty,$apt,$pd,$hf,$zip) = split(/\t/,$key);	
			my $line = $#a+1 . ",$id,$np,$nf,$nl,$num,$st,$ty,$apt,$pd,$hf,$zip\n";
			print OUT $line;
		}
	}
	close OUT;
	$content_type = "text/plain";
}


sub	pad	{
	my($fld,$len) = @_;
	$fld =~ s/^[\s]*//g;
	$fld =~ s/[\s]*$//g;
	if(length($fld) < $len) {
		$fld .= " " x ($len - length($fld));
	}
	return($fld);
}

sub	pct2dist	{
	my ($pct) = shift;
	if(int($pct / 1000) == 1) {
		return(11);
	}
	$dist = int ( ( $pct - (1000 * int( $pct / 1000 ) ) ) / 100) ;
	if($dist == 0) { $dist = 10; }
	return($dist);
}

sub	getBarcode	{
	my $aff = shift;
	my $ua = LWP::UserAgent->new;	
	my $req = HTTP::Request->new(GET => "http://cybre.net/bc/bc39.pl?$aff");
	my $res = $ua->request($req);
	if($res->is_success) {
		open(PNG,">/home/marc/aff/$aff.png");
		binmode(PNG);
		print PNG $res->content;
		close PNG;
	}
	return("file:///home/marc/aff/$aff.png");
}

sub	wrapUpBlock	{
	my($Blocks,$blockOn,$streetOn,$es,$os) = @_;
	my @e = @{$es};
	my @o = @{$os};
	#print "E: $#e O: $#o\n";
	return if($blockOn == -1 || ($#e == -1 && $#o == -1));
	$Blocks{$streetOn}{$blockOn}->{E} = \@e;	
	$Blocks{$streetOn}{$blockOn}->{O} = \@o;	
}
