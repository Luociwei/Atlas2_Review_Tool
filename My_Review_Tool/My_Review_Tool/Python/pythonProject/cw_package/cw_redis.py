#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/11 2:31 PM
# @Author: Ci-wei
# @File  : cwRedis.py
import re
import json
import time

try:
    import redis

except Exception as e:
    print('import redis error:', e)


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


def is_contain_all_in_string(string, keyword_arr):
    result = True
    for keyword in keyword_arr:
        if keyword.lower() not in string.lower():
            result = False
            break
    return result


class RedisClient(object):
    def __init__(self):
        self.redis = redis.Redis(host='localhost', port=6379, decode_responses=True)
        # self.redis = client
        self.set('is_connect', 'yes')  # 设置 name 对应的值
        print(self.get('is_connect'))  # 取出键 name 对应的值
        # print(type(self.get('is_connect')))  # 查看类型

    def flushdb(self):
        return self.redis.flushdb()

    def set(self, key_string, value):

        if type(key_string) != type(''):
            print ('the key_name inputted must be string!!!')
            return False
        b = type(value) == type('') or type(value) == type([]) or type(value) == type({})
        if not b:
            print ('the value inputted must be string or list or dict!!!')
            return False

        if len(key_string) == 0:
            error_mes = 'Error:the key_name inputted is null!!!'
            print (error_mes)
            return False
        b_result = True
        try:
            if len(value):
                new_value = value
                if type(value) == type([]) or type(value) == type({}):
                    new_value = json.dumps(value)
                self.redis.set(key_string, new_value)
        except Exception as err:
            print(err)
        else:
            b_result = False
        finally:
            return b_result

    def get(self, key_string):
        if type(key_string) != type(''):
            error_mes = 'Error:the key_name inputted must be string!!!'
            print (error_mes)
            return error_mes
        if len(key_string) == 0:
            error_mes = 'Error:the key_name inputted is null!!!'
            print (error_mes)
            return error_mes

        recv = self.redis.get(key_string)
        is_json_str = is_contain_all_in_string(recv, ['[', ']']) or is_contain_all_in_string(recv, ['{', '}'])

        if not is_json_str:  # is not a json string
            return recv
        try:
            json_recv = json.loads(recv)
            if type(json_recv) == type([]) or type(json_recv) == type({}):
                recv = json_recv
        except Exception as result:
            print(result)
        else:
            pass
        finally:
            return recv

    def get_common(self):
        return self.get('common')

    def set_common(self, data_title, data_info):
        if not len(data_title):
            data_title = ''
        if not len(data_info):
            data_info = ''

        message_dict = {
            'title': data_title,
            'info': data_info,

        }
        return self.set('common', message_dict)

    def set_common_warning(self, data_info):
        return self.set_common('warning', data_info)

    def set_common_loading(self, data_info):
        return self.set_common('loading', data_info)

    def get_data_table(self, key):
        tb = self.redis.get(key)
        print("self.redis.get", tb)
        tb_data = []
        if tb:
            # tb = tb.decode('utf-8')
            tb = tb.split("\n")
            # tb = (tb[1:-1])  # 去掉数据库首尾元素
            for i in tb:
                k = re.sub('\"', '', i)  # 去掉数据库引号
                h = re.sub(',', '', k)  # 去掉数据库逗号
                m = h.strip()  # 去掉数据库首尾空白
                if is_number(m):
                    tb_data.append(eval(m))  # 去掉数字的引号
                else:
                    tb_data.append(m)
        else:
            tb_data.append('')

        return tb_data


if __name__ == '__main__':
    client = RedisClient()

    # client.set_loading('1222', 0.22)
    # client.get_loading()
    # time.sleep(1)
    if client.set('test', 0.111):
        ret = client.get('test')
        print ('ret:', type(ret))
    # client.redis.set("item1", "0.01,0.03,0.02\n0.02,0.03,0.01")
    # client.get_data_table("item1")
