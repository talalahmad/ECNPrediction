#####Build a dumbbell model with N senders and N receivers communicating
#####through two connected routers

####### s0                                                  r1
#######   \                                                 /
####### s1\\ lineRate RTT1                    lineRate RTT3//r2
####### .  \\        bottleNeckLinkDataRate  RTT2         //  .
####### . -/ nqueue1-------------------------------nqueue2 ---.
####### . /   (RED)                             (DropTail) \
####### sN                                                 rN



set N 1
set bottleNeckLinkDataRate 1024Mb
set lineRate 1024Mb
set RTT1 0.01
set RTT2 0.02
set RTT3 0.01
set packetSize 1460

##### set buffer size to delay-bandwidth product
set routerBufferSize 1800


set simulationTime 200.0
set startMeasurementTime 0.0
set stopMeasurementTime 200.0
set flowClassifyTime 0.04

#########set TCP CC protocol
set congestionControlAlg NewReno
#set congestionControlAlg Cubic

#set switchQueueAlg RED

set traceSamplingInterval 0.01
set throughputSamplingInterval 0.01
set enableNam 0
set ns [new Simulator]


Agent/TCP set packetSize_ $packetSize
Agent/TCP set window_ 4000


Queue set limit_ 2000



DelayLink set avoidReordering_ true

if {$enableNam != 0} {

	set namfile [open outS1.nam w]
	$ns namtrace-all $namfile
}

set tf [open outS1.tr w]
$ns trace-all $tf

set mytracefile [open mytracefileS1.tr w]
set throughputfile [open thrfileS1.tr w]
proc finish {} {
	global ns enableNam namfile tf mytracefile throughputfile
	$ns flush-trace
	close $tf
	close $mytracefile
	close $throughputfile
	if {$enableNam != 0} {
		close $namfile
		exec nam outS1.nam &
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

######Comment the following line if do not want to use Error Model####
#$ns link-lossmodel $em $nqueue1 $nqueue2

for {set i 0} {$i < $N} {incr i} {
	if {[string compare $congestionControlAlg "NewReno"] == 0} {
		set tcp($i) [new Agent/TCP/Newreno]
		set sink($i) [new Agent/TCPSink]
	}
	if {[string compare $congestionControlAlg "Cubic"] == 0} {
		set tcp($i) [new Agent/TCP/Linux]
		$tcp($i) set timestamps_ true
		$ns at 0 "$tcp($i) select_ca cubic"
		set sink($i) [new Agent/TCPSink]
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





