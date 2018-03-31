package Elect::Ass::AIASECD;

sub	new	{
	my $this = shift;
	my $file = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->{file} = $file;
	return $self;
}

sub	init	{
	my $self = shift;
	my $db = shift;

	$self->{db} = $db;
}

sub	load	{
	my($self) = shift;
	my($db) = $self->{db};
	$db->do("drop table ass cascade");
	$result = $db->doFile("sql/ass.sql");

for($m = 2 ; $m <= 4 ; $m++ ) {
	open(MULTI,"</d/voters/pg/multi.$m") || die "open: $!";
	while(<MULTI>) {
		chop;
		$multis{$m}{$_} = 1;
	}
}
open(AIA,"<$self->{file}") || die "open: $!";

while(<AIA>) {
	chop;
	chop;
	$blockandlot = substr($_,3,9);
	($block,$lot) = split(" ",$blockandlot);
	$loc = substr($_,12,36);
	next if($loc =~ /^[\s]*$/);
	$yr = substr($_,49,2);
	$hoe0 = substr($_,88,9);
	$hoe1 = substr($_,147,9);
	$yrblt = substr($_,333,4);
	$ex = 't';
	$ex = 'f' unless (($hoe0 == 7000) || ($hoe1 == 7000));
	next if ($loc =~ /^[\s]*$/);
	next if(!$block || !$lot);
	$loc =~ s/ EAST/E/g;
	$loc =~ s/ALLICE/ALICE/g;
	$loc =~ s/ WEST/W/g;
	$loc =~ s/ NORTH/N/g;
	$loc =~ s/ SOUTH/S/g;
	undef $apt,$street,$apartment_number,$type,$a0,$an;
	my($multi_street_name);
	$multi_house_nums= 0;
	$foo = $_;
	$_ = $loc;
	if(/([\d]+)[A-Z]*[\s]*\-[\s]*([\d]+)[A-Z]*/) {
		$multi_house_nums = 1;
		$a0 = $1;
		$an = $2;
	} else {
		m/^([\d]+)/;
		$a0 = $1;
		$an = $1;
	}
	foreach $m ( reverse sort { $a <=> $b } keys  %multis ) {
		$multi = $multis{$m};
		last if($multi_street_name);
		foreach $mi ( keys %{$multi} ) {
			next if($mi =~ /^[\s]*$/);
			if(/$mi/) {
				s/$mi/\"$mi\"/;
				$multi_street_name = $m;	
				last;
			}
		}
	}
	if(!$multi_street_name) {
		s/[\s]+([A-Z\']+)/"$1"/;
	}
	s/([\d])\-/$1/;
	$loc = $_;
	$_ = $loc;
	my($street,$type,$apt,$apartment_number);
	($street,$type,$apt) = m/^.*?"([\w\s\']+)"[\s]*([A-Z]*)[\s]*(.*)$/;
	undef $apt if($apt =~ /STREET/ || $apt =~ /ST/ || $apt =~ /AV/ || $apt =~ /TER/);
	if($street =~ /^0[0-9]/) {
		$street =~ s/^0//;
	}
	next if($a0 =~ /^[\s]*$/ || $street =~ /^[\s]*$/);
	undef($apt_sql0);
	undef($apt_sql1);
	if($apt) {
		$apt =~ s/UNIT//;
		$apt =~ s/[\s]+$//;
		$apt =~ s/^[\s]+//;
		$apt =~ s/\#//;
		$apt =~ s/\'/\\'/g;
		$apt_sql0 = ", apartment_number";
		$apt_sql1 = ",'$apt'";
	}
	undef $apt,$apt_sql0,$apt_sql1 unless ($apt =~ /[\d]*/ && (!$apt =~ /[A-Z]{2}/));
	$_ = $foo;
	$street =~ s/[\s]+$//;
	$street =~ s/^[\s]+//;
	$street =~ s/\'/\\'/g;
	$yrblt .= "0101";
	#$ex = 't';
	#$sql = "insert into ass set block='$block',lot='$log',yrblt=$yrbltAD,ex='t',a0=$a0,an=$an,street='$street' $apt_sql ";
	$sql = "insert into ass (block,lot,yrblt,ex,a0,an,street $apt_sql0) values ('$block','$lot','$yrblt','$ex',$a0,$an,'$street' $apt_sql1) ";
	#print "$sql\n";
	$res = $db->do($sql);
	if($res){
		$val = $res->cmdStatus();
		$good++;
	} else {
		$bad++;
	}
}
}

1;
