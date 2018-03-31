package Elect::Db;
use Postgres;

sub	new	{
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
#	$self->initialize();
	return $self;
}

sub	connect	{
	my  $self = shift;
	$self->{conn} = db_connect("elect");
	return($self->{conn});
}

sub	do	{
	my ($self) = shift;
	my ($sql) = shift;
	undef($self->{err});
	my $dbh = $self->{conn};
	$result = $dbh->execute($sql);
	$self->{err} = $dbh->errorMessage() if(!$result);
	return($result);
}

sub	doFile	{
	my ($self) = shift;
	my ($file) = shift;
	open(FILE,"<$file") || return(undef);
	@lines = <FILE>;
	$sql = join("",@lines); 
	$result = $self->do($sql);
	return($result);	
}
1;
