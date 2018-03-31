#!/usr/local/bin/perl

$type = "FOO";

$e = "\$SUP_".$type."_SELECTED = 'SELECTED'";
eval  $e;

print $SUP_FOO_SELECTED;
