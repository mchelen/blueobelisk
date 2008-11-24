#!/usr/bin/python

"""This file generates the index filesi in the top directory:
- src/name_index_lang.html
- src/raw_formula_lang.html
- src/index_lang.html
"""

import sys
import os
import xml.sax
import l10nhandler
import indexhandler
import indexwriter
import nameindexwriter
import formulaindexwriter

def get_formula_ar(file):
  fin = open(unicode.encode(file) + ".cml", 'r')
  for line in fin:
    if line.count("formula concise"):
      idx = line.find('=') + 2
      line = line[idx:]
      idx = line.find('"')
      formula = line[:idx].strip()
      formula_ar = formula.split(" ")
      return formula_ar
  return []

def formulaCmp(tuple1, tuple2):
  formula1 = tuple1[0][0]
  formula2 = tuple2[0][0]
  if formula1 == formula2:
    return 0
  count = min( len(formula1), len(formula2) )
  for i in range(0, count):
    if i%2:
      if cmp( int(formula1[i]), int(formula2[i]) ) != 0:
        return cmp( int(formula1[i]), int(formula2[i]) )
    else:
      if cmp( formula1[i],formula2[i])  != 0:
        return cmp( formula1[i], formula2[i] )
  return cmp( len(formula1), len(formula2) )

sourceDir = sys.argv[1]
if not os.path.isdir(sourceDir):
    print "Error: "+ sourceDir + ": no such directory"
    sys.exit(1)
indexFile = sys.argv[2]
level = int(sys.argv[3])
langList = sys.argv[4:]

skip_dir = ['jmol','images','styles']

os.chdir(sourceDir + os.path.sep + "src")

src_list = os.listdir(os.curdir)

name_list = []
formula_list = []

# Parse l10n.xml for l10n support
l10n_parser = xml.sax.make_parser()
l10n_handler = l10nhandler.L10NHandler()
l10n_parser.setContentHandler(l10n_handler)
l10n_file = sourceDir + os.path.sep + "xml" + os.path.sep + "l10n.xml"
l10n_parser.parse(l10n_file)

# find the index.xml files in the subdirectories and index the data
for dir in src_list:
  if os.path.isdir(dir) and dir not in skip_dir:
    os.chdir(dir)
    if os.path.isfile("index.xml"):
      index_parser = xml.sax.make_parser()
      index_parser.setFeature(xml.sax.handler.feature_external_ges, 0)
      index_handler = indexhandler.IndexHandler()
      index_parser.setContentHandler(index_handler)
      index_parser.parse("index.xml")
      for entry in index_handler.entryList["file"]:
        name_list.append( (entry.name["en"], "./" + dir +"/" + entry.path) )
        formula_list.append( [(get_formula_ar(entry.path), "./" + dir +"/" + entry.path), entry.name["en"] ])
    os.chdir(os.pardir)
name_list.sort()
formula_list.sort(formulaCmp)
data_index = nameindexwriter.DataIndexWriter("name_index",name_list,l10n_handler)
formula_index = formulaindexwriter.DataIndexWriter("formula_index",formula_list,l10n_handler)

# parse the top index file
index_parser = xml.sax.make_parser()
index_parser.setFeature(xml.sax.handler.feature_external_ges, 0)
index_handler = indexhandler.IndexHandler()
index_parser.setContentHandler(index_handler)
index_parser.parse(indexFile)
index = indexwriter.IndexWriter(indexFile,index_handler,l10n_handler)

for lang in langList:
  data_index.WriteXHTML("Name index", lang)
  formula_index.WriteXHTML("Formula index", lang)
  index = indexwriter.IndexWriter("index_" + lang + ".html",index_handler,l10n_handler)
  index.WriteXHTML(index_handler.title,lang,level)
