
import re,sys

#line = "Cats are smarter than dogs";
# 
#searchObj = re.search( r'(.*) are (.*?) .*', line, re.M|re.I)
# 
#if searchObj:
#   print "searchObj.group() : ", searchObj.group()
#   print "searchObj.group(1) : ", searchObj.group(1)
#   print "searchObj.group(2) : ", searchObj.group(2)
#else:
#   print "Nothing found!!"
#
#
def regexTest(content,pattern):

	# regex=re.compile(pattern)
	# print(regex.findall(content))

	print(re.findall(pattern,content))


if __name__ == '__main__':

    content = sys.argv[1]
    pattern = sys.argv[2]
    # content = "-----\\J407\\diag-pallas-44.06.81.bin----\\J408\\diag-pallas-48.05.82.bin--\\J409\\diag-pallas-41.02.84.bin"
    # pattern = r"diag-pallas-([\d.]+).bin"

    # print ('-----content is-----'+content + '----\n')
    # print ('-----pattern is-----'+pattern + '----\n')
    regexTest(content,pattern)


