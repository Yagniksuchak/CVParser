search "cv parser" on github

cv-parser: https://github.com/total-impact/cv-parser - might be interested, uses an outdated version of pdfminer and no longer work, portions of code may be useful

https://github.com/copystar/CitationParsing - NO
https://github.com/RudolfVonKrugstein/citation_parser - Parser for citations, searching them online and printing them corrected - Uses "http://search.labs.crossref.org/dois", may have useful regular expressions
https://github.com/carlosp420/google_scholar_parser - Scripts to parse "citations page" of Google Scholar - Get citations for a publication using its DOI.

https://github.com/pallavagarwal07/cv - CV parsing and automated data extraction - NO
https://github.com/rmcgibbo/reftagger - Parse and tag unstructured academic citations - Doesn't work well


Also explore:

pdfminer 
PDFQuery is a light wrapper around pdfminer, lxml and pyquery.

crossref - gives info from article citation, including DOI
freecite - another version of crossref that may do the same, may have online version we could utilize.
other sources
fulltext - https://github.com/ropensci/fulltext
rOpenSci - https://ropensci.org/packages/

useful R APIs:
-------------
rcrossref
fulltext
rplos
aRxiv
rentrez


search "citation parser" in Google

FreeCite - http://freecite.library.brown.edu/
FreeCite API - http://freecite.library.brown.edu/welcome/api_instructions

Other Citation Tools to explore from FreeCite:
-ParaCite
-ParsCit
-A citation metadata extraction tool from the California Digital Library
-CrossRef's DOI retriever
-Biblio Citation Parser

another parser from Github: https://github.com/inukshuk/anystyle-parser
it's live here: http://anystyle.io/

http://www.crossref.org/#: You can even paste entire references into the search box and discover their DOIs.

contains some useful links: http://superuser.com/questions/24081/automatic-parsing-of-citation-text-in-academic-references
and more links: http://stackoverflow.com/questions/7444057/seeking-citation-parser

yet another parser: http://search.cpan.org/~mjewell/Biblio-Citation-Parser-1.10/lib/Biblio/Citation/Parser/Standard.pm



pyPDF, PDFMiner


Questions for Duncan:

where is the function xmlParse() ? - in XML library

Work flow:

1. Input CV as pdf
2. Determine if pdf contains text or an image
3. Pass CV to PDFMiner to extract XML 
4. Parse XML to extract list of citations
5. Pass each citation to anystyle-parser
6. Extract doi, arXiv, or year if available
7a. If doi or arXiv found, then we've likely found the exact article, otherwise
7b. Query rcrossref (and/or aRxiv), cross-checking results with article title, and retaining scores.

Best 


