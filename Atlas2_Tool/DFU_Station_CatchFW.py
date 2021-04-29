#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function  # This line can fix "end='' can't be used by python2.x" issue
import sys,os,re

# read file name
def fileName(what, path, pattern):
	files = os.listdir(path)
	for f in files:
		if pattern in f:
			print('\033[1m' + what + '\033[0m' + f)
		else:
			print('\033[1m' + what + '\033[0m' + "?")

def fileName1(what, path, pattern):
	files = os.listdir(path)
	for f in files:
		if pattern in f:
			print('\033[1m' + what + '\033[0m' + f)

def findOtherPath(what, path):
	files = os.listdir(path)
	for f in files:
		if "Current" in f:
			pass
		elif "ROOT" in f:
			pass
		elif ".D" in f:
			pass
		else:
			print('\033[1m' + what + '\033[0m' + f)

# cat file with pattern
def fileDetail(what, path, pattern):
	loglines = open(path,"r").readlines()
	patternObject = re.compile(pattern)
	for line in loglines:
		matchObject = patternObject.search(line)
		if matchObject:
			value = matchObject.group(1)
			break
		else:
			value="?"
	print('\033[1m' + what + '\033[0m' + value)


def fileDe(path, pattern):
    loglines = open(path,"r").readlines()
    patternObject = re.compile(pattern)
    for line in loglines:
        matchObject = patternObject.search(line)
        if matchObject:
            value = matchObject.group(1)
            return value

# cat file
def fileAll(what, path1, path2):
	print('\033[1m' + what + '\033[0m')

	loglines1 = open(path1,"r").readlines()
	lines1 = len(loglines1)
	for line1 in range(lines1):
		print(loglines1[line1], end='')
	print("")
	loglines2 = open(path2,"r").readlines()
	lines2 = len(loglines2)
	for line2 in range(lines2):
		print(loglines2[line2], end='')
	print("")

# read file name by canshu
def findPath(path, pattern):
    files = os.listdir(path)
    findDir = ""
    for f in files:
        if pattern in f:
            return f

def findProduct(path, pattern):
    loglines = open(path,"r").readlines()
    patternObject = re.compile(pattern)
    for line in loglines:
        matchObject = patternObject.search(line)
        if matchObject:
            value = matchObject.group(1)
            return value
        else:
            value="?"            

# read the part of file name
def fileNamePart(path, pattern):
    files = os.listdir(path)
    findDir = ""
    patternObject = re.compile(pattern)
    for f in files:
        matchObject = patternObject.search(f)
        if matchObject:
            findDir = matchObject.group(1)
        #     print(findDir)
        # else:
        #     print("?")
    return findDir


def versionCatch():
	# bundle version
	osWhat = "OS_VERSION: "
	osPath = "/Users/gdlocal/RestorePackage"
	# osPattern = "Azul"
	findOtherPath(osWhat, osPath)
	# fileName(osWhat, osPath, osPattern)
	# bundleFile = findPath(osPath, osPattern)
	# print(bundleFile)

	productPath = "/Users/gdlocal/Desktop/Restore Info.txt"
	productPattern = "PRODUCT=J([0-9]+)"
	productName = findProduct(productPath, productPattern)
	
	# iBoot version
	ibootWhat = "iBoot_VERSION: "
	ibootPath = os.path.join(osPath, "CurrentBundle/Restore/Firmware/all_flash/iBoot.j{}.RELEASE.im4p".format(productName))
	ibootPattern = "(iBoot\-\d+\.\d+\.\d+\.?\d+?\.?\d+?)"
	fileDetail(ibootWhat, ibootPath, ibootPattern)
	
	# Diags version
	diagSetting = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/BuildManifest.plist"
	bundlePath = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore"
	diagsPath_8A = fileDe(diagSetting, "<string>(\w+\/\w+?\/?\w+?\/?\w+?\/?diag-\w+\d+?\w+?.im4p)</string>")
	if diagsPath_8A == None:
		diagsPath_8A = fileDe(diagSetting, "<string>(\w+\/diag-DUMMY.im4p)</string>")
	diagsImagePath = os.path.join(bundlePath, diagsPath_8A)
	diagsWhat = "Diags_VERSION: "
	# diagsPath = os.path.join(osPath, bundleFile)
	# diagsPath  = os.path.join(osPath, "CurrentBundle/Restore")
	# diagsPath1 = os.path.join(osPath, "CurrentBundle/Restore/Diags")
	# diagName = findPath(diagsPath1, "im4p")
	# diagsImagePath = os.path.join(diagsPath1, diagName)
	diagsPattern = 'Tag:		(.*)'
	fileDetail(diagsWhat, diagsImagePath, diagsPattern)

	diagsTimeWhat = "Diags_DATE: "
	# diagsPath = os.path.join(osPath, bundleFile)
	diagsDatePattern = "Date\:\s+(\d+\/\d+\/\d+\s+\d+\:\d+\:\d+\s+[A-Z]+)"
	fileDetail(diagsTimeWhat, diagsImagePath, diagsDatePattern)

	# BBFW version
	bbWhat = "BB_VERSION: "
	bbPath = "/Users/gdlocal/RestorePackage/CurrentBaseband"
	bbPattern = ".zip"
	if os.path.exists(bbPath):
		fileName1(bbWhat, bbPath, bbPattern)
	else:
		bbPath = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/Firmware"
		bbPattern = ".bbfw"
		fileName1(bbWhat, bbPath, bbPattern)
	
	# RTOS version
	rtosWhat = "RTOS_VERSION: "
	rtosPath = os.path.join(bundlePath, "FactoryTests/j{}/console.j{}.im4p".format(productName, productName))
	rtosPattern = "BUILDINFO(.*RELEASE)"
	fileDetail(rtosWhat, rtosPath, rtosPattern)

	# RBM version
	rbmWhat = "RBM_VERSION: "
	rbmPath = os.path.join(bundlePath, "FactoryTests/j{}/rbm.j{}.im4p".format(productName, productName))
	rbmPattern = 'build-revision " (.*)"'
	fileDetail(rbmWhat, rbmPath, rbmPattern)

	# BBLib version
	bblibWhat = "BBLib_VERSION:  "
	rootPath = os.path.join(osPath, "CurrentRoot/AppleInternal/Diags")
	bblibPath = os.path.join(rootPath, "Logs/Smokey/Shared/BBLib/Latest/lib/libconst.lua")
	if os.path.exists(bblibPath):
		bblibPattern = 'BBLibVer(.*)'
		fileDetail(bblibWhat, bblibPath, bblibPattern)
	else:
		print('\033[1m' + bblibWhat + '\033[0m' + "no found")

	# Grape version
	grapeWhat = "Grape_VERSION: "
	grapeFirstPath = os.path.join(rootPath, "Grape")
	if os.path.exists(grapeFirstPath):
		grapeSecondFile = findPath(grapeFirstPath, "J")
		grapePath = os.path.join(grapeFirstPath, grapeSecondFile, "GrapeFirmware.prm")
		if os.path.exists(grapePath):
			grapePattern = 'J{}-GrapeFW-(.*).im4p'.format(productName)
			fileDetail(grapeWhat, grapePath, grapePattern)
		else:
			grapePath1 = os.path.join(grapeFirstPath, grapeSecondFile)
			grapeImage = fileName(grapeWhat, grapePath, "im4p")
			print('\033[1m' + grapeWhat + '\033[0m' + "GrapeFirmware.prm no found!")
	else:
		print('\033[1m' + grapeWhat + '\033[0m' + "no found")
	
	# Scorpius version
	scorpiusWhat = "Scorpius_VERSION(Default): "
	scorpiusFirstPath = os.path.join(rootPath, "Scorpius")
	if os.path.exists(scorpiusFirstPath):
		scorpiusSecondFile = findPath(scorpiusFirstPath, "J")
		scorpiusPath = os.path.join(scorpiusFirstPath, scorpiusSecondFile, "releasenotes.txt")
		if os.path.exists(scorpiusPath):
			scorpiusPattern = 'VERSION: (.*)'
			fileDetail(scorpiusWhat, scorpiusPath, scorpiusPattern)
		else:
			print('\033[1m' + scorpiusWhat + '\033[0m' + "?")
	else:
		print('\033[1m' + scorpiusWhat + '\033[0m' + "no found")
		

	productName_B = int(productName) + 1
	# Wifi version
	wifiWhat = "WIFI_VERSION: "
	wifiPath1 = os.path.join(rootPath, "WiFiFirmware/J{}/WifiFirmware.prm".format(productName))
	wifiPath2 = os.path.join(rootPath, "WiFiFirmware/J{}/WifiFirmware.prm".format(productName_B))
	if os.path.exists(wifiPath1):
		fileAll(wifiWhat, wifiPath1, wifiPath2)
	else:
		print('\033[1m' + wifiWhat + '\033[0m' + "no found")

	# Bluetooth version
	btWhat = "BLUETOOTH_VERSION: "
	btPath1 = os.path.join(rootPath, "BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName))
	btPath2 = os.path.join(rootPath, "BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName_B))
	if os.path.exists(btPath1):
		fileAll(btWhat, btPath1, btPath2)
	else:
		print('\033[1m' + btWhat + '\033[0m' + "no found")


print("==============================")
print("Current Version As Below:")
print("==============================")
versionCatch()

