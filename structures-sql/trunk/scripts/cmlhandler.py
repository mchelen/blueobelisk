import xml.sax.handler

class CMLHandler(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.id = 0
    self.formula = ""
    self.inchi = ""
    self.inInChI = False
    self.name = ""
    self.inName = False
    self.mpt = ""
    self.mptSet = False
    self.inMpt = False
    self.bpt = "" 
    self.inBpt = False
    self.bptSet = False

  def startElement(self, name, attributes):
    if name == "molecule":
      self.id = attributes["id"]

    if name == "formula":
      self.formula = attributes["concise"]

    if name == "name":
      self.inName = True

    if name == "scalar" and attributes["dictRef"] == "cml:mpt":
      self.inMpt = True

    if name == "scalar" and attributes["dictRef"] == "cml:bpt":
      self.inBpt = True

  def characters(self, data):
    if self.inName:
      self.name += data
    if self.inMpt:
      self.mpt += data
    if self.inBpt:
      self.bpt += data

  def endElement(self,name):
    if name == "name":
      self.inName = False

    if name == "scalar" and self.inMpt:
      self.inMpt = False
      self.mptSet = True

    if name == "scalar" and self.inBpt:
      self.inBpt = False
      self.bptSet = True
