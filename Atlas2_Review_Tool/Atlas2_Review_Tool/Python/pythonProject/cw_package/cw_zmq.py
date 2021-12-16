#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/11 1:44 PM
# @Author: Ci-wei
# @File  : zmq_socket.py

import json
import cw_common as common

try:
    import zmq
except Exception as e:
    print('import zmq error:', e)


# import
class ZmqMsg:
    def __init__(self, msg):
        self.name = ''
        self.event = ''
        self.params = []
        if len(msg):
            msg_dict = json.loads(msg)
            if msg_dict:
                self.name = msg_dict['name']
                self.event = msg_dict['event']
                self.params = msg_dict['params']


class ZmqClient(object):
    def __init__(self, url):
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.setsockopt(zmq.LINGER, 0)
        # "tcp://127.0.0.1:3100"
        self.url = url
        socket.bind(url)
        self.socket = socket

    def send(self, cmd):
        send_cmd = ''
        if type(cmd) == type([]) or type(cmd) == type({}):
            send_cmd = json.dumps(cmd)

        elif type(cmd) == type(''):
            send_cmd = cmd

        else:
            pass

        if common.get_version() < 3:
            self.socket.send(send_cmd)
        else:
            self.socket.send(send_cmd.encode('ascii'))

    def recv(self):
        r = self.socket.recv()
        if common.get_version() < 3:
            return r
        else:
            return r.decode('utf-8')


if __name__ == '__main__':
    b = common.get_version() < 3
    print (b)
