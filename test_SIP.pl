#!/usr/bin/perl -w

use strict;
use SIP; # qw(:Both);
my $response; 
my $patron_identifier = $ARGV[0];

if (!$patron_identifier) {
  print "Patron identifier not set.\n";
  exit();
}

SIPLogin();
$response = SIPSendReceive("2300120120105    154011AO|AA$patron_identifier");
if (substr($response, 0, 2) != '24') {
	print "Bad response for Patron Status request.";
	exit;
}
my $fine =  substr($response, index($response, 'BV')+2, index($response, '|AF')-index($response, 'BV')-2);
print "FINE: $fine\n";
 
SIPLogoff();
