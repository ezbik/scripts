#!/usr/bin/perl

$| = 1;

STDOUT->autoflush(1);

use IO::Handle;
STDOUT->flush();

use Device::Modem;
$TTY=$ARGV[0];
my $modem = Device::Modem->new( port => $TTY  );
if( $modem->connect( baudrate => 9600 ) ) {
             print "=> serial port $TTY connected!\n";
         } else {
             die "sorry, no connection with serial port ,,$TTY'' !\n";
         }

#foreach $i (
#    (
#    "AT",
#    "ATE0",
#    "AT+CGMR",
#    "AT+CGSN",
#    "AT+COPS?",
#    "AT+CSQ",
#
#    )
#    )
#{
#    print "=> $i\n";
#    $modem->atsend( "$i\r\n" );
#    print $modem->answer(), "\n";
#}

use Time::HiRes qw(usleep nanosleep sleep); 

while ($i=<STDIN>)
{
    chomp($i);
    print "=> $i\n";
    $modem->atsend( "$i\r\n" );
    print $modem->answer(), "\n";
    #sleep(0.4);
}
