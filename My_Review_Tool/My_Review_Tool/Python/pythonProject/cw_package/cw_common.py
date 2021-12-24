#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/15 4:18 PM
# @Author: Ci-wei
# @File  : cw_common.py
import os
import re
import platform


# def my_print(word):
#     if 1:
#         print(word)
#

def regular(content, pattern):

    re_pattern = re.compile(pattern)
    results = re_pattern.findall(content)
    return results


def delete_last_path_component(path, level):

    split_arr = path.split(r'/')
    count = len(split_arr)
    file_path = ''
    for index in range(count-level):
        file_path = file_path + split_arr[index] + '/'
    return file_path


def is_contain_all_in_string(string, keyword_arr):
    result = True
    for keyword in keyword_arr:
        if keyword.lower() not in string.lower():
            result = False
            break
    return result


def is_contain_in_string(string, keyword_arr):
    result = False
    for keyword in keyword_arr:
        if keyword.lower() in string.lower():
            result = True
            break
    return result


def filter_list(arr, keyword_arr):
    new_arr = []
    for path in arr:
        for keyword in keyword_arr:
            if keyword.lower() in path.lower():
                new_arr.append(path)
                break
    return new_arr


def get_file_path_list(dir_path, is_deep_find):
    file_arr = []
    for root, dirs, files in os.walk(dir_path):
        for file in files:
            if is_deep_find:
                file_arr.append(os.path.join(root, file))
            else:
                if root == dir_path:
                    file_arr.append(os.path.join(root, file))

    return file_arr


def get_version():
    version = platform.python_version()
    print("platform.python_version():", platform.python_version())
    split_arr = version.split(r'.')
    return int(split_arr[0])



# else:
#     filelist = os.listdir(dir_path)
#     print(f'file_arr:{file_arr}')


if __name__ == '__main__':

    test_path = r'/Users/ciweiluo/Desktop/RedisZMQ'
    new_path = delete_last_path_component(test_path, 2)
    print(new_path)
