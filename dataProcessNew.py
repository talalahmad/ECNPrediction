tracefile = "/Users/tingtinglu/Desktop/Dumbbell/outNewRenoVSUDP.tr"
ID = "/Users/tingtinglu/Desktop/Dumbbell/ID_NewRenoVSUDPPareto.txt"

try:
  f = open(tracefile)
except:
  print "Trace File not existed"
try:
  f = open(ID)
except:
  print "ID File not existed"
  
send = []
ecn = []
receive = []
rtt = []
rttRatio = []
ecnID = []
    ###Read tracefiles and ecn packet nuique IDs
ecn_ids = open(ID).readlines()
for ecn_id in ecn_ids:
    temp = ecn_id.split(' ')
    ecnID.append(temp[0]+ '\n')
    

trace_items = open(tracefile).readlines()
####setup files to store sending time, receiving time, rtt, rtt_ratio
    ####and ecn
sendf = open('/Users/tingtinglu/Desktop/Dumbbell/send_NewRenoVSUDP_Half_S1.txt', 'w')
ecnf = open('/Users/tingtinglu/Desktop/Dumbbell/ecn_NewRenoVSUDP_Half_S1.txt', 'w')
receivef = open('/Users/tingtinglu/Desktop/Dumbbell/receive_NewRenoVSUDP_Half_S1.txt','w')
rttf = open('/Users/tingtinglu/Desktop/Dumbbell/rtt_NewRenoVSUDP_Half_S1.txt','w')
rttRatiof = open('/Users/tingtinglu/Desktop/Dumbbell/rttRatio_NewRenoVSUDP_Half_S1.txt', 'w')
    ##sequenceID to hold the sequence ID of the packet sending from
    ##particular source to particular destination
sequenceID = []
    ##uniqueID to hold the packet unique ID which is used to match with ecn_id
uniqueID = []
    ##setup initial value for rtt, which is a very big value
rtt_minimum = 100
    ####record the sequence that is already acked
ackedSequenceID = []

    ##record sending time data
for trace_item in trace_items:
    data = trace_item.split(' ')
        ####extracting data sending from node 0 to node 1 through gateway node
        ###20 and 21
    if (data[0] == '+') and (data[2] == '0') and (data[3] == '20') and (data[8] == '0.0') and (data[9] == '1.0'):
        if (data[10] in sequenceID):
            pass
        else:
            sequenceID.append(data[10])
            uniqueID.append(data[11])
            send.append(data[1] + '\n')
            if (data[11] in ecnID):
                ecn.append('1' + '\n')
            else:
                ecn.append('0' + '\n')
    if (data[0] == 'r') and (data[3] == '0') and (data[4] == 'ack') and (data[10] in sequenceID) and (data[10] not in ackedSequenceID):
        #receive.append(data[1] + '\n')
        ackLen = len(ackedSequenceID)
        if (int(data[10]) - ackLen > 0): 
            for noack in range(1, int(data[10]) - ackLen):
                ackedSequenceID.append(ackLen+noack-1)
                receivePadding = data[1]
                receive.append(receivePadding + '\n')
                rtt.append(str(float(receive[int(ackLen+noack-1)]) - float(send[int(ackLen+noack-1)])) + '\n')
                if (float(rtt[int(ackLen+noack-1)]) < rtt_minimum):
                    rtt_minimum = float(rtt[int(ackLen+noack-1)])
                rttRatio.append(str(float(rtt[int(ackLen+noack-1)])/rtt_minimum) + '\n')
        else:
            ackedSequenceID.append(data[10])
            receive.append(data[1] + '\n')
            rtt.append(str(float(receive[int(data[10])]) - float(send[int(data[10])])) + '\n')
            if (float(rtt[int(data[10])]) < rtt_minimum):
                rtt_minimum = float(rtt[int(data[10])])
            rttRatio.append(str(float(rtt[int(data[10])])/rtt_minimum) + '\n')

sendf.writelines(send)
receivef.writelines(receive)
ecnf.writelines(ecn)
rttf.writelines(rtt)
rttRatiof.writelines(rttRatio)
sendf.close()
receivef.close()
ecnf.close()
rttf.close()
rttRatiof.close()