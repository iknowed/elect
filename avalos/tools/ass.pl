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

$a->{AIASECD}->load();
print "AIASECD->loadd() " . `date`;
$a->index();
print "AIAOWNR->index() " . `date`;
$a->{AIAOWNR}->load();
print "AIAOWNR->load() " . `date`;
