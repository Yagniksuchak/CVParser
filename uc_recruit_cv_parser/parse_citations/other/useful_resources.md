
Potential Work flow:
-------------------
1. Input CV as pdf
2. Determine if pdf contains text or an image
3. Pass text CV to PDFMiner to extract XML 
4. Parse XML to extract list of citations
5. Pass each citation to anystyle-parser (or FreeCite)
6. Extract doi, arXiv, or year if available
7a. If doi or arXiv found, then we've likely found the exact article, otherwise
7b. Query rcrossref (and/or aRxiv), cross-checking results with article title, and retain scores.
8 [optional]. Search for google scholar profile


Useful R APIs:
-------------
rcrossref
fulltext
rplos
aRxiv
rentrez

latest XML package:
-------------------
http://www.omegahat.org/R/src/contrib/

python PDF parsers:
------------------
PDFMiner - Best option
PDFQuery - is a light wrapper around pdfminer
pyPDF - fewer features than pdfminer


citation parsers:
----------------
anystyle-parser - https://github.com/inukshuk/anystyle-parser or http://anystyle.io/ [offline and works well]
FreeCite - http://freecite.library.brown.edu/ [online, works okay but not as well as anystyle]
CrossRef's DOI retriever - http://search.labs.crossref.org/dois [better to use R API, rcrossref]


Potentially useful:
------------------
* fulltext - https://github.com/ropensci/fulltext 
* rOpenSci - https://ropensci.org/packages/ 
* google_scholar_parser - https://github.com/carlosp420/google_scholar_parser [Scripts to parse "citations page" of Google Scholar and get citation counts for a publication using its DOI]
* cv-parser - https://github.com/total-impact/cv-parser [potentially useful python code for parsing a CV and looking for publications, uses an outdated version of pdfminer and no longer works]
* pdfssa4met - https://code.google.com/p/pdfssa4met/ [python code with similar strategy to ours]
* download latest XML package from: http://www.omegahat.org/R/src/contrib/


Not useful:
----------
* CitationParsing - https://github.com/copystar/CitationParsing [Not useful]
* citation_parser - https://github.com/RudolfVonKrugstein/citation_parser [passes citation to "http://search.labs.crossref.org/dois" to return correct citations with scores - similar approach to ours]
* cv - https://github.com/pallavagarwal07/cv [Not useful - CV parsing and automated data extraction]
* reftagger - https://github.com/rmcgibbo/reftagger [Doesn't work well - Parse and tag unstructured academic citations]

