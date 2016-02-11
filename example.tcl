set ns [new Simulator]
set nf [open out.nam w]
$ns namtrace-all $nf
proc finish {} {
        global ns nf
        $ns flush-trace
        close $nf
        exec nam out.nam &
        exit 0
}
set node_(0) [$ns node]
set node_(1) [$ns node]

set tcp(0) [new Agent/TCP/Newreno]
set sink(0) [new Agent/TCPSink]
set ftp(0) [new Application/FTP]

$sink(0) listen
$ns duplex-link $node_(0) $node_(1) 10Mb 20ms DropTail

$ns attach-agent $node_(0) $tcp(0)
$ns attach-agent $node_(1) $sink(0)
$ns connect $tcp(0) $sink(0)
$ftp(0) set packetSize_ 1024
#$ftp(0) set random_ 1

$ns at 0.5 "$ftp(0) start"
$ns at 4.5 "$ftp(0) stop"

$ns at 5.0 "finish"
$ns run
