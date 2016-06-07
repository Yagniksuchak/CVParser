rm(list = ls())
#setwd("~/Dropbox/GSR/parse_citations/R/")
setwd("~/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/R")


source("pdf_to_xml.R")
source("parse_citations.R")
source("extract_sections.R")
source("extract_citations.R")

#######################
# Extracting sections #
#######################

if( FALSE ) {
    xml_files = list.files("~/Dropbox/GSR/CV_examples/CV_XML", full.names = TRUE)
    xml_files
    
    results = lapply(xml_files, parse_cv, print_sections = TRUE)
    
    total_sections = length(xml_files)
    found_sections = sum( sapply(results, function(r) length(r[[2]]) > 0 ) )
    
    found_sections / total_sections
}

#################
# Exploring XML #
#################

if( FALSE ) {
    # parse xml
    filename = "~/Dropbox/GSR/CV_examples/CV_XML/cv_amir.xml"
    doc = xmlParse(filename)
    
    # some xml output from page 1
    getNodeSet(doc, "//page[@id=1]//textbox")[1:3]
    
    # getting all text locations, font, and size from page 1
    xpathSApply(doc, "//page[@id=1]//textbox/textline", xmlGetAttr, "bbox")
    xpathSApply(doc, "//page[@id=1]//textbox/textline/text", xmlGetAttr, "font")
    xpathSApply(doc, "//page[@id=1]//textbox/textline/text", xmlGetAttr, "size")
    
    # counts for the whole document
    table(xpathSApply(doc, "//textbox/textline/text", xmlGetAttr, "font"))
    table(xpathSApply(doc, "//textbox/textline/text", xmlGetAttr, "size"))
}

########################
# Extracting citations #
########################

get_name = 
function( cv_filename )
{
#     doc = xmlParse( cv_filename )
#     text = xpathSApply(doc, "//page[@id=1]//textbox/textline", xmlValue)
    
    text = parse_cv( cv_filename )[[1]]$text
    
    text[ !grepl( "Curriculum Vitae", text, ignore.case = TRUE ) ][1]
}

filenames = c( "~/Dropbox/GSR/CV_examples/CV_XML/cv_amir.xml",
               "~/Dropbox/GSR/CV_examples/CV_XML/rubincv.xml",
               "~/Dropbox/GSR/CV_examples/CV_XML/SHANASIEGELCVFall2015.xml",
               "~/Dropbox/GSR/CV_examples/CV_XML/cv_amir.xml" )

#pub_filename = "~/Dropbox/GSR/parse_citations/text_files/publications.txt"
pub_filename = "/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/publications.txt"
#section_filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt"
section_filename = "/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/section_names.txt"
#xml_files = list.files("~/Dropbox/GSR/CV_examples/CV_XML", full.names = TRUE)
xml_files = list.files("/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML", full.names = TRUE)

xml_files

# cv_names = sapply( xml_files, get_name )
# data.frame( unname(tolower( trim( cv_names ) ) ), gsub( ".*/(.*)\\.xml", "\\1", names(cv_names) ) )
# write( unname(tolower( trim( cv_names ) ) ), "cv_names.txt" )

# took ~36 minutes for 65
start = proc.time()
sink( file("citation_output.txt", open = "wt") )

cv_names = tolower( readLines( "/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/cv_names.txt" ) )
filenames = xml_files
found_citations = mapply( function(file, cv_name) {
    results_df = try( main( file, cv_name, pub_filename, section_filename ), silent = TRUE )
    
    # if we get an error, print the file name and continue
    if( class(results_df) == "try-error" ) {
        print( paste( "Error with file:", file ) )
        results_df = NULL
    }
    cat( "\n\n" )
    results_df
    }, filenames, cv_names)

sink()
proc.time() - start

save_filename = sprintf( "/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/saved_results/found_citations_%s.RData", Sys.Date() )
save( found_citations, file = save_filename )


filenames = xml_files
found_citations = lapply( filenames, function(file) {


if( FALSE ) {
    length( found_citations )
    mask = sapply( found_citations, class ) == "list"
    found_citations[ mask ] = NULL
    sapply( found_citations, class )
    load( "~/Dropbox/GSR/parse_citations/saved_results/found_citations_2015-11-28.RData" )
}


cv_names = tolower( readLines( "cv_names.txt" ) )
main( xml_files[1], cv_names[1], pub_filename, section_filename )


sapply( found_citations, class )
mask = which( sapply( found_citations, class ) == "data.frame" )
length(mask)
found_citations_2 = do.call( rbind, found_citations[mask] )


class(found_citations_2)
dim(found_citations_2)
table( found_citations_2$id )

rownames( found_citations_2 ) = NULL

head( found_citations_2 )

write.csv( found_citations_2, "text_citations.csv" )

mask = found_citations_2$citation_rank == 1
table( found_citations_2[ mask, ]$id )

fc = found_citations_2[ mask, ]
median( fc$title_score )
mean( fc$title_score )

median( fc$score )
mean( fc$score )



hist( fc$title_score )
hist( fc$score )

example = found_citations_2[ found_citations_2$id == "JBLucks_CV_Cornell_2015_Web1" & mask, ]

o_cite = substring( example$original_citation, 1, 60 )
data.frame( o_cite, round( example$score, 2) , example$title_score )


df = found_citations_2[ mask, ]
stats = aggregate( df[ ,c("title_score", "merge_score", "score")], list( df$id ), mean )
num_citations = aggregate( df[ ,c("title_score")], list( df$id ), length )
stats$num_citations = num_citations$x

ordering = order( stats$merge_score, decreasing = TRUE )
stats = stats[ ordering, ]

cbind( stats$Group.1, round(stats[, -1], 2) )

# found_citations = main( cv_filename, pub_filename, section_filename )

# removing these columns for display only
col_names = c("original_citation", "fullCitation", "authors", "title")
display = found_citations[, !names(found_citations) %in% col_names]

head(display)

table( display$id )

# still need to fix column resumes "/Users/kdelrosso/Dropbox/GSR/CV_examples/CV_XML/rubincv.xml
# use last name (et al) to determine citations
# find citations using dates

