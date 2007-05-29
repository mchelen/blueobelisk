import xhtmlwriter

class DataIndexWriter:
  def __init__(self, fout, data_list, l10n_handler):
    self.fout = fout
    self.data_list = data_list
    self.l10n = l10n_handler
  
  def get_formula(self, formula_ar):
    formula = ""
    idx = 0
    subBool = False
    for i in formula_ar:
      if i == "1":
        idx += 1
        continue
      if idx % 2:
        formula += "<sub>" + i
	subBool = True
        idx += 1
      else:
        if subBool:
          formula += "</sub>"
	  subBool = False
        formula += i
        idx += 1
    if subBool:
      formula += "</sub>"
    return formula
  
  def WriteXHTML(self, title, lang):
    size = len(self.data_list)
    xhtmlout = xhtmlwriter.XHTMLWriter()
    xhtmlout.setOutput(self.fout + "_" + lang + ".html")
    xhtmlout.setTitle(title)
    xhtmlout.addHead('    <link href="./styles/style.css" rel="stylesheet" type="text/css" />')
    xhtmlout.addBody('    <div class="header">')
    xhtmlout.addBody('      <img src="./images/header.png" alt="Header image" />')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div class="navigation">')
    xhtmlout.addBody('      <div class="left">')
    xhtmlout.addBody('            <a href="./index_' + lang + '.html" title="' + self.l10n.translate('Back to index', lang) + '">' + self.l10n.translate('Back to index', lang) + '</a>')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('      <div class="right">')
    xhtmlout.addBody('        <a href="./name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
    xhtmlout.addBody('        ' + self.l10n.translate('Formula index', lang))
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div class="main">')
    xhtmlout.addBody('      <table class="mainLayout">')
    xhtmlout.addBody('        <tr>')
    xhtmlout.addBody('          <td>')
    xhtmlout.addBody('            <table>')
    for i in range(0, size):
      xhtmlout.addBody('              <tr>')
      xhtmlout.addBody('                <td><a href="' + self.data_list[i][1] + "_" + lang + '.html">' + self.get_formula(self.data_list[i][0]) + '</a></td>')
      xhtmlout.addBody('              </tr>')
    xhtmlout.addBody('            </table>')
    xhtmlout.addBody('          </td>')
    xhtmlout.addBody('        </tr>')
    xhtmlout.addBody('      </table>')
    xhtmlout.addBody('    </div>')
    xhtmlout.write()
