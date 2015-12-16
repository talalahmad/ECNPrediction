## Simple example demonstrating use of the RandomVariable class from tcl
# set count 10
# set rng1 [new RNG]
# set rng2 [new RNG]
# for {set i 0} {$i < 1} {incr i} {
# 	puts "===== i = $i "
# 	$rng1 next-substream;
# 	$rng2 next-substream;
# 	set r1 [new RandomVariable/Exponential]
# 	$r1 use-rng $rng1
# 	$r1 set avg_ 10.0
# 	$r1 set shape_ 1.2
# 	puts stdout "(rng1) Testing Pareto Distribution , avg = [$r1 set avg_]
# 	shape = [$r1 set shape_ ]"
# 	$r1 test $count
# 	set r2 [new RandomVariable/Exponential]
# 	$r2 use-rng $rng2
# 	$r2 set avg_ 10.0
# 	$r2 set shape_ 1.2
# 	puts stdout "(rng2) Testing Pareto Distribution , avg = [$r2 set avg_]
# 	shape = [$r2 set shape_]"
# 	$r2 test $count
# }

#######Study of cwnd change and throughput when the channel is periodically up and down

set N 1
set bottleNeckLinkDataRate 1024Mb
set lineRate 1024Mb
set RTT1 0.02
set RTT2 0.04
set RTT3 0.02
set packetSize 1460

##### set buffer size to delay-bandwidth product
set routerBufferSize 3600


set simulationTime 50.0
set startMeasurementTime 0.0
set stopMeasurementTime 50.0
set flowClassifyTime 0.04

#########set TCP CC protocol
# set congestionControlAlg NewReno
set congestionControlAlg Cubic

#set switchQueueAlg RED

set traceSamplingInterval 0.01
set throughputSamplingInterval 0.01
set enableNam 0
set ns [new Simulator]

Agent/TCP set packetSize_ $packetSize
Agent/TCP set window_ 8000


Queue set limit_ 8000



DelayLink set avoidReordering_ true

if {$enableNam != 0} {

	set namfile [open outS4.nam w]
	$ns namtrace-all $namfile
}

set tf [open outS4.tr w]
$ns trace-all $tf

set mytracefile [open mytracefileS4.tr w]
set throughputfile [open thrfileS4.tr w]
proc finish {} {
	global ns enableNam namfile tf mytracefile throughputfile
	$ns flush-trace
	close $tf
	close $mytracefile
	close $throughputfile
	if {$enableNam != 0} {
		close $namfile
		exec nam outS4.nam &
	}
	exit 0
}

proc myTrace {file} {
	global ns N traceSamplingInterval tcp qfile MainLink nbow nclient packetSize enable BumponWire

	set now [$ns now]

	for {set i 0} {$i < $N} {incr i} {
		set cwnd($i) [$tcp($i) set cwnd_]
	}

	$qfile instvar parrivals_ pdepartures_ pdrops_ bdepartures_

	puts -nonewline $file "$now $cwnd(0)"
	for {set i 1} {$i < $N} {incr i} {
    puts -nonewline $file " $cwnd($i)"
    }

    puts -nonewline $file " [expr $parrivals_-$pdepartures_-$pdrops_]"    
    puts $file " $pdrops_"
     
    $ns at [expr $now+$traceSamplingInterval] "myTrace $file"
}


proc throughputTrace {file} {
    global ns throughputSamplingInterval qfile flowstats N flowClassifyTime
    
    set now [$ns now]
    
    $qfile instvar bdepartures_
    
    puts -nonewline $file "$now [expr $bdepartures_*8/$throughputSamplingInterval/1000000]"
    set bdepartures_ 0
    if {$now <= $flowClassifyTime} {
    for {set i 0} {$i < [expr $N-1]} {incr i} {
        puts -nonewline $file " 0"
    }
    puts $file " 0"
    }

    if {$now > $flowClassifyTime} { 
    for {set i 0} {$i < [expr $N-1]} {incr i} {
        $flowstats($i) instvar barrivals_
        puts -nonewline $file " [expr $barrivals_*8/$throughputSamplingInterval/1000000]"
        set barrivals_ 0
    }
    $flowstats([expr $N-1]) instvar barrivals_
    puts $file " [expr $barrivals_*8/$throughputSamplingInterval/1000000]"
    set barrivals_ 0
    }
    $ns at [expr $now+$throughputSamplingInterval] "throughputTrace $file"
}
$ns color 0 Red
$ns color 1 Orange
$ns color 2 Yellow
$ns color 3 Green
$ns color 4 Blue
$ns color 5 Violet
$ns color 6 Brown
$ns color 7 Black
$ns color 8 Purple
$ns color 9 SeaGreen



for {set i 0} {$i < $N} {incr i} {
	set s($i) [$ns node]
    set r($i) [$ns node]
}

set nqueue1 [$ns node]
set nqueue2 [$ns node]

for {set i 0} {$i < $N} {incr i} {
	$ns duplex-link $s($i) $nqueue1 $lineRate [expr $RTT1] DropTail
	$ns duplex-link $r($i) $nqueue2 $lineRate [expr $RTT3] DropTail
}

$ns simplex-link $nqueue1 $nqueue2 $bottleNeckLinkDataRate [expr $RTT2] DropTail
$ns simplex-link $nqueue2 $nqueue1 $bottleNeckLinkDataRate [expr $RTT2] DropTail
$ns queue-limit $nqueue1 $nqueue2 $routerBufferSize
$ns rtmodel-at 10.0 down $nqueue1 $nqueue2
$ns rtmodel-at 10.1 up $nqueue1 $nqueue2
$ns rtmodel-at 20.0 down $nqueue1 $nqueue2
$ns rtmodel-at 20.1 up $nqueue1 $nqueue2
$ns rtmodel-at 30.0 down $nqueue1 $nqueue2
$ns rtmodel-at 30.1 up $nqueue1 $nqueue2
$ns rtmodel-at 40.0 down $nqueue1 $nqueue2
$ns rtmodel-at 40.1 up $nqueue1 $nqueue2


set file1 [open queue100M.tr w]
set qfile [$ns monitor-queue $nqueue1 $nqueue2 $file1 $traceSamplingInterval]


$ns duplex-link-op $nqueue1 $nqueue2 color "green"
$ns duplex-link-op $nqueue1 $nqueue2 queuePos 0.25



####Create Error Model
set off [new ErrorModel/Uniform 0 pkt]
set on [new ErrorModel/Uniform 1 pkt] 

set m_states [list $off $on]
# Durations for each of the states, tmp, tmp1 and tmp2, respectively 
#set m_periods [list 0.2 0.1 0.05]
set m_periods [list 4 0.01]
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


#$ns link-lossmodel $em $nqueue1 $nqueue2

for {set i 0} {$i < $N} {incr i} {
	if {[string compare $congestionControlAlg "NewReno"] == 0} {
		set tcp($i) [new Agent/TCP/Newreno]
		set sink($i) [new Agent/TCPSink/Sack1]
	}
	if {[string compare $congestionControlAlg "Cubic"] == 0} {
		set tcp($i) [new Agent/TCP/Linux]
		$tcp($i) set timestamps_ true
		$ns at 0 "$tcp($i) select_ca cubic"
		set sink($i) [new Agent/TCPSink/Sack1]
	}
	$ns attach-agent $s($i) $tcp($i)
	$ns attach-agent $r($i) $sink($i)

	$tcp($i) set fid_ [expr $i]
	$sink($i) set fid_ [expr $i]

	$ns connect $tcp($i) $sink($i)
}


for {set i 0} {$i < $N} {incr i} {
	set ftp($i) [new Application/FTP]
	$ftp($i) attach-agent $tcp($i)
	$ns at 0.0 "$ftp($i) start"
	$ns at [expr $simulationTime] "$ftp($i) stop"
}

$ns at $traceSamplingInterval "myTrace $mytracefile"
$ns at $throughputSamplingInterval "throughputTrace $throughputfile"

set flowmon [$ns makeflowmon Fid]
set MainLink [$ns link $nqueue1 $nqueue2]

$ns attach-fmon $MainLink $flowmon

set fcl [$flowmon classifier]

$ns at $flowClassifyTime "classifyFlows"

proc classifyFlows {} {
    global N fcl flowstats
    puts "NOW CLASSIFYING FLOWS"
    for {set i 0} {$i < $N} {incr i} {
    set flowstats($i) [$fcl lookup autp 0 0 $i]
    }
} 


set startPacketCount 0
set stopPacketCount 0

proc startMeasurement {} {
global qfile startPacketCount
$qfile instvar pdepartures_   
set startPacketCount $pdepartures_
}

proc stopMeasurement {} {
global qfile startPacketCount stopPacketCount packetSize startMeasurementTime stopMeasurementTime simulationTime
$qfile instvar pdepartures_   
set stopPacketCount $pdepartures_
puts "Throughput = [expr ($stopPacketCount-$startPacketCount)/(1000000*($stopMeasurementTime-$startMeasurementTime))*$packetSize*8] Mbps"
}




$ns at $startMeasurementTime "startMeasurement"
$ns at $stopMeasurementTime "stopMeasurement"
                      
$ns at $simulationTime "finish"
global defaultRNG
$defaultRNG seed 100
$ns run





