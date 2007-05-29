import xml.sax.handler

class EntryList:
  def __init__(self):
    self.fileEntry = []
    self.dirEntry = []
 
class Entry:
  def __init__(self):
    self.id = ""
    self.name = {}
    self.path = ""
    self.synDict = {}
    self.authors = ""
    self.date = ""

class IndexHandler(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.title = {}
    self.titleLang = ""
    self.inTitle = False
    self.entry = None 
    self.entryList = EntryList() 
    self.inEntry = False
    self.nameLang = ""
    self.inName = False
    self.inDirname = False
    self.inFilename = False
    self.type = None
    self.synonym = ""
    self.synLang = ""
    self.inSynonym = False
    self.inAuthors = False
    self.inDate = False

  def startElement(self, name, attributes):
    if name == "title":
      self.inTitle = True
      if attributes.has_key("xml:lang"):
        self.titleLang = unicode.encode(attributes["xml:lang"])
        if self.titleLang == "":
          self.titleLang = "en"
      else:
        self.titleLang = "en"
      self.title[self.titleLang] = ""

    if name == "entry":
      self.inEntry = True
      self.entry = Entry()

    if name == "name":
      self.inName = True
      if attributes.has_key("xml:lang"):
        self.nameLang = unicode.encode(attributes["xml:lang"])
        if self.nameLang == "":
          self.nameLang = "en"
      else:
        self.nameLang = "en"
      self.entry.name[self.nameLang] = ""

    if name == "dirname":
      self.inDirname = True
      self.type = "dir"

    if name == "filename":
      self.inFilename = True
      self.type = "file"

    if name == "synonym":
      self.inSynonym = True
      if attributes.has_key("xml:lang"):
        self.synLang = unicode.encode(attributes["xml:lang"])
        if self.synLang == "":
          self.synLang = "en"
      else:
        self.synLang ="en"
      if not self.entry.synDict.has_key(self.synLang):
        self.entry.synDict[self.synLang] = []

    if name == "authors":
      self.inAuthors = True

    if name == "date":
      self.inDate = True

  def characters(self, data):
    if self.inTitle:
      self.title[self.titleLang] += data
    if self.inName:
      self.entry.name[self.nameLang] += data
    if self.inDirname:
      self.entry.path += data
    if self.inFilename:
      self.entry.path += data
    if self.inSynonym:
      self.synonym += data
    if self.inAuthors:
      self.entry.authors += data
    if self.inDate:
      self.entry.date += data

  def endElement(self,name):
    if name == "title":
      self.inTitle = False
      self.titleLang = ""

    elif name == "entry":
      if self.type == "file":
        self.entryList.fileEntry.append(self.entry)
      else:
        self.entryList.dirEntry.append(self.entry)
      self.entry = None
      self.inEntry = False 

    elif name == "name":
      self.inName = False
      self.nameLang = ""

    elif name == "dirname":
      self.inDirname = False

    elif name == "filename":
      self.inFilename = False

    elif name == "synonym":
      try:
        self.entry.synDict[self.synLang].append(self.synonym)
      except:
        print self.synLang
	print self.entry.synDict
      self.synonym = ""
      self.inSynonym = False
      self.synLang = ""

    elif name == "authors":
      self.inAuthors = False

    elif name == "date":
      self.inDate = False 
