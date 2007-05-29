import xhtmlwriter

class DataIndexWriter:
  def __init__(self, fout, data_list, l10n_handler):
    self.fout = fout
    self.data_list = data_list
    self.l10n = l10n_handler
  
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
    xhtmlout.addBody('        ' + self.l10n.translate('Name index', lang) + '&nbsp;|&nbsp;')
    xhtmlout.addBody('        <a href="./formula_index_' + lang + '.html" title="' + self.l10n.translate('Formula index', lang) + '">' + self.l10n.translate('Formula index', lang) + '</a>')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div class="main">')
    xhtmlout.addBody('      <table class="mainLayout">')
    xhtmlout.addBody('        <tr>')
    xhtmlout.addBody('          <td>')
    xhtmlout.addBody('            <table>')
    for i in range(0, size):
      xhtmlout.addBody('              <tr>')
      xhtmlout.addBody('                <td><a href="' + self.data_list[i][1] + "_" + lang + '.html">' + self.data_list[i][0] + '</a></td>')
      xhtmlout.addBody('              </tr>')
    xhtmlout.addBody('            </table>')
    xhtmlout.addBody('          </td>')
    xhtmlout.addBody('        </tr>')
    xhtmlout.addBody('      </table>')
    xhtmlout.addBody('    </div>')
    xhtmlout.write()
