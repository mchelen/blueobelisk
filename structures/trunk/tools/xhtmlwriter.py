import codecs

class XHTMLWriter:
  def __init__(self):
    self.fout = ""
    self.title = ""
    self.stylesheet = ""
    self.head = ""
    self.body = ""
  
  def setOutput(self, fout):
    self.fout = fout

  def setTitle(self, title):
    self.title = title

  def addHead(self, line):
    self.head = self.head + line + "\n"

  def addBody(self, line):
    self.body = self.body + line + "\n"

  def write(self):
    out = codecs.open(self.fout, encoding='utf-8', mode='w')
    out.write('<?xml version="1.0" encoding="UTF-8"?>' + "\n")
    out.write('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' + "\n")
    out.write('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:chem="http://www.blueobelisk.org/chemistryblogs/">' + "\n")
    out.write('  <head>' + "\n")
    out.write('    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />' + "\n")
    out.write('    <title>'+self.title+'</title>' + "\n")
    out.write(self.head)
    out.write('  </head>' + "\n")
    out.write('  <body>' + "\n")
    out.write(self.body)
    out.write('  </body>' + "\n")
    out.write('</html>')
    out.close()
