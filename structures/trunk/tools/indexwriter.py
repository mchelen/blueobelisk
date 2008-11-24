import xhtmlwriter

class IndexWriter:
    """Class for creating an index file
    """
    def __init__(self, fout, index_handler, l10n_handler):
        """Creates an instance of the class.
	"""
        self.fout = fout
        self.index = index_handler
        self.l10n = l10n_handler

    def WriteXHTML(self, index_title, lang, level):
        """
	"""
        xhtmlout = xhtmlwriter.XHTMLWriter()
        xhtmlout.setOutput(self.fout)
        if index_title.has_key(lang):
            xhtmlout.setTitle(index_title[lang])
        else:
            xhtmlout.setTitle(index_title['en'])
        xhtmlout.addHead('    <link rel="stylesheet" type="text/css" href="' + '../' * level + 'styles/style.css" />')
        xhtmlout.addHead('    <link rel="shortcut icon" href="' + '../' * level + 'images/favicon.ico" />')
        xhtmlout.addBody('    <div id="header">')
        xhtmlout.addBody('      <img src="'+ '../' * level + 'images/header.png" alt="Header image" />')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div id="menu">')
        xhtmlout.addBody('      <div class="path">')
        if level > 0:
            xhtmlout.addBody('        <a href="../index_' + lang + '.html">' + self.l10n.translate('Previous', lang) + '</a>')
        else:
            xhtmlout.addBody('        &nbsp;')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('      <div class="index">')
        xhtmlout.addBody('        <a href="' + '../' * level + 'name_index_' + lang + '.html" title="' + self.l10n.translate('Name index', lang) + '">' + self.l10n.translate('Name index', lang) + '</a>&nbsp;|&nbsp;')
        xhtmlout.addBody('        <a href="' + '../' * level + 'formula_index_' + lang + '.html" title="' + self.l10n.translate('Formula index', lang) + '">' + self.l10n.translate('Formula index', lang) + '</a>')
        xhtmlout.addBody('      </div>')
        xhtmlout.addBody('    </div>')
        xhtmlout.addBody('    <div id="main">')
	"""
	Create a list of directories
	"""
        if len(self.index.entryList["dir"]) > 0:
            xhtmlout.addBody('      <div id="directories">')
            xhtmlout.addBody('        <h2>'+ self.l10n.translate("Directories", lang) +'</h2>')
            xhtmlout.addBody('        <ul id="directory_list">')
            for entry in self.index.entryList["dir"]:
                if entry.name.has_key(lang):
                    xhtmlout.addBody('          <li><a href="./' + entry.path + '/index_' + lang + '.html">' + entry.name[lang] + '</a></li>')
                else:
                    xhtmlout.addBody('          <li><a href="./' + entry.path + '/index_' + lang + '.html">' + entry.name['en'] + ' (<i>en</i>)</a></li>')
            xhtmlout.addBody('        </ul>')
            xhtmlout.addBody('      </div>')
	"""
	Create list of files
	"""
        if len(self.index.entryList["file"]) > 0:
            xhtmlout.addBody('      <div id="files">')
            xhtmlout.addBody('        <h2>' + self.l10n.translate("Names", lang) + '</h2>')
            xhtmlout.addBody('        <ul id="directory_list">')
            for entry in self.index.entryList["file"]:
                if entry.name.has_key(lang):
                    xhtmlout.addBody('            <li><a href="./' + entry.path + '_' + lang + '.html">' + entry.name[lang] + '</a></li>')
                else:
                    xhtmlout.addBody('            <li><a href="./' + entry.path + '_' + lang + '.html">' + entry.name['en'] + ' (<i>en</i>)</a></li>')
            xhtmlout.addBody('        </ul>')
            xhtmlout.addBody('      </div>')
        xhtmlout.addBody('    </div>')
        xhtmlout.write()
