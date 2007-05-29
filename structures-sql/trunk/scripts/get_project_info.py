#!/usr/bin/python

import sys
import os
import xml.sax
import cmlhandler

src_root =  "../../trunk/src"

skip_dir = ['jmol','images']

os.chdir(src_root)

src_list = os.listdir(os.curdir)

count = 0

for dir in src_list:
  if os.path.isdir(dir) and dir not in skip_dir:
    os.chdir(dir)
    file_list = os.listdir(os.curdir)
    for file in file_list:
      if len(file) > 4 and file[-4:] == '.cml':
        parser = xml.sax.make_parser()
	handler = cmlhandler.CMLHandler()
	parser.setContentHandler(handler)
	parser.parse(file)
        count = count + 1
	if handler.mpt != "" and handler.bpt != "":
	  if handler.mpt.count("> "):
            mpt = int(handler.mpt[2:])
	  else:
            mpt = int(handler.mpt)
	  if handler.bpt.count("> "):
            bpt = int(handler.bpt[2:])
	  else:
            bpt = int(handler.bpt)
	  if (bpt - mpt) < 0:
	    print "Error: " + handler.name + " - " + str(mpt) + "(mpt) is higher than "+ str(bpt) + " (bpt)"
	if handler.mpt == "" and handler.mptSet:
	  print "Error: " + handler.name + " mpt value is null"

	if handler.bpt == "" and handler.bptSet:
	  print "Error: " + handler.name + " bpt value is null"

    os.chdir(os.pardir)

print "Number of structures: " + str(count)
