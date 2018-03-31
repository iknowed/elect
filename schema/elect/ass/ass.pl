#!/usr/local/bin/perl

use Elect;
use Elect::Ass;
use Elect::Ass::AIASECD;
use Elect::Ass::AIAOWNR;
$e = Elect->new();
$db = $e->{db};
$db->connect();

$a = Elect::Ass->new();

$a->init();

#print "AIAOWNR->load() " . `date`;
#$a->{AIAOWNR}->load();
print "AIASECD->loadd() " . `date`;
$a->{AIASECD}->load();
print "AIAOWNR->index() " . `date`;
$a->index();
