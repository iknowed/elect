#!/usr/local/bin/perl
use Elect::Db;
package Elect::Ass;
use Elect::Ass::AIAOWNR;
use Elect::Ass::AIASECD;
sub	new	{
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	return $self;
}

sub	init	{
	my $self = shift;

	$e = Elect->new();
	$self->{db}  = $e->{db};
	$db = $self->{db};
	$db->connect();


	$self->{AIAOWNR} = new Elect::Ass::AIAOWNR("/h/assess/aiaownr");
	$self->{AIAOWNR}->init($db);

	$self->{AIASECD} = new Elect::Ass::AIASECD("/h/assess/aiasecd");
	$self->{AIASECD}->init($db);

}

sub	load	{
	my $self = shift;
	$self->{AIASECD}->load();
	$self->{AIAOWNR}->load();
}

sub	index	{
	my $self = shift;
	$db = $self->{db};
	$db->do("create index ass_lot_ix on ass(lot)");
	$db->do("create index ass_block_ix on ass(block)");
}

1;
