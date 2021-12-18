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
    redisClient = cw_redis.RedisClient()

zmqClient = cw_zmq.ZmqClient("tcp://127.0.0.1:3100")


def run():
    while True:
        try:
            print("wait for zmq client ...")
            if is_debug:
                zmq_recv_msg = test_str
            else:
                zmq_recv_msg = zmqClient.recv()

            print('zmq_recv_msg:', zmq_recv_msg)
            msg_mode = cw_zmq.ZmqMsg(zmq_recv_msg)
            msg_mode_name = msg_mode.name
            msg_mode_event = msg_mode.event
            msg_mode_path = msg_mode.params[0]
            zmq_send_msg = ''
            if msg_mode_name == 'AtlasLog':
                if msg_mode_event == 'GenerateClick':
                    print("generate_click msg_mode_path:", msg_mode_path)

                    if len(msg_mode_path) == 0 or not os.path.exists(msg_mode_path):
                        return "Error!!!Not found the file path,pls check."
                    all_file_list = common.get_file_path_list(msg_mode_path, True)
                    print('all_file_list count:', len(all_file_list))
                    records_path_list = common.filter_list(all_file_list, [r'system/records.csv'])
                    print('file_list count:', len(records_path_list))
                    if len(records_path_list) < 1:
                        return 'Error!!!Information:Not found the records.csv file,pls check.'
                    index = 0
                    item_dict_arr = []
                    print('len(records_path_list)', len(records_path_list))
                    for records_file_path in records_path_list:
                        item_mode = atlas_log.ItemMode()
                        item_mode.get_mode(records_file_path, msg_mode_path)
                        item_mode.index = index
                        item_dict_arr.append(item_mode.get_dict())
                        # '---' + str(index) + '--' + item_mode.sn
                        # loading_message_dict = {
                        #     'message': item_mode.sn,
                        #     'index': str(index)
                        # }
                        #
                        # redisClient.set("loading", loading_message_dict)*1.0/len(records_path_list)

                        index = index + 1

                        redisClient.set_loading(item_mode.sn, index*1.0/len(records_path_list))
                        if index == len(records_path_list):
                            time.sleep(0.5)
                        print ('indexssss--', index)
                        print ('item_mode.sn--', item_mode.sn)

                    zmq_send_msg = item_dict_arr

                else:
                    pass

            elif msg_mode_name == 'AtlasScript':
                pass
            else:
                pass

            # s1 = 'name' in zmq_msg
            # zmqClient.send('finish')
            redisClient.redis.set("loading", 'finish')
            zmqClient.send(zmq_send_msg)
            if is_debug:
                break

            #
            # if len(zmq_msg) < 0:
            #
            #     ret = redisClient.redis[zmq_msg]
            #     table_data = redisClient.get_data_table(zmq_msg)
            #     if len(table_data) > 0:
            #         print("---get data:", table_data[0])
            #         zmqClient.send(table_data[0])
            #     else:
            #         print("---get data error")
            #         zmqClient.send("---get data error")
            #
            # else:
            #     time.sleep(0.05)

        except Exception as error:
            print('error:', error)
            break


if __name__ == '__main__':

    run()
    # # zmq_client = ZmqClient("tcp://127.0.0.1:3200")
    # zmqClient.send('sss')
    # result1 = zmqClient.recv()
    #
    # zmqClient.send('sss')
    # result2 = zmqClient.recv()

    print ('sss')