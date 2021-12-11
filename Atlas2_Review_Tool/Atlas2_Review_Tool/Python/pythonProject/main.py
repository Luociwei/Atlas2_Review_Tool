# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import re
import time
import os

from cwPackage import cwRedis
from cwPackage import cwZmqSocket

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print("BASE_DIR:", BASE_DIR)
# sys.path.insert(0,BASE_DIR+'/site-packages/')


zmqClient = cwZmqSocket.ZmqClient("tcp://127.0.0.1:3100")
redisClient = cwRedis.RedisClient()


# def print_hi(name) :
#     # Use a breakpoint in the code line below to debug your script.
#     print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.
#


def run():
    while True:
        try:
            print("wait for cpk client ...")
            zmq_recv = zmqClient.recv()

            if len(zmq_recv) > 0:

                ret = redisClient.redis[zmq_recv]
                print("message from cpk client:", ret)
                zmqClient.send(ret)

                print(redisClient.redis[zmq_recv])
                table_data = redisClient.get_data_table(zmq_recv)
                if len(table_data) > 0:
                    print("---get data:", table_data[0])
                else:
                    print("---get data error")

            else:
                time.sleep(0.05)

        except Exception as error:
            print('error:', error)


if __name__ == '__main__':
    run()

    print('PyCharm')

