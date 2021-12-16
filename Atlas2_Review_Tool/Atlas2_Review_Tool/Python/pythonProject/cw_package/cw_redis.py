#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/11 2:31 PM
# @Author: Ci-wei
# @File  : cwRedis.py
import re

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


class RedisClient(object):
    def __init__(self):
        self.redis = redis.Redis(host='localhost', port=6379, decode_responses=True)
        # self.redis = client
        self.redis.set('is_connect', 'yes')  # 设置 name 对应的值
        print(self.redis.get('is_connect'))  # 取出键 name 对应的值
        print(type(self.redis.get('is_connect')))  # 查看类型

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
    client.redis.set("item1", "0.01,0.03,0.02\n0.02,0.03,0.01")
    client.get_data_table("item1")
