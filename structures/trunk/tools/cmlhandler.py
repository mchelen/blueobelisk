import xml.sax.handler

class CMLHandler(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.id = "" 
    self.formula = ""
    self.inIdentifier = False
    self.inchi = "InChI="
    self.smiles = ""
    self.inInChI = False
    self.inBasic = False
    self.name = ""
    self.inName = False
    self.weight = ""
    self.inWeight = False
    self.exact_weight = ""
    self.inExactWeight = False
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

    if name == "identifier":
      self.inIdentifier = True
      if attributes.has_key("version") and attributes["version"] == "InChI/1":
        self.inInChI = True

    if name == "basic":
      self.inBasic = True

    if name == "name":
      self.inName = True

    if name == "scalar":
      if attributes["dictRef"] == "cml:molwt":
        self.inWeight = True
      if attributes["dictRef"] == "chemwt:exact_molwt":
        self.inExactWeight = True
      if attributes["dictRef"] == "cml:mpt":
        self.inMpt = True
      elif attributes["dictRef"] == "cml:bpt":
        self.inBpt = True

  def characters(self, data):
    if self.inName:
      self.name += data

    if self.inWeight:
      self.weight += data

    if self.inExactWeight:
      self.exact_weight += data

    if self.inMpt:
      self.mpt += data

    if self.inBpt:
      self.bpt += data

    if self.inBasic and self.inInChI:
      self.inchi += data

  def endElement(self,name):
    if name == "identifier":
      self.Idenfitier = False

    if name == "basic":
      self.inBasic = False
      if self.inInChI:
        self.inInChI = False

    if name == "name":
      self.inName = False

    if name == "inchi":
      self.inInChI = False

    if name == "scalar":
      if self.inWeight:
        self.inWeight = False
      elif self.inExactWeight:
        self.inExactWeight = False
      elif self.inMpt:
        self.inMpt = False
        self.mptSet = True
      elif self.inBpt:
        self.inBpt = False
        self.bptSet = True
