
use Data::Dump qw(dump);
use Device::Gsm;
use utf8;

$port=$ARGV[0]; 
#"/dev/ttyACM1";

my $gsm = new Device::Gsm( port => $port  );

if( $gsm->connect() ) {
#print "connected!\n";
} else {
print "sorry, no connection with gsm phone on serial port!\n";
}

my $i=0;

foreach $storage  (( "SM", "ME" ))

{
@sms = $gsm->messages($storage);

#dump(@sms);

if( @sms ) {
    foreach $msg ( @sms ) {
                    print "-\n";
                   #print $msg->recipient() , "\n";
                    $from=$msg->sender();
                    $from=~s/[^\d\w-\.\+]//g;
                   print " Phone: ", $from ,  "\n";
                    $content=$msg->content();
                    $content=~s/\n//g;
                    $content=~s/'/`/g;
                    ## dumb way:
                    #$content=~s/[^[:ascii:]]+//g;
                    ## end
                    ## smart way:
                    $content2=$content; utf8::decode($content2);
                    #$content2=~s/://g;
                    $content=$content2; utf8::encode($content);
                    ## end
                   print " Content: '", $content  , "'\n";
                   print " Date: \"", $msg->time()      , "\"\n";
                   #print $msg->type()      , "\n";
                    print " Index: ", $msg->index(),  "\n";
                    #print " Storage: $storage\n";
                    print "\n";
                    $i++;
               }
}


}

if ($i==0) { print "[]\n"}

