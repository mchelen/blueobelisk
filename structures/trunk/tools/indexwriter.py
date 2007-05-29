import xhtmlwriter

class IndexWriter:
  def __init__(self, fout, index_handler, l10n_handler):
    self.fout = fout
    self.index = index_handler
    self.l10n = l10n_handler

  def WriteXHTML(self, index_title, lang, level):	
    xhtmlout = xhtmlwriter.XHTMLWriter()
    xhtmlout.setOutput(self.fout)
    if index_title.has_key(lang):
      xhtmlout.setTitle(index_title[lang])
    else:
      xhtmlout.setTitle(index_title['en'])
    xhtmlout.addHead('    <link href="' + '../' * level + 'styles/style.css" rel="stylesheet" type="text/css" />')
    xhtmlout.addBody('    <div class="header">')
    xhtmlout.addBody('      <img src="'+ '../' * level + 'images/header.png" alt="Header image" />')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div class="navigation">')
    xhtmlout.addBody('      <div class="left">')
    if level > 0:
      xhtmlout.addBody('            <a href="../index_' + lang + '.html">' + self.l10n.translate('Previous', lang) + '</a>')
    else:
      xhtmlout.addBody('            &nbsp;')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('      <div class="right">')
    xhtmlout.addBody('            <a href="' + '../' * level + 'name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
    xhtmlout.addBody('            <a href="' + '../' * level + 'formula_index_' + lang + '.html" title="' + self.l10n.translate('Formula index', lang) + '">' + self.l10n.translate('Formula index', lang) + '</a>')
    xhtmlout.addBody('      </div>')
    xhtmlout.addBody('    </div>')
    xhtmlout.addBody('    <div class="main">')
    xhtmlout.addBody('      <table class="mainLayout">')
    if len(self.index.entryList.dirEntry) > 0:
      xhtmlout.addBody('        <tr>')
      xhtmlout.addBody('          <td>')
      xhtmlout.addBody('            <table class="data">')
      xhtmlout.addBody('              <tr>')
      xhtmlout.addBody('                <th>' + self.l10n.translate("Directories", lang) + '</th>')
      xhtmlout.addBody('                <th>' + self.l10n.translate("Comments", lang) + '</th>')
      xhtmlout.addBody('              </tr>')
      for entry in self.index.entryList.dirEntry:
          xhtmlout.addBody('              <tr>')
          if entry.name.has_key(lang):
            xhtmlout.addBody('                <td><a href="./' + entry.path + '/index_' + lang + '.html">' + entry.name[lang] + '</a></td>')
          else:
            xhtmlout.addBody('                <td><a href="./' + entry.path + '/index_' + lang + '.html">' + entry.name['en'] + ' (<i>en</i>)</a></td>')
          xhtmlout.addBody('                <td></td>')
          xhtmlout.addBody('              </tr>')
      xhtmlout.addBody('            </table>')
      xhtmlout.addBody('          </td>')
      xhtmlout.addBody('        </tr>')
    if len(self.index.entryList.fileEntry) > 0:
      xhtmlout.addBody('        <tr>')
      xhtmlout.addBody('          <td>')
      xhtmlout.addBody('            <table class="data">')
      xhtmlout.addBody('              <tr>')
      xhtmlout.addBody('                <th>' + self.l10n.translate("Names", lang) + '</th>')
      xhtmlout.addBody('                <th>' + self.l10n.translate("Synonyms", lang) + '</th>')
      xhtmlout.addBody('                <th>' + self.l10n.translate("Comments", lang) + '</th>')
      xhtmlout.addBody('              </tr>')
      for entry in self.index.entryList.fileEntry:
          xhtmlout.addBody('              <tr>')
	  if entry.name.has_key(lang):
            xhtmlout.addBody('                <td><a href="./' + entry.path + '_' + lang + '.html">' + entry.name[lang] + '</a></td>')
          else:
            xhtmlout.addBody('                <td><a href="./' + entry.path + '_' + lang + '.html">' + entry.name['en'] + ' (<i>en</i>)</a></td>')
          xhtmlout.addBody('                <td>')
          if len(entry.synDict):
            xhtmlout.addBody('                  <ul>')
            if entry.synDict.has_key(lang):
              for syn in entry.synDict[lang]:
                xhtmlout.addBody('                    <li>' + syn + '</li>')
            elif entry.synDict.has_key('en'):
              for syn in entry.synDict['en']:
                xhtmlout.addBody('                    <li>' + syn + '(<i>en</i>)</li>')
            xhtmlout.addBody('                  </ul>')
          xhtmlout.addBody('                </td>')
          xhtmlout.addBody('                <td></td>')
          xhtmlout.addBody('              </tr>')
      xhtmlout.addBody('            </table>')
      xhtmlout.addBody('          </td>')
      xhtmlout.addBody('        </tr>')
    xhtmlout.addBody('      </table>')
    xhtmlout.addBody('    </div>')
    xhtmlout.write()
