#!/usr/bin/env python
# -*- coding:utf-8 -*-
# @Time  : 2021/12/15 10:35 PM
# @Author: Ci-wei
# @File  : atlas_log.py

from cw_package import cw_common as common
import os
import csv


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


def get_fail_item(records_file_path):
    with open(records_file_path, 'r') as f:
        items_list = csv.reader(f)
        title_count = 17
        status_index = 12
        fail_total = ''
        index = 0
        for item_list in items_list:
            if index == 0:
                title_count = len(item_list)
                status_index = item_list.index('status')
            else:
                if title_count == len(item_list):
                    if item_list[status_index].upper() == 'FAIL':
                        item_fail_list = item_list[2] + '-' + item_list[3] + '-' + item_list[4] + ';'
                        fail_total = fail_total + item_fail_list

            index = index + 1
        # print ('fail_total:{0})'.format(fail_total))
        return fail_total


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

            'Index': self.index,
            'Sn': self.sn,
            'SubDirName': self.subDirName,
            'Slot': self.slot,
            'CFG': self.cfg,
            'BroadType': self.broadType,
            'SubDirName': self.subDirName,
            'StartTime': self.startTime,
            'EndTime': self.endTime,
            'TestTime(s)': self.testTime,
            'recordPath': self.recordPath,
            'FailList ↑↓': self.failList
        }

        return item_dict

    def get_mode(self, records_file_path, log_path):
        new_records_file_path = records_file_path.replace(log_path, '')
        split_list = new_records_file_path.split(r'/')
        self.sn = split_list[1]
        self.subDirName = split_list[2]
        self.recordPath = records_file_path
        self.slot = get_slot(records_file_path)
        dict = get_cfg_broadType(records_file_path)
        self.cfg = dict['cfg']
        self.broadType = dict['boardType']
        self.failList = get_fail_item(records_file_path)


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
        new_records_file_path = records_file_path.replace(log_path, '')
        split_list = new_records_file_path.split(r'/')
        item_mode.index = index
        item_mode.sn = split_list[1]
        item_mode.subDirName = split_list[2]
        item_mode.recordPath = records_file_path
        item_mode.slot = get_slot(records_file_path)
        dict = get_cfg_broadType(records_file_path)
        item_mode.cfg = dict['cfg']
        item_mode.broadType = dict['boardType']
        item_mode.failList = get_fail_item(records_file_path)

        index = index + 1
        item_dict_arr.append(item_mode.get_dict())
    # print('item_mode_arr:',item_dict_arr)
    return item_dict_arr


if __name__ == '__main__':
    # pass
    # path = '/Users/ciweiluo/Desktop/records.csv'
    # get_fail_item(path)
    generate_click('/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/TestLog/unit-archive')
    # log_path = '/Users/ciweiluo/Desktop/Louis/GitHub/Atlas2_Tool_WS/Atlas2_Tool_0504/unit-archive/DLX1133006S0NC419/20210417_0-33-14.413-F2C24C/system/device.log'
    # get_slot(log_path)
    # get_cfg_broadType(log_path)
