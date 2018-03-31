package Elect;
use Elect::Db;
sub	new	{
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->initialize();
	return $self;
}

sub	initialize	{
	my $self = shift;
	$self->{db} = Elect::Db->new();
}
1;
