#!/usr/bin/python
#
# parse_feed.py
#
# script that parses out individual posts from feeds and saves everything as simple XML files (one post per file).
# we used to have a Python script that parsed out the posts, blog details etc. and put things in the database straight away.
# we changed things because:
#
# * this way we don't have to store the content of every post in the database, but we can still search or retrieve them when necessary
# * it keeps configuration simple (we only need to tell Perl and PHP the database login details, for example)
# * it reduces the amount of Python code - the rest of the pipeline is all in Perl.
# * shorter scripts are easier to debug and maintain
#
# some info about writing XML with Python: http://www.xml.com/pub/a/2002/11/13/py-xml.html
#
# This script can take a list of feeds (on the command line) as arguments: in that case, it only parses the feeds you supply.
# Useful for debugging and incrementally updating the list of posts...

import sys
import os
import feedparser
import glob
import md5
import string
from xml.sax import saxutils

ENCODING = 'ascii'
ENCODING_ERRORS = 'ignore'
FEED_DIR = "feeds/"
POSTS_DIR = "posts/"
DEBUG = 1
DO_POSTS = 1 # do posts or just refresh feed details?

# get attributes from posts.
def test_and_print(entry,key):
  if entry.has_key(key):
    try:
      value = entry[key]
      return value
    except UnicodeEncodeError:
      print "a unicode error happened"
      sys.exit()
    except:
      print "Some horrible error happened."
      sys.exit()
  else:
    return "no such key"

# get attributes from the feed itself.
def get_feed_attr(feed,attr):
  try:
    if feed.has_key(attr):
      return feed.get(attr)
    else:
      return "no such attr"
  except UnicodeEncodeError:
    print "a unicode error happened"
    sys.exit()
  except:
    print "Some horrible error happened."
    sys.exit()
    
def md5_hash(input):
  m = md5.new()
  m.update(input)
  hash = m.hexdigest()
  return hash
  
def parse_file(file):
  if DEBUG:
    print "\n"
    print file

  # the feed_id is the last 32 chars of the file (feed_ids are a constant length: they're an md5 hash)
  feed_id = file[len(file) - 32:len(file)]
  
  try:
    feed = feedparser.parse(file)
  except UnicodeDecodeError:
	print "A unicode error happened in feedparser.py"
	return
	
  # first get feed information.
  title = get_feed_attr(feed['feed'],'title').encode(ENCODING, ENCODING_ERRORS)
  link =  get_feed_attr(feed['feed'],'link').encode(ENCODING, ENCODING_ERRORS)
  description = get_feed_attr(feed['feed'],'description').encode(ENCODING, ENCODING_ERRORS)
  summary = get_feed_attr(feed['feed'],'summary').encode(ENCODING, ENCODING_ERRORS)

  if len(description) <= 0:
	description = summary

  if DEBUG:
    print title + " " + link
    print description

  # write this information to disk. The filename is a hash of the feed_id (file)
  feed_filename = POSTS_DIR + "feed_info_" + feed_id
  this_feed_dir = feed_id + "/"

  # create the feed directory if it doesn't already exist
  if not (os.path.exists(POSTS_DIR + this_feed_dir) and os.path.isdir(POSTS_DIR + this_feed_dir)):
  	os.mkdir(POSTS_DIR + this_feed_dir)

  feed_info = open(feed_filename, 'w')
  
  feed_info.write('<?xml version="1.0" encoding="' + ENCODING + '"?>\n')
  feed_info.write("<feed>\n")
  feed_info.write("\t<title>" + saxutils.escape(title).encode(ENCODING) + "</title>\n")
  feed_info.write("\t<feed_id>" + saxutils.escape(feed_id).encode(ENCODING) + "</feed_id>\n")
  feed_info.write("\t<link>" + saxutils.escape(link).encode(ENCODING) + "</link>\n")
  feed_info.write("\t<description><![CDATA[" + saxutils.escape(description).encode(ENCODING) + "]]></description>\n")
  feed_info.write("</feed>")

  if DO_POSTS == 0:
    return

  # now get all the posts.
  entries = feed.entries

  for entry in entries:
    try:
      title = test_and_print(entry,'title').encode(ENCODING, ENCODING_ERRORS)
      link = test_and_print(entry,'link').encode(ENCODING, ENCODING_ERRORS)
      description = test_and_print(entry,'description').encode(ENCODING, ENCODING_ERRORS)
      date = test_and_print(entry,'date').encode(ENCODING, ENCODING_ERRORS)
      tags = ()
      if entry.has_key("categories"):
      	tags = entry.categories

      if date == "no such attr":
        date = test_and_print(entry,'published').encode(ENCODING, ENCODING_ERRORS)

      content = test_and_print(entry,'content')
      if content != "no such key":
        # find the longest content dictionary entry.
        longest = content[0]
        longest_len = len(longest.value.encode(ENCODING, ENCODING_ERRORS))
        for content_entry in content:
          # find the longest content entry associated with this post.
          if len(content_entry.value.encode(ENCODING, ENCODING_ERRORS)) > longest_len:
            longest = content_entry

          newdescription = longest.value.encode(ENCODING, ENCODING_ERRORS)

          # this, uh, may or may not work. We're basically assuming that the longest piece of content associated
          # with a post is the actual post body.
          if len(newdescription) > (len(description) + 1):
            description = newdescription

      if DEBUG:
        print title

      # the filename for each post is a hash of the post URL.
      post_filename = POSTS_DIR + this_feed_dir + "post_" + md5_hash(link)
      
      post_info = open(post_filename, 'w')
      
      post_info.write('<?xml version="1.0" encoding="' + ENCODING + '"?>\n')
      post_info.write("<post>\n");
      post_info.write("\t<feed_id>" + saxutils.escape(feed_id).encode(ENCODING, ENCODING_ERRORS) + "</feed_id>\n");
      post_info.write("\t<title>" + saxutils.escape(title).encode(ENCODING, ENCODING_ERRORS) + "</title>\n");
      post_info.write("\t<link>" + saxutils.escape(link).encode(ENCODING, ENCODING_ERRORS) + "</link>\n");
      post_info.write("\t<date>" + saxutils.escape(date).encode(ENCODING, ENCODING_ERRORS) + "</date>\n");
      for tag in tags:
		post_info.write("\t<tag>" + saxutils.escape(tag[1]).encode(ENCODING, ENCODING_ERRORS) + "</tag>\n");  
      post_info.write("\t<description><![CDATA[" + saxutils.escape(description).encode(ENCODING, ENCODING_ERRORS) + "]]></description>\n");
      post_info.write("</post>\n");
      
    except Exception, details:
      print "An error occurred when processing a post."
      print details
      #sys.exit(0)



# *** EXECUTION STARTS HERE ***
if len(sys.argv) > 1:
  sys.argv.pop(0)
  files = sys.argv
else:
  files = glob.glob(FEED_DIR + "*")

for file in files:
  if ( (os.path.getsize(file) > 0) and (os.path.isfile(file)) ):
    parse_file(file)
  else:
    if DEBUG:
      print "Skipping" + file + ", which has size 0\n"

  
  
