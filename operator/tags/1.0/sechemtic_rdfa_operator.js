/* Version 1.0                                                                */
/*                                                                            */
/* Copyright (C) 2007 Egon Willighagen                                        */
/* Released under the GPL v3 license                                          */
/* http://www.gnu.org/copyleft/gpl.html                                       */

var google_inchi = {
  description: "Search with Google",
  shortDescription: "Google",
  scope: {
    semantic: {
      "RDFa" :  {
        property : "http://www.blueobelisk.org/chemistryblogs/inchi",
        defaultNS : "http://www.blueobelisk.org/chemistryblogs/"
      }
    }
  },
  doAction: function(semanticObject, semanticObjectType) {
    if (semanticObjectType == "RDFa") {
      return "http://www.google.com/search?q=" + semanticObject.inchi;
    }
  }
};

var pubchem_inchi = {
  description: "Search in PubChem",
  shortDescription: "PubChem",
  icon: "http://pubchem.ncbi.nlm.nih.gov/favicon.ico",
  scope: {
    semantic: {
      "RDFa" :  {
        property : "http://www.blueobelisk.org/chemistryblogs/inchi",
        defaultNS : "http://www.blueobelisk.org/chemistryblogs/"
      }
    }
  },
  doAction: function(semanticObject, semanticObjectType) {
    if (semanticObjectType == "RDFa") {
      return "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=%22" + semanticObject.inchi + "%22[InChI]";
    }
  }
};

var chemspider_inchi = {
  description: "Search in ChemSpider",
  shortDescription: "ChemSpider",
  icon: "http://www.chemspider.com/favicon.ico",
  scope: {
    semantic: {
      "RDFa" :  {
        property : "http://www.blueobelisk.org/chemistryblogs/inchi",
        defaultNS : "http://www.blueobelisk.org/chemistryblogs/"
      }
    }
  },
  doAction: function(semanticObject, semanticObjectType) {
    if (semanticObjectType == "RDFa") {
      return "http://www.chemspider.com/Search.aspx?q=" + semanticObject.inchi;
    }
  }
};

var pubchem_smiles = {
  description: "Search in PubChem",
  shortDescription: "PubChem",
  icon: "http://pubchem.ncbi.nlm.nih.gov/favicon.ico",
  scope: {
    semantic: {
      "RDFa" :  {
        property : "http://www.blueobelisk.org/chemistryblogs/smiles",
        defaultNS : "http://www.blueobelisk.org/chemistryblogs/"
      }
    }
  },
  doAction: function(semanticObject, semanticObjectType) {
    if (semanticObjectType == "RDFa") {
      return "http://pubchem.ncbi.nlm.nih.gov/search/?smarts=" + semanticObject.smiles;
    }
  }
};

var eMolecules_smiles = {
  description: "Search in eMolecules",
  shortDescription: "eMolecules",
  icon: "http://www.emolecules.com/favicon.ico",
  scope: {
    semantic: {
      "RDFa" :  {
        property : "http://www.blueobelisk.org/chemistryblogs/smiles",
        defaultNS : "http://www.blueobelisk.org/chemistryblogs/"
      }
    }
  },
  doAction: function(semanticObject, semanticObjectType) {
    if (semanticObjectType == "RDFa") {
      return "http://www.emolecules.com/cgi-bin/search?t=ss&q=" + semanticObject.smiles;
    }
  }
};

SemanticActions.add("google_inchi", google_inchi);
SemanticActions.add("chemspider_inchi", chemspider_inchi);
SemanticActions.add("pubchem_inchi", pubchem_inchi);
SemanticActions.add("pubchem_smiles", pubchem_smiles);
SemanticActions.add("eMolecules_smiles", eMolecules_smiles);

