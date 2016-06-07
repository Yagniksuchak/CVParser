# testing functions from Duncan
rm(list = ls())

install.packages( c("fulltext", "rplos", "aRxiv", "biorxivr", "rentrez") )
install.packages("alm")


library(fulltext)
library(rplos)
library(aRxiv)
library(rentrez)

# library(biorxivr)

query = "AghaKouchak A., Habib E., Bárdossy A., 2010, A comparison of three remotelysensed rainfall ensemble generators, Atmospheric Research, 98(2-4), 387-399"

res = ft_search(query, from = c("plos", "crossref", "BMC", "arxiv"))
attributes(res$crossref)
as.data.frame( res$crossref$data )

res$arxiv

arxiv_search(id_list = "1207.6631")$doi
q = "Combined search for the standard model Higgs boson decaying to b bbar using the D0 Run II data set"
arxiv_search(q)

library(RCurl)
library(RJSONIO)
library(rcrossref)
library(XML)
library(stringr)

setwd("~/Desktop/GSR/CVRead/R/")

freecite(query)

source("freecite.R")
source("procMiner.R")
source("crossref.R")
source("text.R")
source("utils.R")

start = proc.time()

options(PDF2TXT = "~/anaconda/bin/pdf2txt.py")

doc = "../../CV_examples/cv_amir.pdf"
doc = pdfMinerDoc(doc)

r <- xmlRoot(doc)

xmlSize(r[[5]])
xmlName(r[[5]][[1]])

text_box = xpathApply(r, "//textbox", xmlValue)
text_box = unlist(text_box)
text_box = text_box[ nchar(text_box) > 0 ]
publications = text_box[ (which( text_box == "Publications" ) + 1) : (which( text_box == "Books" ) - 1)  ]
publications[1:10]

publications = gsub( "^([0-9]+\\. )", "", publications )
publications[10:20]

publications = sapply( strsplit(publications, "doi:"), '[', 1)

check_title = function(titles, citation) {
    word_pairs = function(list_of_words, num) {
        list_of_words = list_of_words[nchar(list_of_words) > 1]
        paste_results = function(index, word) {
            paste( word[seq(index, index + num - 1)], collapse = " " ) 
        }
        sapply(seq(1, length(list_of_words) - num), paste_results, list_of_words) 
    }
    
    percent_contained = function(word_list, string) {
        tf = sapply( tolower(word_list), grepl, x = tolower(string), ignore.case = TRUE, fixed = TRUE)
        sum(tf) / length(word_list)
    }
    
    words = lapply( strsplit( gsub("^ | $", "", titles), " +"), word_pairs, 3)
    
    mapply(percent_contained, words, citation)
    
}

search_num = 10
scores = numeric(10)
accuracy = numeric(10)

i = 1
for (p in publications[20:30]) {
    print(i)
    print(p)
    reg = "[ ,\\.\\)\\}\\]](19[0-9]{2}|200[0-9]|201[0-9])[ ,\\.\\)\\}\\]]"
    year = as.numeric( gsub( "[^0-9]", "", str_extract(p, reg) ) )
    
    if ( is.na(year) ) {
        year = NULL
    }
    
    print(year)
    
    results = cr_search(query = p, sort = "score", type = "Journal Article", rows = search_num)
    scores[i] = results$score[1]
    
    titles = results$title
    print( check_title( titles, p) )
    accuracy[i] = max( check_title( titles, p) )
    
    i = i + 1
}

data.frame(scores, accuracy)

proc.time() - start


options(error = recover)

cite = "Mazdiyasni O., AghaKouchak A., 2015, Substantial Increase in Concurrent Droughts and Heatwaves in the United States, Proceedings of the National Academy of Sciences, doi: 10.1073/pnas.1422945112."



















freecite(publications[3])

http://api.crossref.org/works/10.1037/0003-066X.59.1.29/agency

doc = convertPDF(doc)
doc = xmlParse(doc)

r <- xmlRoot(doc)

xmlSize(r)
xmlName(r)

xmlName(r[[1]][[1]][[1]][[1]][[1]])
xmlSize(r)

xmlAttrs(r)

sapply(xmlChildren(r[[1]]), xmlName)

xmlValue( r[[1]][[1]][[1]])

xmlSApply(r[[1]], xmlName)
xmlApply(r[[1]][[1]][[1]], xmlAttrs)
xmlSApply(r[[1]], xmlSize)

xmlValue( r[[4]] )



test_d = "10.3390/rs1030606"
cr_agency( test_d )
cr_citation_count( test_d )
query = "AghaKouchak A., Habib E., Bárdossy A., 2010, A comparison of three remotelysensed rainfall ensemble generators, Atmospheric Research, 98(2-4), 387-399"
cr_fundref( query = "A comparison of three remotelysensed rainfall ensemble generators")

pre = "10.3390"
cr_prefixes( pre )

query = "AghaKouchak A., Habib E., Bárdossy A., 2010, A comparison of three remotelysensed rainfall ensemble generators, Atmospheric Research,"

scores = numeric(10)
i = 1
for (p in publications[1:10]) {
    print( paste("\n", p ))
    results = cr_search(query = p, sort = "score", type = "Journal Article", rows = 3)
    print( results[c("doi", "score", "fullCitation")] )
    scores[i] = results$score[1]
    i = i + 1
}

scores

results[c("doi", "score", "fullCitation")]

cr_search_free(query)

q = "V.M. Abazov Michael J Mulhearn [D0 Collaboration], “Combined search for the standard model Higgs boson decaying to bb using the D0 Run II data” Phys. Rev. Lett. 109, 121802 (2012)"
q = "T. Aaltonen, Michael J Mulhearn  [CDF and D0 Collaborations], “Evidence for a particle produced in association with weak bosons and decaying to a bottom-antibottom quark pair in Higgs boson searches at the Tevatron” Phys. Rev. Lett. 109, 071804 (2012) [arXiv:1207.6436]"

q = "V.M. Abazov Michael J Mulhearn [D0 Collaboration], “Search for the Standard Model Higgs Bo- son in the H → WW → lνqq ̄ Decay Channel”, Phys. Rev. Lett. 106, 171802 (2011) [arXiv:1101.6079]"
q = "V.M. Abazov et al. [D0 Collaboration], “Search for WH Associated Production in 5.3 fb1 of pp ̄ Collisions at the Fermilab Tevatron”, Phys. Lett. B 698, 6 (2011) [arXiv:1012.0874]"

results = cr_search(query = q, sort = "score", type = "Journal Article", rows = 10)
print( results[c("doi", "score", "title", "year")] )

titles = results$title

check_title = function(titles, citation) {
    word_pairs = function(list_of_words, num) {
        list_of_words = list_of_words[nchar(list_of_words) > 1]
        paste_results = function(index, word) {
            paste( word[seq(index, index + num - 1)], collapse = " " ) 
        }
        sapply(seq(1, length(list_of_words) - num), paste_results, list_of_words) 
    }
    
    percent_contained = function(word_list, string) {
        tf = sapply( tolower(word_list), grepl, x = tolower(string), ignore.case = TRUE, fixed = TRUE)
        sum(tf) / length(word_list)
    }
    
    words = lapply( strsplit( gsub("^ | $", "", titles), " +"), word_pairs, 3)
    print( words )
    
    mapply(percent_contained, words, citation)
    
}

check_title( titles, q)


q1 = "V.M. Abazov et al. [D0 Collaboration], “Combined search for the standard model Higgs boson decaying to bb using the D0 Run II data” Phys. Rev. Lett. 109, 121802 (2012) [arXiv:1207.6631]."
q2 = "J. B. Lucks, A. J. Cohen, N. C. Handy* (2002). Constructing a map from the electron density to the exchange-correlation potential. Physical Chemistry Chemical Physics, 4, 4612-4618."
q3 = "Shukla S., Safeeq M., AghaKouchak A., Guan K., Funk C., 2015, Temperature Impacts on the Water Year 2014 Drought in California, Geophysical Research Letters, 42, 4384- 4393, doi:10.1002/2015GL063666."

citations = c(q1, q2, q3)
# sprintf('print "\n\n %s \n\n"', cite)
to_ruby = sapply(citations, function(cite) c( 'print "\n"', sprintf('c = Anystyle.parse"%s"', cite), "print c.to_json" ) )

to_write = c("require 'anystyle/parser'", "require 'json'", to_ruby)

test_file = "../../test.rb"
write(to_write, test_file)

output = system( sprintf("ruby %s", test_file), intern = TRUE)

library(jsonlite)

output = output[nchar(output) > 0]
output = fromJSON(output[1])
length(output)
as.data.frame(output)
