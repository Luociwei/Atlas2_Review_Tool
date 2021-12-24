
import sys,os,time,math,re

import threading

BASE_DIR=os.path.dirname(os.path.abspath(__file__))
print("BASE_DIR:", BASE_DIR)
sys.path.insert(0,BASE_DIR+'/site-packages/')

try:
    import zmq
except Exception as e:
    print('import zmq error:',e)
print('python import ----> zmg')

import zmq


context = zmq.Context()
socket = context.socket(zmq.REP)
socket.setsockopt(zmq.LINGER,0)
socket.bind("tcp://127.0.0.1:3100")

#line = "Cats are smarter than dogs";
# 
#searchObj = re.search( r'(.*) are (.*?) .*', line, re.M|re.I)
# 
#if searchObj:
#   print "searchObj.group() : ", searchObj.group()
#   print "searchObj.group(1) : ", searchObj.group(1)
#   print "searchObj.group(2) : ", searchObj.group(2)
#else:
#   print "Nothing found!!"
#
#
def regexTest(content,pattern):

	# regex=re.compile(pattern)
	# print(regex.findall(content))

	print(re.findall(pattern,content))




def run():
    while True:
        try:
            print("wait for cpk client ...")
            zmqMsg = socket.recv()
            
            if len(zmqMsg)>0:
                key = zmqMsg.decode('utf-8')
                socket.send(b'cpk.png')
                print("message from cpk client:", key)

            else:
                time.sleep(0.05)

            # socket.send(b'cpk.png')       
        except Exception as e:
            print('error:',e)


if __name__ == '__main__':
    run()

    # regexTest(content,pattern)


