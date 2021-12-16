#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/15 10:35 PM
# @Author: Ci-wei
# @File  : atlas_log.py

from cw_package import cw_common as common
import os


def get_user_dir_path(records_file_path):
    return common.delete_last_path_component(records_file_path, 2) + 'user'


def get_device_file_path(records_file_path):
    return common.delete_last_path_component(records_file_path, 1) + 'device.log'


def get_uart_file_path(records_file_path):
    return get_user_dir_path(records_file_path) + 'uart.log'


def get_slot(records_file_path):
    device_file_path = get_device_file_path(records_file_path)
    slot = 'NotFound'
    with open(device_file_path, 'r') as f:
        device_file_content = f.read()
        if common.is_contain_in_string(device_file_content, ['group0.G=1:S=slot1]', 'group0.Device_slot1']):
            slot = 'slot1'
        elif common.is_contain_in_string(device_file_content, ['group0.G=1:S=slot2]', 'group0.Device_slot2']):
            slot = 'slot2'
        elif common.is_contain_in_string(device_file_content, ['group0.G=1:S=slot3]', 'group0.Device_slot3']):
            slot = 'slot3'
        elif common.is_contain_in_string(device_file_content, ['group0.G=1:S=slot4]', 'group0.Device_slot4']):
            slot = 'slot4'
        return slot


def get_cfg_broadType(records_file_path):
    user_dir = get_user_dir_path(records_file_path)
    all_files_path = common.get_file_path_list(user_dir, False)
    log_files_path = common.filter_list(all_files_path, ['.log'])
    result_list = {'cfg': 'NotFound', 'boardType': 'NotFound'}
    if len(log_files_path):
        uart_path = log_files_path[0]
        with open(uart_path, 'r') as f:
            uart_content = f.read()
            type_arr = common.regular(uart_content, r'boot, Board\s+(.+\))')
            cfg_arr = common.regular(uart_content, r'syscfg print CFG#\s*[\d/\s:.]+([A-Z0-9-_]+)\n')
            if len(type_arr):
                result_list['boardType'] = type_arr[0]
            if len(cfg_arr):
                result_list['cfg'] = cfg_arr[0]
            else:
                cfg_arr = common.regular(uart_content, r'CFG#[\sValue]*:\s+(.+)')
                result_list['cfg'] = cfg_arr[0]

    return result_list


class ItemMode(object):
    def __init__(self):
        self.index = 0
        self.sn = 'NotFound'
        self.slot = 'NotFound'
        self.cfg = 'NotFound'
        self.broadType = 'NotFound'
        self.subDirName = 'NotFound'
        self.startTime = 'NotFound'
        self.endTime = 'NotFound'
        self.testTime = ''
        self.endTime = 'NotFound'
        self.recordPath = 'NotFound'
        self.failList = ''

    def get_dict(self):

        item_dict = {

            'index': self.index,
            'sn': self.sn,
            'slot': self.slot,
            'cfg': self.cfg,
            'broadType': self.broadType,
            'subDirName': self.subDirName,
            'startTime': self.startTime,
            'endTime': self.endTime,
            'recordPath': self.recordPath,
            'failList': self.failList
        }

        return item_dict


def generate_click(log_path):
    print('log_path:', log_path)
    if len(log_path) == 0 or not os.path.exists(log_path):
        return "Error!!!Not found the file path,pls check."
    all_file_list = common.get_file_path_list(log_path, True)
    print('all_file_list count:', len(all_file_list))
    records_path_list = common.filter_list(all_file_list, [r'system/records.csv'])
    print('file_list count:', len(records_path_list))
    if len(records_path_list) < 1:
        return 'Error!!!Information:Not found the records.csv file,pls check.'
    index = 1
    item_dict_arr = []
    for records_file_path in records_path_list:
        item_mode = ItemMode()
        records_path_split_list = records_file_path.split(r'/')
        item_mode.index = index
        item_mode.sn = records_path_split_list[0]
        item_mode.recordPath = records_file_path
        item_mode.slot = get_slot(records_file_path)
        dict = get_cfg_broadType(records_file_path)
        item_mode.cfg = dict['cfg']
        item_mode.broadType = dict['boardType']

        index = index + 1
        item_dict_arr.append(item_mode.get_dict())
    # print('item_mode_arr:',item_dict_arr)
    return item_dict_arr


if __name__ == '__main__':
    pass

    # generate_click('/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504/unit-archive')
    # log_path = '/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504/unit-archive/DLX1133006S0NC419/20210417_0-33-14.413-F2C24C/system/device.log'
    # get_slot(log_path)
    # get_cfg_broadType(log_path)
