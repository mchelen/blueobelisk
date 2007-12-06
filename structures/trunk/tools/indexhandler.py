"""Index file handler for Python.

Exported classes:
    Entry - a entry class.
    IndexHandler - Index file handler.
"""

import xml.sax.handler

class Entry:
    """Class for common index entry.

    It contains each feature of an entry element.
    """
    def __init__(self):
        """Creates an instance of the Entry class.

        Set the object attributes with default values.
        """
        self.id = ""
        self.name = {}
        self.path = ""
        self.synDict = {}
        self.abbreviation = []
        self.authors = ""
        self.date = ""

class IndexHandler(xml.sax.handler.ContentHandler):
    """Class for receiving logical Index content events.

    It supports Index entities as defined in the project's DTD.
    For more details, see xml/index.dtd
    """
    def __init__(self):
        """Creates an instance of the IndexHandler class.

        Set the object attributes with default values.
        """
        self.title = {}
        self.titleLang = ""
        self.inTitle = False
        self.entry = None 
        self.entryList = {'dir': [], 'file': []}
        self.inEntry = False
        self.nameLang = ""
        self.inName = False
        self.inDirname = False
        self.inFilename = False
        self.type = None
        self.synonym = ""
        self.synLang = ""
        self.inSynonym = False
        self.abbreviation = ""
        self.inAbbreviation = False
        self.inAuthors = False
        self.inDate = False

    def startElement(self, name, attributes):
        """Signals the start of an element.

        The function set a variable depending on the element and the attribut.

        Parameters:
            name - contains the element name as a string.
            attributes -  contains an instance of the Attributes class.
        """
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

        if name == "abbreviation":
            self.inAbbreviation = True

        if name == "authors":
            self.inAuthors = True

        if name == "date":
            self.inDate = True

    def characters(self, data):
        """Receives notification of character data.

        The parser will call this method to report each chunk of character
        data.

        Parameters:
            data - contains the chunk of character data.
        """
        if self.inTitle:
            self.title[self.titleLang] += data
        elif self.inName:
            self.entry.name[self.nameLang] += data
        elif self.inDirname:
            self.entry.path += data
        elif self.inFilename:
            self.entry.path += data
        elif self.inSynonym:
            self.synonym += data
        elif self.inAbbreviation:
            self.abbreviation += data
        elif self.inAuthors:
            self.entry.authors += data
        elif self.inDate:
            self.entry.date += data

    def endElement(self,name):
        """Signals the end of an element.

        Parameters:
            name - contains the name of the element type.
        """
        if name == "title":
            self.inTitle = False
            self.titleLang = ""

        elif name == "entry":
            if self.type == "file":
                self.entryList["file"].append(self.entry)
            else:
                self.entryList["dir"].append(self.entry)
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

        elif name == "abbreviation":
            self.inAbbreviation = False
            self.entry.abbreviation.append(self.abbreviation)
            self.abbreviation = ""

        elif name == "authors":
            self.inAuthors = False

        elif name == "date":
            self.inDate = False 
