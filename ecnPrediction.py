import numpy as np
from sklearn.svm import SVC
import matplotlib.pyplot as plt
import math
from mpl_toolkits.mplot3d import Axes3D
#'Server0_cnwd.txt'
def mean(values):
    sum = 0
    for i in values:
        sum += i
    return sum /len(values)
# data importing... 
data = []
for filename in ['/Users/tingtinglu/Desktop/Dumbbell/receive_NewRenoVSUDP_Half_S1.txt',
                 '/Users/tingtinglu/Desktop/Dumbbell/send_NewRenoVSUDP_Half_S1.txt', 
                 '/Users/tingtinglu/Desktop/Dumbbell/ecn_NewRenoVSUDP_Half_S1.txt',
                 '/Users/tingtinglu/Desktop/Dumbbell/rttRatio_NewRenoVSUDP_Half_S1.txt']:
    print "importing..."+filename
    data.append(np.genfromtxt(filename))
    print "importing done for "+filename

send = data[1]
send= np.around(send, decimals = 6)
send_diff = np.diff(data[1])
ack = data[0]
ack = np.around(ack, decimals = 6)
ack_diff = np.diff(data[0])
ecn = np.asarray(data[2])
rttRatio = data[3]
rttRatio = np.around(rttRatio, decimals = 6)
def ExpMovingAverage(values, window):
    weights = np.exp(np.linspace(-1., 0., window))
    weights /= weights.sum()

    # Here, we will just allow the default since it is an EMA
    a =  np.convolve(values, weights)[:len(values)]
    a[:window] = a[window]
    return a #again, as a numpy array.

print "computing EWMA..."
ack_ewma = ExpMovingAverage(ack_diff,10)
send_ewma = ExpMovingAverage(send_diff,10)

print "size of send, ack, ecn, ack_ewma and send_ewma"
print len(send)
print len(ack)
print len(ecn)
print len(ack_ewma)
print len(send_ewma)

print "construct train set..."
train = []

for i in range(1,len(ack)):
    train.append([send_ewma[i-1], ack_ewma[i-1], rttRatio[i]])

print "train set constructiong done!"

train = np.asarray(train)

y = []
for i in range(len(train)):
    y.append(ecn[i+1])

y = np.asarray(y)


count = 0
for i in y:
    if i == 1:
        count += 1
print "ECN count is:"
print count


np.savetxt('/Users/tingtinglu/Desktop/Dumbbell/train_NewRenoVSUDP_Half_S1.txt',train)
from sklearn import linear_model
from sklearn import cross_validation as cv
from sklearn.metrics import roc_curve, auc
import pylab as pl


print "train test set split..."

# X_train,X_test,y_train,y_test=cv.train_test_split(train,y,test_size=0.2, random_state=0)
X_train = train[:int(train.shape[0]*0.8),:]
X_test = train[int(train.shape[0]*0.8)+1:,:]
y_train = y[:int(train.shape[0]*0.8)]
y_test =  y[int(train.shape[0]*0.8)+1:]
print "spliting complete."



np.savetxt('/Users/tingtinglu/Desktop/Dumbbell/train_test_data/NewRenoVSUDP_Half_S1_X_train.txt',X_train)
np.savetxt('/Users/tingtinglu/Desktop/Dumbbell/train_test_data/NewRenoVSUDP_Half_S1_y_train.txt',y_train)
np.savetxt('/Users/tingtinglu/Desktop/Dumbbell/train_test_data/NewRenoVSUDP_Half_S1_X_test.txt',X_test)
np.savetxt('/Users/tingtinglu/Desktop/Dumbbell/train_test_data/NewRenoVSUDP_Half_S1_y_test.txt',y_test)


pos = np.where(y_train == 1)[0].tolist()
neg = np.where(y_train == 0)[0].tolist()
X_train11 = []
X_train12 = []
X_train13 = []
X_train21 = []
X_train22 = []
X_train23 = []
for item in X_train[pos]:
    X_train11.append(item[0])
    X_train12.append(item[1])
    X_train13.append(item[2])
for item in X_train[neg]:
    X_train21.append(item[0])
    X_train22.append(item[1])
    X_train23.append(item[2])
#for ii, jj in zip(X_train[pos], X_train[neg])
# plt.plot(X_train11, X_train12, 'r+', label = 'ecn=1')
# plt.plot(X_train21, X_train22, 'y*', label = 'ecn=0')
# plt.xlabel('send_ewma')
# plt.ylabel('ack_ewma')
# plt.legend(loc=1)
# plt.title('ECN distribuction with using NewReno')
# plt.show()
#fig = plt.figure(1)
#ax = fig.add_subplot(111,projection = '3d')
#ax.scatter(X_train11,X_train12,X_train13, c='r', marker = 'o', label = 'ecn = 1')
#ax.scatter(X_train21,X_train22,X_train23, c='y', marker = '+', label = 'ecn = 0')
#
#ax.set_xlabel('RTT Ratio')
#ax.set_ylabel('send_ewma')
#ax.set_zlabel('ack_ewma')
#plt.show()
#
#for c_val in [1]: #,2.5,5.0,10.0]:
c_val = 1
clf = linear_model.LogisticRegression(C=c_val,penalty='l1')
clf.fit(X_train,y_train)
probas_ = clf.predict_proba(X_test)
#predict_ = clf.predict(X_test)
#params_ = clf.get_params(deep = True)
fpr, tpr, thresholds = roc_curve(y_test, probas_[:,1])
print clf.score(X_test, y_test)
roc_auc = auc(fpr, tpr)
#auc_list.append(roc_auc)
print(clf.coef_)
print(clf.intercept_)
print("Area under the ROC curve : %f" % roc_auc)
plt.figure(2)
plt.plot(fpr, tpr, label='ROC (area = %0.2f) (c_value = %0.1f)' % (roc_auc,c_val))
plt.plot([0, 1], [0, 1], 'k--')
    
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.0])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ECN Prediction given ack_ewma, send_ewma')
plt.legend(loc="lower right")
plt.show()
