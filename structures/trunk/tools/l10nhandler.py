"""L10N file handler for Python.

Exported classes:
    - L10NHandler
        L10N file handler
"""

import xml.sax.handler

class L10NHandler(xml.sax.handler.ContentHandler):
    """Class for receiving logical L10N content events.

    It supports L10N entities as defined in the by the 2.0 version.
    For more details, see http://www.xml-cml.org/

    The order of event in this class mirrors the order of the information in
    the document.
    """
    def __init__(self):
        """Creates an instance of the L10NHandler class.

        Set the object attributes with default values.
"""
        self.msgDict = {}
        self.msgid = ""
        self.inMsgid = False
        self.msg = ""
        self.msgLang =""
        self.inMsg = False

    def startElement(self, name, attributes):
        """Signals the start of an element in non-namespace mode.

        Set some variables depending the element and the attribut

        Param:
            - name
                contains the raw CML name of the element type as a string
            - attributes
                contains an instance of the Attributes class
                containing the attributes of the elements.
        """
        if name == "msgid":
            self.inMsgid = True

        if name == "msg":
            if attributes.has_key('xml:lang'):
                self.msgLang = unicode.encode(attributes["xml:lang"])
            else:
                self.msgLang = "en"
            self.inMsg = True
       
    def characters(self, data):
        """Receives notification of character data.

        The Parse will call this method to report each chunk of character data.

        Param:
            - data
                contains the chunk of character data.
        """
        if self.inMsgid:
            self.msgid += data

        if self.inMsg:
            self.msg += data

    def endElement(self,name):
        """Signals the end of an element in non-namespace mode.

        Param:
            - name
                contains the name of the element type.

        """
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
        """Translates a string

	Param:
	    - msgid
                contains the msgid to translate
	    - lang
	        contains the destination language
	
	Return:
	    - the translated string if the translation is available
	    - the msgid in other cases
        """
        if self.msgDict.has_key(msgid) and self.msgDict[msgid].has_key(lang):
            return self.msgDict[msgid][lang]
        else:
            return msgid
