#!/usr/bin/python

import sys
import os
import xml.sax
import l10nhandler
import indexhandler
import indexwriter
import cmlhandler
import cmlwriter

langList = ["en"]
src_root = os.pardir + os.path.sep + "src"

os.chdir(src_root)

#src_list = os.listdir(os.curdir)
src_list=['alcohols']

# Parse l10n.xml for l10n support
l10n_parser = xml.sax.make_parser()
l10n_handler = l10nhandler.L10NHandler()
l10n_parser.setContentHandler(l10n_handler)
l10n_parser.parse("../xml/l10n.xml")

# Parse the base directory. I need to evolve to an recurrent stuff
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_external_ges, 0)
handler = indexhandler.IndexHandler()
parser.setContentHandler(handler)
parser.parse("index.xml")

for entry in handler.entryList:
  if entry.dirname != "" and os.path.isdir(entry.dirname):
  #if entry.dirname == "alcohols":
    # Parse index.xml and for each file open the dir.
    level = 0
    os.chdir(entry.dirname)
    
    level += 1
    if os.path.isfile("index.xml"):
        index_parser = xml.sax.make_parser()
	index_parser.setFeature(xml.sax.handler.feature_external_ges, 0)
	index_handler = indexhandler.IndexHandler()
	index_parser.setContentHandler(index_handler)
	index_parser.parse("index.xml")
        index = indexwriter.IndexWriter("index.xml",index_handler,l10n_handler)
	print index_handler.title['en']
	for index_entry in index_handler.entryList:
          index = indexwriter.IndexWriter("index.xml",index_handler,l10n_handler)
	  if index_entry.filename != "" and os.path.isfile(index_entry.filename + ".cml"):
            cml_parser = xml.sax.make_parser()
            cml_handler = cmlhandler.CMLHandler()
            cml_parser.setContentHandler(cml_handler)
            cml_parser.parse(index_entry.filename + ".cml")

	    for lang in langList:
              index = indexwriter.IndexWriter("index_" + lang + ".html",index_handler,l10n_handler)
              index.WriteXHTML("Index",lang,level)
              cml = cmlwriter.CMLWriter(index_entry.filename + "_" + lang + ".html", cml_handler,l10n_handler)
              cml.WriteXHTML("Molecule title",lang,level)
	  elif entry.dirname != "" and os.path.isdir(entry.dirname):
	    print entry.dirname + " is a directory"
	  else:
	    print "error on " + index_entry.filename
    os.chdir(os.pardir)
