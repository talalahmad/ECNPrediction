# ECNPrediction
Predict ECN bit using end user data. 

Dumbbell_Scenario1.tcl is an ns-2 simulation that simulated a dumbbell topology with 10 TCP senders and 10 receivers, each running the same TCP congestion control protocal (NewReno, Cubic, etc.). End-user data like packet sending time, ack receiving time, RTT and so on are collected to do the prediction of congestion in intermediate network (ECN bit).

Congestion is believed happened when the queue length is greater than a threshold. The drop-tail.cc in ns-2 is modified from line 93 to 106 to record the packet unique id when the queue length is greater than some threshold (for example, queuelimit/2). End-user data and the recorded congested packet forms the training data to predict the congestion.

