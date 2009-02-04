"""CML2XHTML converter for Python

This module provides a convenient way to transform CML to XHTML.

Exported classes:
    CMLWriter - Write a XHTML file with the content of a CML file
"""
import xhtmlwriter
import os

class CMLWriter:
    """
    """
    def __init__(self, fout, cml_handler, l10n_handler):
        """Creates an instance of the CMLWriter class.
	"""
        self.fout = fout
        self.cml = cml_handler
        self.l10n = l10n_handler

    def parseFormula(self, raw_formula):
        """Parse formula and return the HTML formula
	"""
        formula = raw_formula.strip()
        formula_ar = formula.split(" ")
        formula = ""
        idx = 0
        subBool = False
        for i in formula_ar:
            if i == "1":
                idx += 1
            elif idx % 2: # we are in the multiple section"
                formula += "<sub>" + i + "</sub>"
		idx += 1
            else: # we are in the element section
                formula += i
                idx += 1
        return formula

    def WriteXHTML(self, entry_details, lang, level):
        if entry_details.name.has_key(lang):
            title = entry_details.name[lang]
        else:
            title = entry_details.name['en']

        cml_file = entry_details.path + '.cml'
        mol_file = entry_details.path + '.mol'
        smi_file = entry_details.path + '.smi'
        smiles =  ""
        if os.path.isfile(smi_file):
            smiles_fin = open(smi_file,'r')
            smiles = smiles_fin.readline()
            idx = smiles.find("\t")
            smiles = smiles[:idx]
            smiles_fin.close()
        xhtmlout = xhtmlwriter.XHTMLWriter()
        xhtmlout.setOutput(self.fout)
        xhtmlout.setTitle(title)
        xhtmlout.addHead('    <script src="' + '../' * level + 'jmol/Jmol.js" type="text/javascript"></script>')
        xhtmlout.addHead('    <link rel="stylesheet" type="text/css" href="' + '../' * level + 'styles/style.css" />')
        xhtmlout.addHead('    <link rel="shortcut icon" href="' + '../' * level + 'images/favicon.ico" />')
        xhtmlout.addBody('    <div id="header">')
        xhtmlout.addBody('      <img src="'+ '../' * level + 'images/header.png" alt="Header image" />')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div id="menu">')
        xhtmlout.addBody('      <div class="path">')
        xhtmlout.addBody('        <a href="./index_' + lang + '.html" title="' + self.l10n.translate('Back to index', lang) + '">' + self.l10n.translate('Back to index', lang) + '</a>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('      <div class="index">')
        xhtmlout.addBody('        <a href="' + '../' * level + 'name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
        xhtmlout.addBody('        <a href="' + '../' * level + 'formula_index_' + lang + '.html" title="' + self.l10n.translate('Formula index', lang) + '">' + self.l10n.translate('Formula index', lang) + '</a>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div id="main">')
        xhtmlout.addBody('      <div id="molecule">')
        xhtmlout.addBody('        <div id="properties">')
        xhtmlout.addBody('          <h3>' + self.l10n.translate('Properties', lang) + '</h3>')
        xhtmlout.addBody('          <ul>')
        xhtmlout.addBody('            <li>' + self.l10n.translate('IUPAC name: ', lang) + self.cml.name + '</li>')
        xhtmlout.addBody('            <li>' + self.l10n.translate('Formula: ', lang) + self.parseFormula(self.cml.formula) + '</li>')
        xhtmlout.addBody('            <li>' + self.l10n.translate('Molecular weight: ', lang) + self.cml.weight + ' g/mol</li>')
        xhtmlout.addBody('            <li>' + self.l10n.translate('Monoisotopic weight: ', lang) + self.cml.monoisotopic_weight + ' g/mol</li>')
        if self.cml.mpSet:
            if self.cml.mp.count(">"):
                mp = self.cml.mp.replace(">","").strip()
                mpK = str(int(mp) + 273)
            else:
                mpK = str(int(self.cml.mp) + 273)
            xhtmlout.addBody('            <li>' + self.l10n.translate('Melting point: ', lang) + self.cml.mp + ' &deg;C ('+ mpK + ' K)</li>')
        if self.cml.bpSet:
            if self.cml.bp.count(">"):
                bp = self.cml.bp.replace(">","").strip()
                bpK = str(int(bp) + 273)
            else:
                bpK = str(int(self.cml.bp) + 273)
            xhtmlout.addBody('            <li>' + self.l10n.translate('Boiling point: ', lang) + self.cml.bp  + ' &deg;C (' + bpK + ' K)</li>')
	#########################################################
	# Writing synonyms
	#
	# Write only if synonyms (localized or english) are
	# available
	#########################################################
	if entry_details.synDict.has_key(lang):
	    if len(entry_details.synDict[lang]) == 1:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Synonym:', lang) )
	    else:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Synonyms:', lang) )
            xhtmlout.addBody('              <ul>')
            for synonym in entry_details.synDict[lang]:
                xhtmlout.addBody('                <li>' + synonym + '</li>')
            xhtmlout.addBody('              </ul>')
            xhtmlout.addBody('            </li>')
	elif entry_details.synDict.has_key('en'):
	    if len(entry_details.synDict['en']) == 1:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Synonym:', lang) )
	    else:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Synonyms:', lang) )
            xhtmlout.addBody('              <ul>')
            for synonym in entry_details.synDict['en']:
                xhtmlout.addBody('                <li>' + synonym + ' (<i>en</i>)</li>')
            xhtmlout.addBody('              </ul>')
            xhtmlout.addBody('            </li>')
	#########################################################
	# Writing abbreviations 
	#
	# Write only if abbreviations are available
	#########################################################
	if len(entry_details.abbreviation):
	    if len(entry_details.abbreviation) == 1:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Abbreviation:', lang) )
	    else:
                xhtmlout.addBody('            <li>' + self.l10n.translate('Abbreviations:', lang) )
            xhtmlout.addBody('              <ul>')
            for abbreviation in entry_details.abbreviation:
                xhtmlout.addBody('                <li>' + abbreviation + '</li>')
            xhtmlout.addBody('              </ul>')
            xhtmlout.addBody('            </li>')
        xhtmlout.addBody('          </ul>')
        xhtmlout.addBody('        </div>')
        xhtmlout.addBody('        <div id="structure">')
        xhtmlout.addBody('          <h3>' + self.l10n.translate('Structure', lang) + '</h3>')
        xhtmlout.addBody('          <script type="text/javascript">')
        xhtmlout.addBody('            jmolInitialize("' + '../' * level + 'jmol", window.location.protocol == "file:");')
        xhtmlout.addBody('            jmolSetAppletColor("white");')
        xhtmlout.addBody('            jmolApplet(300, "load ' + cml_file + '");')
        xhtmlout.addBody('          </script>')
        xhtmlout.addBody('        </div>')
        xhtmlout.addBody('        <div id="download">')
        xhtmlout.addBody('          <h3>' + self.l10n.translate('Structure Download', lang) + '</h3>')
        xhtmlout.addBody('          <ul>')
        xhtmlout.addBody('            <li>' + self.l10n.translate('In CML format', lang) + '&nbsp;<a href="' + cml_file + '" title="CML"><img src="' + '../'*level + 'images/download.png" alt="Download cml file" /></a></li>')
        if os.path.isfile(mol_file):
            xhtmlout.addBody('            <li>' + self.l10n.translate('In MOL format', lang) + '&nbsp;<a href="' + mol_file + '" title="MOL"><img src="' + '../'*level + 'images/download.png" alt="Download mol file" /></a></li>')
        xhtmlout.addBody('          </ul>')
        xhtmlout.addBody('        </div>')
        xhtmlout.addBody('        <div id="inchi">')
        xhtmlout.addBody('          <h3>' + self.l10n.translate('InChI', lang) + '</h3>')
	if len(self.cml.inchi) > 80:
	    htmlinchi = ""
	    size = int(len(self.cml.inchi)/80)
	    for i in range(0,size):
	        htmlinchi += self.cml.inchi[i*80:(i+1)*80] + "<br />\n"
            htmlinchi += self.cml.inchi[size*80:len(self.cml.inchi)]
	else:
	    htmlinchi = self.cml.inchi
        xhtmlout.addBody('          <span class="inchi">' + htmlinchi + '</span>')
        xhtmlout.addBody('        </div>')
        if smiles:
            xhtmlout.addBody('        <div id="smiles">')
            xhtmlout.addBody('          <h3>' +  self.l10n.translate('SMILES', lang) + '</h3>')
            if len(smiles) > 80:
	        htmlsmiles = ""
  	        size = int(len(smiles)/80)
 	        for i in range(0,size):
	            htmlsmiles += smiles[i*80:(i+1)*80] + "<br />\n"
                htmlsmiles += smiles[size*80:len(smiles)]
            else:
	        htmlsmiles = smiles
            xhtmlout.addBody('          <span class="smiles">' + htmlsmiles + '</span>')
            xhtmlout.addBody('        </div>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('    </div>')
        xhtmlout.write()
