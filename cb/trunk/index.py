#!/usr/bin/env python

import sys, os, re, glob
from PyLucene import *

stopwords = ["a", "about", "again", "all", "almost", "also", "although", "always", "among", "an", "and", "another", "any", "are", "as", "at", "be", "because", "been", "before", "being", "between", "both", "but", "by", "can", "could", "did", "do", "does", "done", "due", "during", "each", "either", "enough", "especially", "etc", "for", "found", "from", "further", "had", "has", "have", "having", "here", "how", "however", "i", "if", "in", "into", "is", "it", "its", "itself", "just", "kg", "km", "made", "mainly", "make", "may", "mg", "might", "ml", "mm", "most", "mostly", "must", "nearly", "neither", "no", "nor", "obtained", "of", "often", "on", "our", "overall", "perhaps", "quite", "rather", "really", "regarding", "seem", "seen", "several", "should", "show", "showed", "shown", "shows", "since", "so", "some", "such", "than", "that", "the", "their", "theirs", "them", "then", "there", "therefore", "these", "they", "this", "those", "through", "thus", "to", "upon", "use", "used", "using", "various", "very", "was", "we", "were", "what", "when", "which", "while", "with", "within", "without", "would", "cdata"]

### Indexer
startNew = False # True to start a new index

feedFiles = "posts/*"
paperFiles = "papers/*"

reindex = 0

indexDir = "lucene_posts_index"

numdocs = 0
try:
	indexreader = IndexReader.open(indexDir)
	numdocs = indexreader.numDocs()
except:
	numdocs = 0

if numdocs:
	startNew = False
else:
	startNew = True

if reindex:
	startNew = 1

filestore = FSDirectory.getDirectory(indexDir, startNew)
analyzer = StandardAnalyzer(stopwords)
filewriter = IndexWriter(filestore, analyzer, startNew)

filewriter.setMergeFactor(100)
filewriter.setMaxMergeDocs(10000)
filewriter.setMaxBufferedDocs(5000)

m = re.compile('<post>')
i = re.compile('<(?:feed|paper)_id>(.*?)</(?:feed|paper)_id>')
t = re.compile('<title>(.*?)</title>')
d = re.compile('<date>(.*?)</date>')
de = re.compile('<description>(.*?)</description>', re.S)

def parse(dir):    
	for f in glob.glob(dir):  
		if os.path.isdir(f):
			parse(f + "/*")
			continue 
    		
		# if id f is already in the index, skip it unless reindex is true
		fterm = Term("id", f)
		# print "Checking term " + fterm.text()
		if indexreader.docFreq(fterm):
			# print "Already in index"
			continue		

		file = open(f)
    		contents = unicode(file.read(), 'utf-8')
    		file.close()
            
    		for article in m.split(contents):
			id = re.search(i, article)
        		if id:
            			title = re.search(t, article)
            			if title:
                			doc = Document()
					id = f
                			doc.add(Field('id', id, Field.Store.YES, Field.Index.UN_TOKENIZED))
                			doc.add(Field('title', title.group(1), Field.Store.YES, Field.Index.TOKENIZED))
                			description = re.search(de, article)
                			if description:
                    				doc.add(Field('description', description.group(1), Field.Store.YES, Field.Index.TOKENIZED, Field.TermVector.YES))
                			date = re.search(d, article)
                			if date:
                    				doc.add(Field('date', date.group(1), Field.Store.YES, Field.Index.UN_TOKENIZED))
                			
					print title.group(1)
					filewriter.addDocument(doc)
					#sys.exit(0)
    
# parse posts and blogs first
parse(feedFiles)

# then papers
parse(paperFiles)

filewriter.optimize()
filewriter.close()

print 'optimizing index'
filewriter.optimize()
filewriter.close()
print 'done'
                            


