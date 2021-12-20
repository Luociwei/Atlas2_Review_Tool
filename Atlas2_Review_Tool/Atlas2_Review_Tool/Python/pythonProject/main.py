# This is a sample Python script.
import json
import os
import time

from cw_package import cw_redis
from cw_package import cw_zmq
from cw_package import cw_common as common
from atlaslog_package import atlas_log

is_debug = 0
if is_debug:
    dict = {
        'name': 'AtlasLog',
        'event': 'GenerateClick',
        'params': ["/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504/unit-archive"]
    }
    test_str = json.dumps(dict)

else:
    redis_client = cw_redis.RedisClient()

zmqClient = cw_zmq.ZmqClient("tcp://127.0.0.1:3100")


def run():
    while True:
        time.sleep(0.1)
        try:
            print("wait for zmq client ...")
            if is_debug:
                zmq_recv_msg = test_str
            else:
                zmq_recv_msg = zmqClient.recv()

            print('zmq_recv_msg:{0}', zmq_recv_msg)
            redis_client.flushdb()

            msg_name = zmq_recv_msg['name']
            msg_event = zmq_recv_msg['event']
            msg_path_arr = zmq_recv_msg['params']

            if len(msg_path_arr):
                msg_path = msg_path_arr[0]
            else:
                redis_client.set_common_warning(["Error!!!", "Not found the file path,pls check."])
                continue

            zmq_send_msg = ''
            if msg_name == 'AtlasLog':
                if msg_event == 'GenerateClick':
                    print("generate_click msg_mode_path:", msg_path)

                    if len(msg_path) == 0 or not os.path.exists(msg_path):

                        redis_client.set_common_warning(["Error!!!", "Not found the file path,pls check."])
                        zmqClient.send('ssss')
                        continue
                    all_file_list = common.get_file_path_list(msg_path, True)
                    print('all_file_list count:', len(all_file_list))
                    records_path_list = common.filter_list(all_file_list, [r'system/records.csv'])
                    print('file_list count:', len(records_path_list))
                    if len(records_path_list) < 1:
                        redis_client.set_common_warning(["Error!!!", "Not found the records.csv file,pls check."])
                        continue
                    index = 0
                    item_dict_arr = []
                    print('len(records_path_list)', len(records_path_list))
                    for records_file_path in records_path_list:
                        item_mode = atlas_log.ItemMode()
                        item_mode.get_mode(records_file_path, msg_path)
                        item_mode.index = index
                        item_dict_arr.append(item_mode.get_dict())

                        index = index + 1

                        redis_client.set_common_loading([item_mode.sn, index*1.0/len(records_path_list)])
                        if index == len(records_path_list):
                            time.sleep(0.5)

                    # redis_client.set_common('finish', 1.0)
                    zmq_send_msg = item_dict_arr

                else:
                    pass

            elif msg_name == 'AtlasScript':
                pass
            else:
                pass

            zmqClient.send(zmq_send_msg)
            if is_debug:
                break

        except Exception as error:
            print('error:', error)
            continue


if __name__ == '__main__':

    run()
    # # zmq_client = ZmqClient("tcp://127.0.0.1:3200")
    # zmqClient.send('sss')
    # result1 = zmqClient.recv()
    #
    # zmqClient.send('sss')
    # result2 = zmqClient.recv()

    # print ('sss')