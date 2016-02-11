#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows
$ns color 1 Blue
$ns color 2 Red

#Create four nodes
set n0 [$ns node]
# set n1 [$ns node]
# set n2 [$ns node]
set n3 [$ns node]

#Create links between the nodes
$ns duplex-link $n0 $n3 10Mb 20ms DropTail
# $ns duplex-link $n1 $n2 1Mb 10ms DropTail
# $ns duplex-link $n3 $n2 1Mb 10ms DropTail

#Create a TCP agent and attach it to node n0
set tcp0 [new Agent/TCP/Linux]
$ns at 0 "$tcp0 select_ca cubic"
$tcp0 set class_ 1
$ns attach-agent $n0 $tcp0

# Create a CBR traffic source and attach it to udp0
set cbr0 [new Application/Traffic/CBR]
#$cbr0 set packetSize_ 500
#$cbr0 set interval_ 0.005
$cbr0 attach-agent $tcp0


# #Open the nam trace file
# set nf [open out.nam w]
# $ns namtrace-all $nf

####Create Error Model
set off [new ErrorModel/Uniform 0 pkt]
set on [new ErrorModel/Uniform 1 pkt] 

set m_states [list $off $on]
# Durations for each of the states, tmp, tmp1 and tmp2, respectively 
#set m_periods [list 0.2 0.1 0.05]
set m_periods [list 2 2 4 2 10]
# Transition state model matrix
#set m_transmx { {0 1 0}
#{0 0 1}
#{1 0 0}}
set m_transmx { 
	{0 1}
    {1 0}
}
set m_trunit pkt
# Use time-based transition
set m_sttype time
set m_nstates 2
set m_nstart [lindex $m_states 0]
set em [new ErrorModel/MultiState $m_states $m_periods $m_transmx $m_trunit $m_sttype $m_nstates $m_nstart]

$ns link-lossmodel $em $n0 $n3
#Define a ‘finish’ procedure

proc finish {} {
	global ns nf
	$ns flush-trace
	#Close the trace file
	#close $nf
	#Execute nam on the trace file
	#exec nam out.nam &
	#exit 0
	#exec xgraph congestion.xg -geometry 300x300 &1amp;
   	exit 0
}


# Create a UDP agent and attach it to node n1
# set tcp1 [new Agent/TCP]
# $tcp1 set class_ 2
# $ns attach-agent $n1 $tcp1

# Create a CBR traffic source and attach it to udp1
# set cbr1 [new Application/Traffic/CBR]
# $cbr1 set packetSize_ 500
# $cbr1 set interval_ 0.005
# $cbr1 attach-agent $tcp1

# Create a Null agent (a traffic sink) and attach it to node n3
set null0 [new Agent/TCPSink/Sack1] 
$null0 set ts_echo_rfc1323_ true
$ns attach-agent $n3 $null0
#set null0 [new Agent/TCPSink]
#$ns attach-agent $n3 $null0
# set null1 [new Agent/TCPSink]
# $ns attach-agent $n3 $null1
# Connect the traffic sources with the traffic sink
$ns connect $tcp0 $null0
# $ns connect $tcp1 $null1

#Schedule events for the CBR agents
$ns at 0.0 "$cbr0 start"
#$ns at 1.0 "$cbr1 start"
#$ns at 4.0 "$cbr1 stop"
$ns at 20.0 "$cbr0 stop"
#Call the finish procedure after 5 seconds of simulation time
$ns at 20.0 "finish"

#Run the simulation


proc plotWindow {tcpSource outfile} {
   global ns
   set now [$ns now]
   set cwnd [$tcpSource set cwnd_]

# the data is recorded in a file called congestion.xg (this can be plotted # using xgraph or gnuplot. this example uses xgraph to plot the cwnd_
   puts  $outfile  "$now $cwnd"
   $ns at [expr $now+0.01] "plotWindow $tcpSource  $outfile"
}

set outfile [open  "congestion.tr"  w]
$ns  at  0.0  "plotWindow $tcp0  $outfile"


$ns run