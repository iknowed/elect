#!/usr/bin/perl

if(($ENV{REQUEST_METHOD} =~ /get/i) || ($ENV{QUERY_STRING})) {
	my $qy = $ENV{QUERY_STRING};
} 
if($ENV{REQUEST_METHOD} =~ /post/i) {
	my $qy = <>;
} 
