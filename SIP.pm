package SIP;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(SIPLogin SIPLogoff SIPSendReceive);

#####################################################
#  Based on code by Mark Ellis @Richmond Public Library
#  http://www.rice.edu/perl4lib/archives/2003-05/msg00032.html
#
#  trick for making work in Voyager is to change line terminator
#  from \n to \r
#####################################################

use IO::Socket::INET;
use IO::Select;

my $remote_host = 'yourip';
my $remote_port = 'your-port';

my $username = 'your-username';
my $password = 'your-password';
my $location = 'your-location';

my $timeout = 30;
my $response;

my $socket = IO::Socket::INET->new(
                                PeerAddr => $remote_host,
                                PeerPort => $remote_port,
                                Proto    => "tcp")
    or die "Couldn't connect to $remote_host:$remote_port : $!\n";

my $sel = new IO::Select( $socket );
$socket->autoflush(1);
my $date_time = SIPDateTime();

my $sequence_number = 1;

sub SIPLogin {
    my $login = "9300CN$username|CO$password|CP$location"; #|AY' . $sequence_number . 'AZ';
    $response = SIPSendReceive($login);
    if ($response != '941') {
	print "Cannot log in to Voyager SIP server.";
	exit;
    }
}

sub SIPLogoff {
    my $shutdown = '9920002.00AY' . ++$sequence_number . 'AZ';
    $response = SIPSendReceive($shutdown);
	if (substr($response, 0, 2) ne '98') {
	print "Bad response for logoff request.";
	exit;
    }
    close($socket);
}

#####################################################
sub SIPSendReceive {

	my $message = shift;
	my $line;
	my $message_checksum = Checksum($message);

	# removed checksum.  Unecessary with Voyager.
	## print "Sent: $message\n"; #$message_checksum\n"; # DEBUG

	# removed checksum.  Unecessary with Voyager.
	print $socket "$message\r"; #$message_checksum\n";
	if ($sel->can_read($timeout) )  {
		my $response = sysread($socket, $line, 256);
	} else { undef $line; }
	return $line;
}
#####################################################
# Unecessary for Voyager, but used with other ILSes, so we'll hang on to it.
sub Checksum  {
	my $message = shift;
	$message = $message . "\0";
	my $sum = 0;
	my $i;
	for($i = 0; $i < length($message); $i++)  {
		$sum += ord(substr($message, $i, 1));
	}
	my $checksum = ($sum ^ 0xFFFF) + 1;
	return sprintf("%4.4X", $checksum);
}
#####################################################

#####################################################
sub SIPDateTime  {
	# Convert date/time returned by localtime to SIP date/time string (YYYYMMDDZZZZHHMMSS)
	my($sec, $min, $hour, $mday, $mon, $year) = localtime( time );
	$year += 1900;
	my $four_spaces = '    ';
	$mon++; # Month returned as 0 - 11, so increment to get the correct number.
	return sprintf("$year%02d%02d%02d$four_spaces%02d%02d", $mon, $mday, $hour, $min, $sec);
}
#####################################################

1;
