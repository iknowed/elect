package Elect::Ass::AIAOWNR;

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
	my $self = shift;
	my $db = $self->{db};
	#$db->do("drop table ass cascade");
	#$result = $db->doFile("sql/ass.sql");
	open(OWN,"<$self->{file}");
	while(<OWN>) {
		chop;
		($block,$lot) = split(" ",substr($_,3,9));
		next unless(length($lot) && length($block));
		$own = substr($_,14,30);
		$own =~ s/\'/\\'/g;
		$own =~ s/[\s]*$//;
		$own = "'" . $own . "'";
		$own =~ s/\s[A-Z]\s/\ /g;
		$block = "'" . $block . "'";
		$lot = "'" . $lot . "'";
		$sql = "update ass set name=$own where block=$block and lot=$lot";
		my $res = $db->do($sql);
		if($res) {
			$good++;
		} else {
			$bad++;
		}	
	}
}


1;
