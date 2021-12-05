import time
from rpc_client import RPCClientWrapper
from rpc_server import RPCServerWrapper
from publisher import *
from tinyrpc.dispatch import public
from threading import Thread
import logging
RUNNING = 'running'
DONE = 'done'


class UART(object):
    def __init__(self):
        pass

    @public
    def open(self, *arg, **kwargs):
        return 'done'

    @public
    def close(self, *arg, **kwargs):
        return 'done'

    @public
    def config(self, *arg, **kwargs):
        return 'done'

    @public
    def read_hex(self, *arg, **kwargs):
        print 'reading hex'
        return [30, 31, 32, 33]

    @public
    def write_hex(self, *arg, **kwargs):
        return 'done'


# test driver class; only for demo & testing
class driver(object):
    def __init__(self):
        self.bus = bus()
        self.axi = axi()

    @public
    def echo(self, a):
        if len(a) > 128:
            msg = a[:125] + '...'
        else:
            msg = a
        print('Echoing {} back to client.'.format(msg))
        return a

    @public
    def float10(self, a):
        print('Checking if input is float 1.0', a)
        if a != 1.0:
            return 'input {} is not 1.0 as expected'.format(a)
        return a

    @public
    def float11(self, a):
        print('Checking if input is float 1.1', a)
        if a != 1.1:
            return 'input {} is not 1.1 as expected'.format(a)
        return a

    @public
    def int1(self, a):
        # print('Checking if input is int 1', a)
        # if a != 1:
        #     return 'input {} is not 1 as expected'.format(a)
        return a

    @public
    def strshark(self, a):
        print('Checking if input is string "shark"', a)
        if a != 'shark':
            return 'input {} is not "shark" as expected'.format(a)
        return a

    @public
    def list_0_1_a_float15_false(self, a):
        print('Checking if input is list [0, 1, "a", 1.5, False]')
        expected = [0, 1, 'a', 1.5, False]
        if a != expected:
            return 'input {} is not [0, 1, "a", 1.5, False] as expected'.format(a)
        return a

    @public
    def dict_a_0(self, a):
        print('Checking if input is dictionary {"a": 0}')
        expected = {"a": 0}
        if a != {"a": 0}:
            return 'input {} is not {"a": 0} as expected'.format(a)
        return a

    @public
    def fun(self, a=None, b=None):
        if not a and not b:
            ret = 'calling driver.fun()'
        elif a and b:
            ret = 'calling driver.fun({}, {})'.format(a, b)
        return ret

    @public
    def fun_kwargs(self, a, b):
        ret = 'calling driver.fun_kwargs(a={}, b={})'.format(a, b)
        return ret

    def driver_private_fun(self):
        ret = 'driver private fun'
        return ret


class bus(object):
    def __init__(self):
        self.axi = axi()

    @public
    def fun(self):
        ret = 'calling driver.bus.fun()'
        return ret

    def bus_private_fun(self):
        ret = 'bus private fun'
        return ret


class _UART(object):
    def __init__(self):
        self.axi = axi()

    @public
    def read_hex(self):
        ret = ['0'] * 1024
        return ret

    def write_hex(self, data):
        print data
        return 'done'


class axi(object):
    def __init__(self):
        pass

    @public
    def fun(self):
        ret = 'calling axi.fun()'
        return ret

    def axi_private_fun(self):
        ret = 'axi private fun'
        return ret


class utility(object):
    def __init__(self, name='utility'):
        self.name = name

    @public
    def measure(self, value):
        print 'measure: ', value
        return value

    @public
    def dummy(self, a=1, b=2):
        print 'dummy: {}, {} '.format(a, b)
        return '--PASS--'

    @public
    def dummy_fail(self, a=1, b=2):
        print 'dummy: {}, {} '.format(a, b)
        return '--FAIL--'

    @public
    def dummy_other(self, a=1, b=2):
        print 'dummy: {}, {} '.format(a, b)
        return 'Shark does not bite.'

    @public('sleep')
    def test_delay(self, second):
        now = time.time()
        logging.info('[{}] worker: start to sleep for {} second'.format(time.time(), second))
        time.sleep(second)
        logging.info('[{}] worker: end sleep for {} second'.format(time.time(), second))
        return 'server time cost for {} second sleep: {}'.format(second, time.time() - now)

    @public
    def sleep_timeout(self, second):
        '''
        sleep 1s more than given second to generate a server side timeout.
        '''
        now = time.time()
        logging.info('[{}] worker: start to sleep for {}+1 second'.format(time.time(), second))

        time.sleep(second + 1)
        logging.info('[{}] worker: end sleep for {}+1 second'.format(time.time(), second))
        return 'server time cost for {}+1 second sleep: {}'.format(second, time.time() - now)


if __name__ == '__main__':
    endpoints = []
    endpoint = {'receiver': 'tcp://127.0.0.1:5556', 'replier': '127.0.0.1:15556'}
    endpoints.append(endpoint)
    endpoint = {'receiver': 'tcp://*:5557', 'replier': 'tcp://127.0.0.1:15557'}
    endpoints.append(endpoint)

    ctx = zmq.Context()
    # publisher = ZmqPublisher(ctx, "tcp://127.0.0.1:6666", 'Publisher')
    publisher = NoOpPublisher()

    # 2 driver instances
    util = utility()
    driver = driver()
    uart = UART()

    servers = []
    for endpoint in endpoints:
        server = RPCServerWrapper(endpoint, NoOpPublisher())
        server.register_instance(util)
        server.register_instance({'driver': driver, 'util': util})
        server.register_instance({'uart': uart})
        servers.append(server)

    # initial work that will take 150ms; put it here to avoid adding 150ms to the 1st rpc call.
    from uuid import uuid1
    uuid1().hex

    # for socket connect
    time.sleep(0.5)

    # raw_input()
    while True:
        time.sleep(1)


