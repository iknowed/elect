#!/usr/local/bin/perl

use Elect;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$qy = $db->do("select * from ass where ex='t' and street is not null");
$seq = 0;
open(BAD,">bad");
open(BADDER,">badder");
$goo = select(BAD); $| = 1; select($goo);
$goo = select(BADDER); $| = 1; select($goo);
while(my (@res) = $qy->fetchrow) {
	if(!($seq % 10000)) {
		print "$seq\n";
	}
	$seq++;
	my $a0 = $res[2];
	my $an = $res[3];
	my $street = $res[4];
	my $apartment_number = $res[5];
	my $name = $res[7];
	$name =~ s/ & / /g;
	$name =~ s/\-/ /g;
	my (@toks) = split(" ",$name);
	my(@lnames);
	my(@fnames);
	$street =~ s/\'/\\'/g;
	$corp = 0;
if(0){
	foreach  my $tok (@toks) {
		if(($tok eq "LLC") || ($tok eq "LP") || ($tok =~ /PARTNER/)
		|| ($tok =~ /PROPERTY/) || ($tok =~ /CITY/)
		|| ($tok eq "THE") || ($tok eq "ASSET")
		|| ($tok eq "HOTEL") || ($tok =~ /ASSOCS/) || ($tok eq "CORP")
		|| ($tok eq "CO") || ($tok =~ /^[\d]+$/) 
		|| ($tok =~ /SURVIV/)) {
			$corp = 1;
			last;
		}
	}
	next if($corp);
}
	#	next if(length($tok) == 1);
	#	if($tok =~ /'/) {
	#		$tok =~ s/\'/\\'/g;
	#	}
	#	push(@lnames," name_last like '%$tok%' ");
	#	push(@fnames," name_first like '%$tok%' ");
	#}
	#$lname = "(" . join(" or ",@lnames) . ")";
	#$fname = "(" . join(" or ",@fnames) . ")";
	#if(($#lnames == -1) && ($#fnames == -1 ))  {
	#	next;
	#}
	my  $apt_num_sql;
	if($apartment_number) {
		$apartment_number =~ s/\'/\\'/g;
		if($apartment_number =~ /[A-Z]/) {
			$apt_num_sql = " and apartment_number like '%$apartment_number%' ";
		} else {
			$apt_num_sql = " and apartment_number = '$apartment_number' ";
		}
	} else {
		$apt_num_sql = " and apartment_number is null";
	}
	for (my $a = $a0 ; $a <= $an ; $a+=2 ) {
		my $sql = "select voter_id from mvf where street='$street' and house_number=$a $apt_num_sql ";
		my $qy = $db->do($sql);
		if($qy) {
			while(my (@row) = $qy->fetchrow()) {
				$voter_id = $row[0];
				my $upd = "update ten set tenant='f' where voter_id = $voter_id and tenant != 'f'";
				$res = $db->do($upd);
				$stat = $res->cmdStatus();
				($res,$cnt) = split(" ",$stat);
				if($cnt == 0) {
					print BAD "street='$street' house_number=$a $apt_num_sql\n";
				} else {
					print "$seq +$cnt\n";
				}
			}
			#if($cnt > 0) {
			#	print "$seq: +$cnt\n";
			#} 
			#if($cnt >= 5) {	
			#	print "here\n";
			#}
			#$good++;
		} else {
			print "$seq: bad\n";
			print BADDER "street='$street' house_number=$a $apt_num_sql\n";
			$bad++;
		}
	}
}
