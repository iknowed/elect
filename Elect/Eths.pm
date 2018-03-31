Package Elect::Eth;
use strict;
use warnings;

sub	new	{
	my($class,$eths) = shift;

	my $self = { eths => $eths };

	bless($self,$class);

	return($self);
}

sub	makeWheres	{
	my($self) = shift;
	my(@wheres);
	@eths = @{$self->{eths}};
	if($#eths > -1) {
		my(@e);
		foreach $eid(@eths) {
			push(@e,"(  $mvf.voter_id in ( select voter_id from eth where eth.eid=$eid ) )");
		}
		if($#eths== 0) {
			push(@owheres,$e[0]);
		} else {
	}
	$self->{wheres} = \@wheres;	
}

1;
