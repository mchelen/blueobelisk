#!/usr/bin/python
"""This module can transform index file into xhtml file

No class or function are defined
"""
import sys
import os
import xml.sax
import l10nhandler
import indexhandler
import indexwriter
import cmlhandler
import cmlwriter

source_dir = sys.argv[1]
if not os.path.isdir(source_dir):
    sys.stderror.write("[ERROR] %s: no such directory.\n" % (source_dir))
    sys.exit(1)
indexFile = sys.argv[2]
level = int(sys.argv[3])
langList = sys.argv[4:]
# Get the level into CMake ?
root = os.path.realpath(os.curdir)

if os.path.isfile(indexFile):

  # Parse l10n.xml for l10n support
  l10n_parser = xml.sax.make_parser()
  l10n_handler = l10nhandler.L10NHandler()
  l10n_parser.setContentHandler(l10n_handler)
  l10n_parser.parse(source_dir + "/xml/l10n.xml")

  # Parse index file
  index_parser = xml.sax.make_parser()
  index_parser.setFeature(xml.sax.handler.feature_external_ges, 0)
  index_handler = indexhandler.IndexHandler()
  index_parser.setContentHandler(index_handler)
  index_parser.parse(indexFile)
  index = indexwriter.IndexWriter(indexFile,index_handler,l10n_handler)
  for lang in langList:
      index = indexwriter.IndexWriter("index_" + lang \
                                    + ".html",index_handler,l10n_handler)
      index.WriteXHTML(index_handler.title,lang,level)

  # Add dir entry to the index file
  for index_entry in index_handler.entryList["file"]:
      if index_entry.path != "" and os.path.isfile(index_entry.path + ".cml"):
        cml_parser = xml.sax.make_parser()
        cml_handler = cmlhandler.CMLHandler()
        cml_parser.setContentHandler(cml_handler)
        cml_parser.parse(index_entry.path + ".cml")
        for lang in langList:
            cml = cmlwriter.CMLWriter(index_entry.path + "_" + lang \
                                    + ".html", cml_handler,l10n_handler)
            cml.WriteXHTML(index_entry,lang,level)

