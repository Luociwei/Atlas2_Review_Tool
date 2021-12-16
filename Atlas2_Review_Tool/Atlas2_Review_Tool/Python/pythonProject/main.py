# This is a sample Python script.
import json
from cw_package import cw_redis
from cw_package import cw_zmq
from atlaslog_package import atlas_log

is_debug = 0
if is_debug:
    dict = {
        'name': 'AtlasLog',
        'event': 'GenerateClick',
        'params': ["/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504/unit-archive"]
    }
    test_str = json.dumps(dict)
    # BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    # print("BASE_DIR:", BASE_DIR)
    # sys.path.insert(0,BASE_DIR+'/site-packages/')
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
                    zmq_send_msg = atlas_log.generate_click(msg_mode_path)

                else:
                    pass

            elif msg_mode_name == 'AtlasScript':
                pass
            else:
                pass

            # s1 = 'name' in zmq_msg
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
