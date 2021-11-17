#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function  # This line can fix "end='' can't be used by python2.x" issue
import sys,os,re,time

# read file name - match pattern
def fileName(path, pattern):
	files = os.listdir(path)
	for f in files:
		if pattern in f:
			return f

# read file name - except pattern
def otherFileName(path, patterns):
	files = os.listdir(path)
	for f in files:
		if patterns[0] in f:
			pass
		elif patterns[1] in f:
			pass
		elif patterns[2] in f:
			pass
		else:
			return f

# cat file - match single pattern
def fileDetail(path, pattern):
	loglines = open(path,"r").readlines()
	patternObject = re.compile(pattern)
	for line in loglines:
		matchObject = patternObject.search(line)
		if matchObject:
			value = matchObject.group(1)
			return value

# cat file - match various pattern
def fileDetail_var(path, patterns):
	loglines = open(path,"r").readlines()
	for pattern in patterns:
		patternObject = re.compile(pattern)
		for line in loglines:
			matchObject = patternObject.search(line)
			if matchObject:
				value = matchObject.group(1)
				break
			else:
				pass
	if value == None:
		value = "?"
	return value

# cat file - print all
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

# read the part of file name
def fileNamePart(path, pattern):
	files = os.listdir(path)
 	findDir = ""
	patternObject = re.compile(pattern)
	for f in files:
		matchObject = patternObject.search(f)
		if matchObject:
			findDir = matchObject.group(1)
		#	print(findDir)
		# else:
		#	print("?")
	return findDir 

# main()
def versionCatch():
	productPath = "/vault/data_collection/test_station_config/gh_station_info.json"
	productPattern = "\"PRODUCT\" \: \"J([0-9]+)\""
	productName = fileDetail(productPath, productPattern)

	# Bundle version
	osWhat = "OS_VERSION: "
	osPath = "/Users/gdlocal/RestorePackage"
	osPattern = ["Current", "ROOT", ".D"]
	print('\033[1m' + osWhat + '\033[0m' + otherFileName(osPath, osPattern))
	
	# iBoot version
	ibootWhat = "iBoot_VERSION: "
	ibootPath = os.path.join(osPath, "CurrentBundle/Restore/Firmware/all_flash/iBoot.j{}.RELEASE.im4p".format(productName))
	ibootPattern1 = "(iBoot\-\d+\.\d+\.\d+\.\d+\.\d+)"
	ibootPattern2 = "(iBoot\-\d+\.\d+\.\d+\.\d+)"
	ibootPattern3 = "(iBoot\-\d+\.\d+\.\d+)"
	ibootPattern4 = "(iBoot\-\d+\.\d+)"
	ibootPattern = [ibootPattern4, ibootPattern3, ibootPattern2, ibootPattern1]
	print('\033[1m' + ibootWhat + '\033[0m' + fileDetail_var(ibootPath, ibootPattern))
	
	# Diags version
	diagSetting = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/BuildManifest.plist"
	bundlePath = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore"
	diagsPath_8A = fileDetail(diagSetting, "<string>(\w+\/\w+?\/?\w+?\/?\w+?\/?diag-\w+\d+?\w+?.im4p)</string>")
	if diagsPath_8A == None:
		diagsPath_8A = fileDetail(diagSetting, "<string>(\w+\/diag-DUMMY.im4p)</string>")
	diagsImagePath = os.path.join(bundlePath, diagsPath_8A)
	diagsWhat = "Diags_VERSION: "
	diagsPattern = 'Tag:		(.*)'
	print('\033[1m' + diagsWhat + '\033[0m' + fileDetail(diagsImagePath, diagsPattern))

	diagsTimeWhat = "Diags_DATE: "
	# diagsPath = os.path.join(osPath, bundleFile)
	diagsDatePattern = "Date\:\s+(\d+\/\d+\/\d+\s+\d+\:\d+\:\d+\s+[A-Z]+)"
	print('\033[1m' + diagsTimeWhat + '\033[0m' + fileDetail(diagsImagePath, diagsDatePattern))

	# BBFW version
	bbWhat = "BB_VERSION: "
	bbPath = "/Users/gdlocal/RestorePackage/CurrentBaseband"
	bbPattern = ".zip"
	if os.path.exists(bbPath):
		print('\033[1m' + bbWhat + '\033[0m' + fileName(bbPath, bbPattern))
		
	else:
		bbPath = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/Firmware"
		bbPattern = ".bbfw"
		print('\033[1m' + bbWhat + '\033[0m' + fileName(bbPath, bbPattern) + " (Bundle Default)")
	
	# RTOS version
	rtosWhat = "RTOS_VERSION: "
	rtosPath = os.path.join(bundlePath, "FactoryTests/j{}/console.j{}.im4p".format(productName, productName))
	rtosPattern = "BUILDINFO(.*RELEASE)"
	print('\033[1m' + rtosWhat + '\033[0m' + fileDetail(rtosPath, rtosPattern))

	# RBM version
	rbmWhat = "RBM_VERSION: "
	rbmPath = os.path.join(bundlePath, "FactoryTests/j{}/rbm.j{}.im4p".format(productName, productName))
	rbmPattern = 'build-revision " (.*)"'
	print('\033[1m' + rbmWhat + '\033[0m' + fileDetail(rbmPath, rbmPattern))

	# for bundle default
	os.system("open /Users/gdlocal/RestorePackage/CurrentBundle/Restore/j{}\(null\).dmg".format(productName))
	time.sleep(2)
	
	dmgName = fileName("/Volumes", "Extras")
	dmgPath = "O"
	
	if dmgName != None:
		dmgPath = os.path.join("/Volumes", dmgName)

	# BBLib version
	bblibWhat = "BBLib_VERSION:  "
	rootPath = os.path.join(osPath, "CurrentRoot/AppleInternal/Diags")
	bblibPath = os.path.join(rootPath, "Logs/Smokey/Shared/BBLib/Latest/lib/libconst.lua")
	bblibPattern = 'BBLibVer(.*)'
	if os.path.exists(bblibPath):
		print('\033[1m' + bblibWhat + '\033[0m' + fileDetail(bblibPath, bblibPattern))
	elif dmgPath != "O":
		bblibPath =  os.path.join(dmgPath, "AppleInternal/Diags/Logs/Smokey/Shared/BBLib/Latest/lib/libconst.lua")
		print('\033[1m' + bblibWhat + '\033[0m' + fileDetail(bblibPath, bblibPattern) + " (Bundle Default)")
	else:
		print('\033[1m' + bblibWhat + '\033[0m' + "no found")

	# Grape version
	grapeWhat = "Grape_VERSION: "
	grapeFirstPath = os.path.join(rootPath, "Grape")
	grapePattern = 'J{}-GrapeFW-(.*).im4p'.format(productName)
	if os.path.exists(grapeFirstPath):
		grapeSecondFile = fileName(grapeFirstPath, "J")
		grapePath = os.path.join(grapeFirstPath, grapeSecondFile, "GrapeFirmware.prm")
		if os.path.exists(grapePath):
			print('\033[1m' + grapeWhat + '\033[0m' + fileDetail(grapePath, grapePattern))
		else:
			grapePath = os.path.join(grapeFirstPath, grapeSecondFile)
			grapeImage = fileName(grapePath, "im4p")
			print('\033[1m' + grapeWhat + '\033[0m' + grapeImage + " GrapeFirmware.prm no found!")
	elif dmgPath != "O":
		grapeFirstPath =  os.path.join(dmgPath, "AppleInternal/Diags/Grape")
		grapeSecondFile = fileName(grapeFirstPath, "J")
		grapePath = os.path.join(grapeFirstPath, grapeSecondFile, "GrapeFirmware.prm")
		print('\033[1m' + grapeWhat + '\033[0m' + fileDetail(grapePath, grapePattern) + " (Bundle Default)")
	else:
		print('\033[1m' + grapeWhat + '\033[0m' + "no found")
	
	# Scorpius version
	scorpiusWhat = "Scorpius_VERSION: "
	scorpiusFirstPath = os.path.join(rootPath, "Scorpius")
	scorpiusPattern = 'VERSION: (.*)'
	if os.path.exists(scorpiusFirstPath):
		scorpiusSecondFile = fileName(scorpiusFirstPath, "J")
		scorpiusPath = os.path.join(scorpiusFirstPath, scorpiusSecondFile, "releasenotes.txt")
		if os.path.exists(scorpiusPath):
			print('\033[1m' + scorpiusWhat + '\033[0m' + fileDetail(scorpiusPath, scorpiusPattern)+ " (From Releasenotes Latest)")
		else:
			print('\033[1m' + scorpiusWhat + '\033[0m' + "?")
	elif dmgPath != "O":
		scorpiusFirstPath =  os.path.join(dmgPath, "AppleInternal/Diags/Scorpius")
		scorpiusSecondFile = fileName(scorpiusFirstPath, "J")
		scorpiusPath = os.path.join(scorpiusFirstPath, scorpiusSecondFile, "releasenotes.txt")
		print('\033[1m' + scorpiusWhat + '\033[0m' + fileDetail(scorpiusPath, scorpiusPattern) + " (Bundle Default Latest)")
	else:
		print('\033[1m' + scorpiusWhat + '\033[0m' + "no found")

	productName_B = int(productName) + 1
	# Wifi version
	wifiWhat = "WIFI_VERSION: "
	wifiPath1 = os.path.join(rootPath, "WiFiFirmware/J{}/WifiFirmware.prm".format(productName))
	wifiPath2 = os.path.join(rootPath, "WiFiFirmware/J{}/WifiFirmware.prm".format(productName_B))
	if os.path.exists(wifiPath1):
		fileAll(wifiWhat, wifiPath1, wifiPath2)
	elif dmgPath != "O":
		wifiPath1 = os.path.join(dmgPath, "AppleInternal/Diags/WiFiFirmware/J{}/WifiFirmware.prm".format(productName))
		wifiPath2 = os.path.join(dmgPath, "AppleInternal/Diags/WiFiFirmware/J{}/WifiFirmware.prm".format(productName_B))
		fileAll(wifiWhat, wifiPath1, wifiPath2)
		print("(Bundle Default)")
	else:
		print('\033[1m' + wifiWhat + '\033[0m' + "no found")

	# Bluetooth version
	btWhat = "BLUETOOTH_VERSION: "
	btPath1 = os.path.join(rootPath, "BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName))
	btPath2 = os.path.join(rootPath, "BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName_B))
	if os.path.exists(btPath1):
		fileAll(btWhat, btPath1, btPath2)
	elif dmgPath != "O":
		btPath1 = os.path.join(dmgPath, "AppleInternal/Diags/BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName))
		btPath2 = os.path.join(dmgPath, "AppleInternal/Diags/BluetoothPCIE/J{}/BluetoothFirmware.prm".format(productName_B))
		fileAll(btWhat, btPath1, btPath2)
		print("(Bundle Default)")
	else:
		print('\033[1m' + btWhat + '\033[0m' + "no found")

	os.system("umount /Volumes/{}".format(dmgName))

print("")
print("Ver.10 |(σ｀д′)σ| Updated at 2020-12-18 17:29")
print("———— ♥︎ ———— ♥︎ ———— ♥︎ ———— ฅ՞•ﻌ•՞ฅ♥︎ ")
print("Current Version As Below:")
print("———— ♥︎ ———— ♥︎ ———— ♥︎ ————  ʕ·͡ˑ·ཻʔ♥︎ ")

versionCatch()
