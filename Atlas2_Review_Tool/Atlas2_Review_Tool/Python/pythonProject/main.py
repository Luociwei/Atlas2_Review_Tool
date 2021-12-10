# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import sys
import os,time,re,math

try:
    import redis
except Exception as e:
    print('import redis error:', e)


import threading

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print("BASE_DIR:", BASE_DIR)
# sys.path.insert(0,BASE_DIR+'/site-packages/')


try:
    import time
except Exception as e:
    print('import time error:', e)

try:
    import zmq
except Exception as e:
    print('import zmq error:', e)

# redisClient = redis.Redis(host='localhost', port=6379, db=0)
redisClient = redis.Redis(host='localhost', port=6379, decode_responses=True)
redisClient.set('name', 'runoob')  # 设置 name 对应的值
print(redisClient['name'])
print(redisClient.get('name'))  # 取出键 name 对应的值
print(type(redisClient.get('name')))  # 查看类型
# def zmq_connect():
context = zmq.Context()
socket = context.socket(zmq.REP)
socket.setsockopt(zmq.LINGER, 0)
socket.bind("tcp://127.0.0.1:3100")

# def print_hi(name) :
#     # Use a breakpoint in the code line below to debug your script.
#     print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.
#

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        pass
    try:
        import unicodedata
        unicodedata.numeric(s)
        return True
    except (TypeError, ValueError):
        pass
 
    return False

def get_redis_data(zmqMsg):
    tb = redisClient.get(zmqMsg)
    tb_data=[]
    if tb:
        tb=tb.decode('utf-8')
        tb=tb.split("\n")
        tb=(tb[1:-1])   #去掉数据库首尾元素
        for i in tb:
            k=re.sub('\"','',i)  #去掉数据库引号
            h=re.sub(',','',k)   #去掉数据库逗号
            m=h.strip()          #去掉数据库首尾空白
            if is_number(m):
                tb_data.append(eval(m))   #去掉数字的引号
            else:
                tb_data.append(m)
    else:
        tb_data.append('')
    return tb_data


def run():
    while True:
        try:
            print("wait for cpk client ...")
            zmqMsg = socket.recv()

            if len(zmqMsg) > 0:
                key = zmqMsg.decode('utf-8')
                ret = redisClient[key]
                print("message from cpk client:", ret)
                socket.send(ret.encode('ascii'))
                
                print(redisClient[key])
                # table_data = get_redis_data(key)
                # if len(table_data) > 0:
                #     print("---get data:", table_data[0])
                # else:
                #     print("---get data error")
                # socket.send(table_data[0].decode('utf-8').encode('ascii'))

            else:
                time.sleep(0.05)

        except Exception as error:
            print('error:', error)


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    # print(time.time())
    run()

    print('PyCharm')

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
