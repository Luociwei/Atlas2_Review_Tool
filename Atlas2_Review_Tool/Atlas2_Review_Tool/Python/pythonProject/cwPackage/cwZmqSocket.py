#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/11 1:44 PM
# @Author: Ci-wei
# @File  : zmq_socket.py
try:
    import zmq
except Exception as e:
    print('import zmq error:', e)


class ZmqClient(object):
    def __init__(self, url):
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.setsockopt(zmq.LINGER, 0)
        # "tcp://127.0.0.1:3100"
        self.url = url
        socket.bind(url)
        self.socket = socket

    def send(self, cmd_str):
        self.socket.send(cmd_str.encode('ascii'))

    def recv(self):
        r = self.socket.recv()
        return r.decode('utf-8')


if __name__ == '__main__':
    print('ss')