"""CML file handler for Python.

This module provides an xml handler for CML file.

Exported classes:
    CMLHandler - CML file handler.
""" 

import sys
import xml.sax.handler

class CMLHandler(xml.sax.handler.ContentHandler):
    """Class for receiving logical CML content events.
  
    It supports CML entities as defined by the 2.0 version. For more details,
    see http://www.xml-cml.org/

    The order of event in this class mirrors the order of the information in
    the document.
    """
    def __init__(self):
        """Creates an instance of the CMLHandler class.

        Set the object attributes with default values.
        """
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
        """Signals the start of an element.

        The function set a variable depending on the element and the
        attributes.

        Parameters:
            name - contains the raw CML name of the element type as a string.
            attributes - contains an instance of the Attributes class.
        """
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
            elif attributes["dictRef"] == "cml:monoisotopicwt":
                self.inMonoisotopicWeight = True
            elif attributes["dictRef"] == "cml:mp":
                self.inMp = True
            elif attributes["dictRef"] == "cml:bp":
                self.inBp = True

    def characters(self, data):
        """Receives notification of character data.
        
        The parser will call this method to report each chunk of character
        data.

        Parameters:
            data - contains the chunk of character data.
        """
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
        """Signals the end of an element.

        Parameters:
            name - contains the name of the element type.
        """
        if name == "name":
            self.inName = False

        if name == "scalar":
            if self.inWeight:
                self.inWeight = False
            elif self.inMonoisotopicWeight:
                self.inMonoisotopicWeight = False
            elif self.inMp:
                self.inMp = False
                self.mp = self.mp.strip()
                if self.mp:
                    self.mpSet = True
            elif self.inBp:
                self.inBp = False
                self.bp = self.bp.strip()
                if self.bp:
                    self.bpSet = True

