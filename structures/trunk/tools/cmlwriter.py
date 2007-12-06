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
        xhtmlout.addHead('    <link href="' + '../' * level + 'styles/style.css" rel="stylesheet" type="text/css" />')
        xhtmlout.addBody('    <div class="header">')
        xhtmlout.addBody('      <img src="'+ '../' * level + 'images/header.png" alt="Header image" />')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div class="navigation">')
        xhtmlout.addBody('      <div class="left">')
        xhtmlout.addBody('            <a href="./index_' + lang + '.html" title="' + self.l10n.translate('Back to index', lang) + '">' + self.l10n.translate('Back to index', lang) + '</a>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('      <div class="right">')
        xhtmlout.addBody('            <a href="' + '../' * level + 'name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
        xhtmlout.addBody('            <a href="' + '../' * level + 'formula_index_' + lang + '.html" title="' + self.l10n.translate('Formula index', lang) + '">' + self.l10n.translate('Formula index', lang) + '</a>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div class="main">')
        xhtmlout.addBody('      <table class="mainLayout">')
        xhtmlout.addBody('        <tr>')
        xhtmlout.addBody('          <td colspan="2">')
        xhtmlout.addBody('            <table class="data">')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <th>' + self.l10n.translate('Properties', lang) + '</th>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <td>')
        xhtmlout.addBody('                  <ul>')
        xhtmlout.addBody('                    <li>' + self.l10n.translate('IUPAC name: ', lang) + self.cml.name + '</li>')
        xhtmlout.addBody('                    <li>' + self.l10n.translate('Formula: ', lang) + self.parseFormula(self.cml.formula) + '</li>')
        xhtmlout.addBody('                    <li>' + self.l10n.translate('Molecular weight: ', lang) + self.cml.weight + ' g/mol</li>')
        xhtmlout.addBody('                    <li>' + self.l10n.translate('Monoisotopic Weight: ', lang) + self.cml.monoisotopic_weight + ' g/mol</li>')
        if self.cml.mpSet:
          if self.cml.mp.count(">"):
            mp = self.cml.mp.replace(">","").strip()
            mpK = str(int(mp) + 273)
          else:
            mpK = str(int(self.cml.mp) + 273)
          xhtmlout.addBody('                    <li>' + self.l10n.translate('Melting point: ', lang) + self.cml.mp + ' &deg;C ('+ mpK + ' K)</li>')
        if self.cml.bpSet:
          if self.cml.bp.count(">"):
            bp = self.cml.bp.replace(">","").strip()
            bpK = str(int(bp) + 273)
          else:
            bpK = str(int(self.cml.bp) + 273)
          xhtmlout.addBody('                    <li>' + self.l10n.translate('Boiling point: ', lang) + self.cml.bp  + ' &deg;C (' + bpK + ' K)</li>')
        if entry_details.synDict.has_key('en') or entry_details.synDict.has_key(lang):
          xhtmlout.addBody('                    <li>' + self.l10n.translate('Synonyms:', lang) )
          xhtmlout.addBody('                      <ul>')
          if entry_details.synDict.has_key(lang):
            for synonym in entry_details.synDict[lang]:
              xhtmlout.addBody('                      <li>' + synonym + '</li>')
          elif entry_details.synDict.has_key('en'):
            for synonym in entry_details.synDict['en']:
              xhtmlout.addBody('                      <li>' + synonym + ' (<i>en</i>)</li>')
          xhtmlout.addBody('                      </ul>')
          xhtmlout.addBody('                    </li>')
        xhtmlout.addBody('                  </ul>')
        xhtmlout.addBody('                </td>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('            </table>')
        xhtmlout.addBody('          </td>')
        xhtmlout.addBody('        </tr>')
        xhtmlout.addBody('        <tr>')
        xhtmlout.addBody('          <td id="structure">')
        xhtmlout.addBody('            <table class="data">')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <th>' + self.l10n.translate('Structure', lang) + '</th>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <td>')
        xhtmlout.addBody('                  <script type="text/javascript">')
        xhtmlout.addBody('                    jmolInitialize("' + '../' * level + 'jmol", window.location.protocol == "file:");')
        xhtmlout.addBody('                    jmolApplet(300, "load ' + cml_file + '");')
        xhtmlout.addBody('                  </script>')
        xhtmlout.addBody('                </td>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('            </table>')
        xhtmlout.addBody('          </td>')
        xhtmlout.addBody('          <td>')
        xhtmlout.addBody('            <table class="data">')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <th>' + self.l10n.translate('Structure Download', lang) + '</th>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <td>')
        xhtmlout.addBody('                  <ul>')
        xhtmlout.addBody('                    <li>' + self.l10n.translate('In CML format', lang) + '&nbsp;<a href="' + cml_file + '" title="CML"><img src="' + '../'*level + 'images/download.png" alt="Download cml file" /></a></li>')
        if os.path.isfile(mol_file):
          xhtmlout.addBody('                    <li>' + self.l10n.translate('In MOL format', lang) + '&nbsp;<a href="' + mol_file + '" title="MOL"><img src="' + '../'*level + 'images/download.png" alt="Download mol file" /></a></li>')
        xhtmlout.addBody('                  </ul>')
        xhtmlout.addBody('                </td>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('            </table>')
        xhtmlout.addBody('          </td>')
        xhtmlout.addBody('        </tr>')
        xhtmlout.addBody('        <tr>')
        xhtmlout.addBody('          <td colspan="2">')
        xhtmlout.addBody('            <table class="data">')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <th>InChI</th>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('              <tr>')
        xhtmlout.addBody('                <td><div about="http://chem-file.sourceforge.net/data/cml/'+ cml_file +'"><span property="chem:inchi">' + self.cml.inchi + '</span></div></td>')
        xhtmlout.addBody('              </tr>')
        xhtmlout.addBody('            </table>')
        xhtmlout.addBody('          </td>')
        xhtmlout.addBody('        </tr>')
        if smiles:
          xhtmlout.addBody('        <tr>')
          xhtmlout.addBody('          <td colspan="2">')
          xhtmlout.addBody('            <table class="data">')
          xhtmlout.addBody('              <tr>')
          xhtmlout.addBody('                <th>SMILES</th>')
          xhtmlout.addBody('              </tr>')
          xhtmlout.addBody('              <tr>')
          xhtmlout.addBody('                <td><div about="http://chem-file.sourceforge.net/data/cml/'+ cml_file +'"><span property="chem:smiles">' + smiles + '</span></div></td>')
          xhtmlout.addBody('              </tr>')
          xhtmlout.addBody('            </table>')
          xhtmlout.addBody('          </td>')
          xhtmlout.addBody('        </tr>')
        xhtmlout.addBody('      </table>')
        xhtmlout.addBody('    </div>')
        xhtmlout.write()
