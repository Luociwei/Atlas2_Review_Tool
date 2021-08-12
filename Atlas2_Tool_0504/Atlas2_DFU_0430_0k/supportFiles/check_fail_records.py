#!/usr/bin/env python
# Jayson Ye
import sys
import os

def isNeedToSkip(TestName,SubTestName,SubSubTestName,Status,failureMessage):
	if Status not in ["FAIL"]:
		return True
	if TestName in []:
		return True
	if SubTestName in []:
		return True
	if SubSubTestName in []:
		return True
	if failureMessage in ["Station is not secure","no input sn"]:
		return True
	return False

if __name__ == '__main__':
	isFirstOne = True
	if len(sys.argv) != 2:
		print "argv error"
	else:
		filePath = sys.argv[1]
		filePath = filePath.replace('\\', '').strip()
		# nrows = ["filePath,TestName,SubTestName,SubSubTestName,Status,failureMessage"]
		failedCount = 0
		with open(filePath,'r+') as f:
			content = f.read()
			rows = content.split('\n')
			for row in rows:
				row = row.replace("\"","'")
				items = row.split(",")
				if len(items) > 13:
					if not isNeedToSkip(items[2],items[3],items[4],items[12],items[13]):
						failedCount += 1
		print str(failedCount)
	# return failedCount


