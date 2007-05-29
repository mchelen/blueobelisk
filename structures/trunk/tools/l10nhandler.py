import xml.sax.handler

class L10NHandler(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.msgDict = {}
    self.msgid = ""
    self.inMsgid = False
    self.msg = ""
    self.msgLang =""
    self.inMsg = False

  def startElement(self, name, attributes):
    if name == "msgid":
      self.inMsgid = True

    if name == "msg":
      if attributes.has_key('xml:lang'):
        self.msgLang = unicode.encode(attributes["xml:lang"])
      else:
        self.msgLang = "en"
      self.inMsg = True

  def characters(self, data):
    if self.inMsgid:
      self.msgid += data

    if self.inMsg:
      self.msg += data

  def endElement(self,name):
    if name == "msgid":
      self.inMsgid = False
      self.msgDict[self.msgid] = {}

    if name == "msg":
      self.inMsg = False
      self.msgDict[self.msgid][self.msgLang] = self.msg
      self.msgLang = ""
      self.msg = ""

    if name == "msgset":
      self.msgid = ""

  def translate(self, msgid, lang):
    if self.msgDict.has_key(msgid) and self.msgDict[msgid].has_key(lang):
      return self.msgDict[msgid][lang]
    else:
      return msgid
