use DBI;
use Elect;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );

$e = Elect->new();
$db = $e->{db};
$db->connect();

open(V,"</mnt/cdrom/MVF - OCT 26, 2004.txt") || die "open: $!";
$_ = <V>;
chop;
chop;
s/\"//g;
@F = split(/,/);
# can't have numeric column names so election history cols are prepended with 'E'
for ( $f = 0 ; $f <= $#F ; $f++ ) {
	if($F[$f] =~ /^[0-9]/) {
		$F[$f] = "E" . $F[$f];
	}
}
open(EXCEPT,">mvf041026.except.$$");
$delta = 0.0;
while(<V>) {
	$line = $_;
	if(!($. % 25000)) { # show progress
		print "$. " . `/bin/date`
	}
	chop;
	chop;
	if(/[^\"0-9\,],/ || /,[^\"0-9\,]/) {
		s/([^"0-9\,])(,)/$1/;
		s/(,)([^"0-9\,])/$2/;
	}
	s/"//g;
	@V = split(/,/);
	for($i = 0 ; $i <= $#V ; $i++ ) {
		next if($F[$i] eq "city");
		if($i == $#V) {
			$voter_id = $V[$#V];
			if(!length($voter_id)) {
				print "null: $voter_id : $V[0]\n";
			}	
			if($voter_ids{$voter_id}) {
				print "duplicate: $voter_id : $affidavit{$voter_id}\n";
			}
			$voter_ids{$voter_id} = 1;	
			$affidavits{$voter_id} = $affidavit;
		}
		if($F[$i] eq "BART") {
			$V[$i] =~ s/^[A-Z]//;
		}
		if($F[$i] eq "street") {
			$V[$i] =~ s/\"//g;
			$V[$i] =~ s/^[\s]*//g;
			$V[$i] =~ s/[\s]*$//g;
		} 
		if($F[$i] eq "precinct") {
			$V[$i] =~ s/\"//g;
			$V[$i] /= 100;
		}
		if($V[$i] =~ /'/) {
			$V[$i] =~ s/'/\\'/g;
		}
		if($F[$i] eq "reg_date") {
			$V[$i] = &fix_date($V[$i]) ;
		} 
		if($F[$i] eq "birth_date") {
			if(length($V[$i])) {
				$V[$i] = &fix_date($V[$i]);
			} else {
				$V[$i] = "NULL";
			}
		}
		$V[$i] =~ s/[\s]*$//;
		$V[$i] =~ s/^[\s]*$//;
		if(!length($V[$i])) {
			$V[$i] = "NULL";
		} else {
			$V[$i] =~ s/^[\s]*//g;
			$V[$i] =~ s/[\s]*$//g;
		} 
		$V[$i] = "\'$V[$i]\'" unless (($V[$i] =~ /^[0-9]+$/) || ($V[$i] eq "NULL"));
		#if($F[$i] eq "apartment_number" && ($V[$i] ne "NULL")) {
		#	print "$V[$i]\n";
		#}
		
		push(@cols,$F[$i]);
		push(@vals,$V[$i]);
	}
	#$db->do("insert into vid (voter_id) values ($voter_id)");
	my $sql = "insert into mvf041026 ";
	if($#cols  != $#vals) {
		print "here\n";
	}
	pop(@cols) while(!length($cols[$#cols-1]));
	$sql .= "(" . join(",",@cols) . ")  ";
	$sql .= " values (" . join(",",@vals) . ")  ";
	$sql =~ s/"'/'/g;
	$sql =~ s/'"/'/g;
	$t0 = [gettimeofday];
	$qy = $db->do($sql);
	#$elapsed = tv_interval($t0);
	#if($elapsed > $delta) {
	#	print "$elapsed\n";
	#	$delta = $elapsed;
	##} else {
	#	$delta = $elapsed;
	#}
	if($qy) {
		if($db->{err}) {
			if($db->{err} =~ /INSERT has more target columns than expressions/) {
				print "here\n";
			}
			print EXCEPT "$line\t$db->{err}\n" unless ($db->{err} =~ /duplicate/i);
		}
	} else {
			print EXCEPT "$line\t$db->{err}\n" unless ($db->{err} =~ /duplicate/i);
	}
	$sql = "";
#	print "$sth\n";
	undef(@cols);
	undef(@vals);
}
close EXCEPT;

sub	fix_date	{
	$datetime = shift;
	($date,$time) = split(/\ /,$datetime);
	($m,$d,$y) = split(/\//,$date);
	$datetime = $y . "-" . $m . "-" . $d ;
	return($datetime);
}
