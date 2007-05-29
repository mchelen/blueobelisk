#!/usr/bin/python

import os
import sys
import MySQLdb

### Database parameters
host = "localhost"
username = ""
password = ""
database = ""

### Try to open MySQL connection
try:
    link = MySQLdb.connect(host = host,
                           user= username,
			   passwd = password,
			   db = database)
    cursor = link.cursor()
except MySQLdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

file_list = os.listdir(os.curdir)
for file in file_list:
    if file[-4:] == ".mol":
        f_in = open(file, 'r')

        molfile = f_in.readlines()

        moldata = ""
        count = 0
        name = ""
        for line in molfile:
            if count == 0:
                name = line.strip()
            moldata += line
            count += 1

        try:
            cursor.execute("""INSERT INTO structure (`name`,`molfile`)""" \
	                 + """ VALUES (%s,%s)""",(name,moldata)) 
        except MySQLdb.Error, e:
            print "Error %d: %s" % (e.args[0], e.args[1])
            print file
            sys.exit(1)

        f_in.close()

cursor.close()
link.commit()
link.close()

