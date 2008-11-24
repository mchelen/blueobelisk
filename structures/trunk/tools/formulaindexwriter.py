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
    size = len(self.data_list)/3
    if len(self.data_list) % 3:
        size += 1
    xhtmlout = xhtmlwriter.XHTMLWriter()
    xhtmlout.setOutput(self.fout + "_" + lang + ".html")
    xhtmlout.setTitle(title)
    xhtmlout.addHead('    <link rel="stylesheet" type="text/css" href="./styles/style.css" />')
    xhtmlout.addHead('    <link rel="shortcut icon" href="./images/favicon.ico" />')
    xhtmlout.addBody('    <div id="header">')
    xhtmlout.addBody('      <img src="./images/header.png" alt="Header image" />')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div id="menu">')
    xhtmlout.addBody('      <div class="path">')
    xhtmlout.addBody('        <a href="./index_' + lang + '.html" title="' + self.l10n.translate('Back to index', lang) + '">' + self.l10n.translate('Back to index', lang) + '</a>')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('      <div class="index">')
    xhtmlout.addBody('        <a href="./name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
    xhtmlout.addBody('        ' + self.l10n.translate('Formula index', lang))
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div id="main">')
    xhtmlout.addBody('      <div id="formula_index">')
    xhtmlout.addBody('        <table class="data">')
    for i in range(0, size):
        xhtmlout.addBody('          <tr>')
        xhtmlout.addBody('            <td><a href="' + self.data_list[i][0][1] + "_" + lang + '.html" title="'+ self.data_list[i][1] +'">' + self.get_formula(self.data_list[i][0][0]) + '</a></td>')
        if (size + i) < len(self.data_list):
            xhtmlout.addBody('            <td><a href="' + self.data_list[size+i][0][1] + "_" + lang + '.html" title="'+ self.data_list[size+i][1] +'">' + self.get_formula(self.data_list[size+i][0][0]) + '</a></td>')
        else: 
            xhtmlout.addBody('            <td></td>')
        if (2*size + i) < len(self.data_list):
            xhtmlout.addBody('            <td><a href="' + self.data_list[2*size+i][0][1] + "_" + lang + '.html" title="'+ self.data_list[2*size+i][1] +'">' + self.get_formula(self.data_list[2*size+i][0][0]) + '</a></td>')
        else:
            xhtmlout.addBody('            <td></td>')
        xhtmlout.addBody('          </tr>')
    xhtmlout.addBody('        </table>')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('    </div>')
    xhtmlout.write()
