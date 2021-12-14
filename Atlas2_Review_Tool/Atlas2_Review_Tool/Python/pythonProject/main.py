# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import re
import time
import os

from cwpackage import cwredis
from cwpackage import cwzmq

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print("BASE_DIR:", BASE_DIR)
# sys.path.insert(0,BASE_DIR+'/site-packages/')


zmqClient = cwzmq.ZmqClient("tcp://127.0.0.1:3100")
redisClient = cwredis.RedisClient()


# def print_hi(name) :
#     # Use a breakpoint in the code line below to debug your script.
#     print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.
#


def run1():
    while True:
        try:
            print("wait for zmq client ...")
            zmq_msg = zmqClient.recv()

            if len(zmq_msg) > 0:

                ret = redisClient.redis[zmq_msg]
                table_data = redisClient.get_data_table(zmq_msg)
                if len(table_data) > 0:
                    print("---get data:", table_data[0])
                    zmqClient.send(table_data[0])
                else:
                    print("---get data error")
                    zmqClient.send("---get data error")

            else:
                time.sleep(0.05)

        except Exception as error:
            print('error:', error)


def run():
    while True:
        try:
            print("wait for zmq client ...")
            zmq_msg = zmqClient.recv()

            if len(zmq_msg) > 0:

                ret = redisClient.redis[zmq_msg]
                table_data = redisClient.get_data_table(zmq_msg)
                if len(table_data) > 0:
                    print("---get data:", table_data[0])
                    zmqClient.send(table_data[0])
                else:
                    print("---get data error")
                    zmqClient.send("---get data error")

            else:
                time.sleep(0.05)

        except Exception as error:
            print('error:', error)


if __name__ == '__main__':
    run()

    print('PyCharm')

