import xml.sax.handler

class CMLHandler(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.id = "" 
    self.formula = ""
    self.inchi = "InChI="
    self.smiles = ""
    self.name = ""
    self.inName = False
    self.weight = ""
    self.inWeight = False
    self.monoisotopic_weight = ""
    self.inMonoisotopicWeight = False
    self.mp = ""
    self.mpSet = False
    self.inMp = False
    self.bp = "" 
    self.inBp = False
    self.bpSet = False

  def startElement(self, name, attributes):
    if name == "molecule":
      self.id = attributes["id"]

    if name == "formula":
      self.formula = attributes["concise"]

    if name == "identifier":
      self.inIdentifier = True
      if attributes["convention"] == "iupac:inchi":
        self.inchi += attributes["value"]

    if name == "name":
      self.inName = True

    if name == "scalar":
      if attributes["dictRef"] == "cml:molwt":
        self.inWeight = True
      if attributes["dictRef"] == "cml:monoisotopicwt":
        self.inMonoisotopicWeight = True
      if attributes["dictRef"] == "cml:mp":
        self.inMp = True
      elif attributes["dictRef"] == "cml:bp":
        self.inBp = True

  def characters(self, data):
    if self.inName:
      self.name += data

    if self.inWeight:
      self.weight += data

    if self.inMonoisotopicWeight:
      self.monoisotopic_weight += data

    if self.inMp:
      self.mp += data

    if self.inBp:
      self.bp += data

  def endElement(self,name):
    if name == "name":
      self.inName = False

    if name == "scalar":
      if self.inWeight:
        self.inWeight = False
      elif self.inMonoisotopicWeight:
        self.inMonoisotopicWeight = False
      elif self.inMp:
        self.inMp = False
        self.mpSet = True
      elif self.inBp:
        self.inBp = False
        self.bpSet = True
