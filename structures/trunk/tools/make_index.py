#!/usr/bin/python

"""This file generates the following index files:
- src/name_index.html
- src/raw_formula.html
"""

import sys
import os
import xml.sax
import l10nhandler
import indexhandler
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

langList = sys.argv[2:]

skip_dir = ['jmol','images','styles']

os.chdir(sourceDir)

src_list = os.listdir(os.curdir)

name_list = []
formula_list = []

# Parse l10n.xml for l10n support
l10n_parser = xml.sax.make_parser()
l10n_handler = l10nhandler.L10NHandler()
l10n_parser.setContentHandler(l10n_handler)
l10n_parser.parse(os.pardir + "/xml/l10n.xml")

for dir in src_list:
  if os.path.isdir(dir) and dir not in skip_dir:
    os.chdir(dir)
    if os.path.isfile("index.xml"):
      index_parser = xml.sax.make_parser()
      index_parser.setFeature(xml.sax.handler.feature_external_ges, 0)
      index_handler = indexhandler.IndexHandler()
      index_parser.setContentHandler(index_handler)
      index_parser.parse("index.xml")
      for entry in index_handler.entryList.fileEntry:
        name_list.append( (entry.name["en"], "./" + dir +"/" + entry.path) )
        formula_list.append( [(get_formula_ar(entry.path), "./" + dir +"/" + entry.path), entry.name["en"] ])
    os.chdir(os.pardir)

name_list.sort()
formula_list.sort(formulaCmp)

data_index = nameindexwriter.DataIndexWriter("name_index",name_list,l10n_handler)
formula_index = formulaindexwriter.DataIndexWriter("formula_index",formula_list,l10n_handler)

for lang in langList:
  data_index.WriteXHTML("Name index", lang)
  formula_index.WriteXHTML("Formula index", lang)
