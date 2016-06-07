# testing functions from Duncan
rm(list = ls())

require(fulltext)
require(rplos)
require(aRxiv)
require(rentrez)
require(RCurl)
require(RJSONIO)
require(rcrossref)
require(XML)
require(stringr)
require(magrittr)
require(zoo)

setwd("~/Dropbox/GSR/CVRead/R/")

# R files from Duncan
source("freecite.R")
source("procMiner.R")
source("crossref.R")
source("text.R")
source("utils.R")

# set path to pdfminer
options(PDF2TXT = "~/anaconda/bin/pdf2txt.py")

escape_char_fix = 
function(file)
{
    char_to_fix = "[]{}() ,!@$^&*`'"
    char_to_fix = unlist( strsplit( char_to_fix, "" ) ); char_to_fix
    for( c in char_to_fix ) {
        file = gsub( c, paste0("\\", c), file, fixed = TRUE )
    }
    file
}

pdf_to_xml = 
    # batch convert .pdf file to .xml in the given directory
function(input_dir) 
{
    all_files = list.files(input_dir)

    # only keep files with .pdf extension
    to_keep = grepl("\\.pdf$", all_files)
    all_files = all_files[to_keep]
    all_files_pdf = sapply(all_files, escape_char_fix)
    
    # create directory for xml files
    output_dir = file.path(input_dir, "../CV_XML")
    dir.create(output_dir, showWarnings = FALSE)
    
    # output file names and full paths
    new_filenames = gsub( "\\.pdf$", ".xml", all_files)
    output_full_path = file.path(output_dir, new_filenames)
    input_full_path = file.path(input_dir, all_files_pdf)
 
    mapply( function(pdf_doc, filename) {
        doc = try( pdfMinerDoc(pdf_doc), silent = TRUE)
        if( class(doc) != "try-error" ) {
            saveXML( doc, filename )
        } else {
            # print filename on error
            print( filename )
        }
        }, input_full_path, output_full_path )
    
    list.files(output_dir)
}

# got error with "../../CV_examples/SampleCVs/../CV_XML/colom_CV.xml"
dir = "../../CV_examples/SampleCVs"
if(FALSE) pdf_to_xml(dir)

##################
# Main Functions #
##################

common_sections = function(filename) {
    readLines(filename)
}

bbox_to_df = 
    # INPUT: character vector of bbox location
    # OUTPUT: data.frame with numeric columns
    #   columns: top, bottom, right, top
    #   bottom and top are measured from the bottom of page
function(bbox)
{
    df = do.call( rbind, strsplit( bbox, ",") )
    df = apply(df, 2, as.numeric)
    df = as.data.frame( df )
    
    set_colnames( df, c("left", "bottom", "right", "top"))
}

size_text = 
function(doc, page_num)
{
    # get charcterSizes for every character in a textline on page page_num
    char_size = xpathSApply(doc, sprintf("//page[@id=%s]//textbox/textline", page_num), xmlGetAttr, "charcterSizes")
    by_line = strsplit( char_size, ",")
    
    # we'll give a line the size of it's most common character size
    common_size = lapply( by_line, function(line) names( which.max( table(line) ) ) )
    unlist(common_size)
}

get_text_info = 
function(doc, page_num = 8)
{
    # get bbox dimensions for every textline on page page_num, convert to a data frame
    bbox = xpathSApply(doc, sprintf("//page[@id=%s]//textbox/textline", page_num), xmlGetAttr, "bbox")
    bbox_df = bbox_to_df(bbox)
    
    bbox_df$text = xpathSApply(doc, sprintf("//page[@id=%s]//textbox/textline/text", page_num), xmlValue)
    bbox_df$text_size = as.numeric( size_text(doc, page_num) )
    
    bbox_df$font = xpathSApply(doc, sprintf("//page[@id=%s]//textbox/textline/text", page_num), xmlGetAttr, "font")
    
    # make sure textline are in the correct order
    ordering = order( bbox_df$top, decreasing = TRUE)
    bbox_df[ordering, ]
}

white_space = 
    # simple version of white_space to call after location_text
    # finds the amount of white space between each line of text
function(df)
{
    top = df$top
    bottom = df$bottom
    
    below = bottom - c(top[-1], NA)
    above = c(NA, bottom[-length(bottom)]) - top

    list(below = below, above = above)    
}

all_caps = 
    # INPUT: data frame with text as column
    # OUTPUT: the longest continuous all caps text
function(df, text_col = "text")
{
    text = df[[text_col]]
    setNames( sapply( text, find_upper ), NULL )
}

# trim leading and training whitespace from character vector
trim = function(char_vector) {
    setNames( sapply( char_vector, function (x) gsub("^\\s+|\\s+$", "", x) ), NULL )
}

# replace everything not alphanumeric, space, or ampersand
remove_punct = function(char_vector) {
    setNames( sapply( char_vector, function (x) gsub("[^[:alnum:][:space:]\\&]", "", x) ), NULL )
}

find_upper = 
    # return all upper case text from beginning of a line
function( text, min_length = 6 )
{
    # for simplicity, remove all punctuation
    text = remove_punct(text)
    text = trim( str_extract( text, "^[[:upper:]\\s]+") )
    if( is.na(text) | nchar(text) < min_length ) return("")
    
    text
}

df_per_page = 
function(doc, page_number)
{
    df = get_text_info(doc, page_number)
    df$caps = all_caps( df )
    df$caps_tf = as.integer( nchar( df$caps ) != 0 )

    space = white_space(df)
    df$above = space$above
    df$below = space$below
    
    df$page_num = page_number
    
    df 
}

doc_to_df = 
function(doc, short_text = FALSE)
{
    # get the number of pages
    root <- xmlRoot(doc)
    num_pages = as.numeric( xmlGetAttr(root, "numPages") )
    
    # create a df for each page, return combined result
    df_list = lapply( 1:num_pages, df_per_page, doc = doc  )
    df = do.call(rbind, df_list)
    
    df$n_char = nchar( df$text )
    
    # remove blank and lines with only spaces (i.e. don't contain alphanumeric or punctuation)
    df = df[ grepl("[[:alnum:][:punct:]]", df$text), ] 
    df$text_size_norm = round( df$text_size, 1 )
    
    df$left_norm = round(df[, "left"], 0)
    
    df$font_bold = as.integer( grepl("bold", df$font, ignore.case = TRUE) )
    df$font_italic = as.integer( grepl("italic", df$font, ignore.case = TRUE) )
    
    pos_above = na.fill( df$above, Inf ) > median(df$above, na.rm = TRUE)
    pos_below = na.fill( df$below, Inf ) > median(df$below, na.rm = TRUE)
    
    df$space_ab = as.integer( pos_above & pos_below )
    
    if( short_text ) {
        df$text = substring(df$text, 1, 20)
    }
    
    df
}

update_section_names = function(new_sections, filename) {
    write( tolower(new_sections), "../../section_names.txt", append = TRUE)
}

word_count = function(vect) {
    length( unlist( strsplit(vect, "\\s") ) )
}

search_section_names = 
    #
function(vect, section_names, inverse = FALSE)
{
    if( !inverse ) {
        vect = tolower( as.character(vect) )
        return( sum( vect %in% section_names ) )
    } 
    
    sum( sapply( section_names, function(word) sum( grepl(word, vect, ignore.case = TRUE) ) ) )
}

get_min_sections = function(df) {
    pages = max(df$page_num)
    
    # min_sections in the interval (3, 7)
    min_sect = 0.5 * pages + 2
    min_sect = max( c(3, min_sect) )
    min_sect = min( c(7, min_sect) )
    
    floor(min_sect)
}


# ask for user input to identify sections
get_user_input = function(group_by_list) {
    print(group_by_list)
    
    n = length(group_by_list)
    index = Inf
    while( index > n ) {
        cat("\n", "Enter group number: (-1 for none)", "\n")
        index = as.numeric( readline() )
        if(index == -1) return(NULL) 
        if(index == 0) index = Inf
    }
    tolower( group_by_list[[index]] )
}


fix_group_text = 
function(vect, fix = FALSE)
{
    vect = trim( remove_punct( as.character(vect) ) )
    if( fix ) {
        vect = sapply( strsplit(vect, "  "), function(text) {
            paste( gsub("\\s", "", text), collapse = " " ) 
            })
    }
    vect
}


compare_with_sections = 
    # INPUT:
    #   - group_by: list of character vectors, for each group
    #   - section_names: previously found sections names to match against
    #
    # OUTPUT: TRUE/FALSE mask if the number of matched elements is greater than 1
    # DOC: for each character vecter, get the count of the number of occurances in section_names
function( group_by, section_names, min_match = 1, inverse = FALSE)
{
    match_sum = sapply( group_by, function(vect) search_section_names( vect, section_names, inverse ) )
    mask = match_sum > min_match
    if( sum(mask) == 0 ){
        # similar to above, but we first fix the character vector and then search
        match_sum = sapply( group_by, function(vect) {
            search_section_names( fix_group_text(vect, fix = TRUE), section_names, inverse ) 
            })
        mask = match_sum > min_match
    }
    mask
}

cv_search_tree =
    # on the first pass, we'll use uppercase as a give away from sections, then group
function(df, section_names, group_list, min_sections = get_min_sections(df), max_sections = 50, pass = 1) 
{
    print( sprintf( "Pass: %s", pass) )
    
    # for testing
    if( FALSE ) {
        min_sections = get_min_sections(df)
        max_sections = 50
        group_list = list(df$caps_tf, df$text_size, df$font_bold, df$font_italic, df$font)
    }
    
    group_by = aggregate( df$text, by = group_list, function(x) x, simplify = FALSE )$x
    
    # filter group_by list, to those between min/max section length, and convert to character
    mask = sapply(group_by, function(vect) (length(vect) > min_sections) & (length(vect) < max_sections) )
    
    # remove punctuation and leading and trailing white space
    group_by = unname( lapply( group_by[mask], fix_group_text ) )
    
#     match_sum = sapply( group_by, function(vect) search_section_names( vect, section_names ) )
#     mask = match_sum > 1
    
    mask = compare_with_sections( group_by, section_names )
    
    if( length(group_by) != 0) {
        if( sum(mask) == 1 ) {
            return( tolower( group_by[mask][[1]]) )
        } else {
            
#             match_sum = sapply( group_by, function(vect) search_section_names( vect, section_names, inverse = TRUE ) )
#             mask = match_sum > 1
            mask = compare_with_sections( group_by, section_names, inverse = TRUE )
            
            # ratio of total words to matched words
            words_by_group = sapply( group_by, word_count )
            ratio = match_sum / words_by_group
            
            # we require at least 2 matching words, then we'll take the largest ratio
            mask = mask & ( ratio = max(ratio) )
            
            if( sum(mask) == 1 ) {
                return( tolower( group_by[mask][[1]]) )
            } 
        }
    }
    
    if( pass == 1 ) {
        # searching for centered text, also adding font
        group_list = list(df$caps_tf, df$text_size, df$font_bold, df$font_italic, df$font)
        cv_search_tree(df, section_names, group_list, min_sections, max_sections, pass = 2)
    } else if ( pass == 2 ){
        # next pass here
    }  
}


fix_sections = 
function( sections )
{
    if( length(sections) > 0 ){
        # in case we included a line with their name (using the assumption it's first)
        if( grepl("phd", sections[1]) ) sections = sections[-1]
    }
    sections
}

parse_cv =
    #
function(filename, section_filename = "../../section_names.txt")
{
    print( filename )
    
    # for testing
    if( FALSE ) {
        section_filename = "../../section_names.txt"
        filename = "../../CV_examples/CV_XML/CV_-_Whooley_updated_2015_apps.xml"
    }
    
    # get the file extension
    extension = tolower( substring( filename, nchar(filename) - 3) )
    
    # parse xml
    doc = 
        if( extension == ".pdf" ) {
            pdfMinerDoc(filename)
        } else if( extension == ".xml" ) {
            xmlParse(filename)
        } else {
            stop( "Input file must be either .pdf or .xml" )
        }
    
    # for testing / exploring XML
    if( FALSE ) {
        getNodeSet(doc, "//page[@id=1]//textbox")
        xpathSApply(doc, "//page[@id=1]//textbox/textline", xmlGetAttr, "bbox")
    }
    
    df = doc_to_df( doc, short_text = FALSE )
    
    section_names = common_sections( section_filename )
    
    group_list = list(df$caps_tf, df$text_size, df$font_bold, df$font_italic, df$left_norm)
    new_sections = cv_search_tree(df, section_names, group_list)
    
    new_sections = fix_sections( new_sections )

    print( new_sections )
    cat("\n\n\n")
    new_sections
}


####################
# Testing the Code #  
####################

parse_cv( "../../CV_examples/CV_XML/CV_-_Whooley_updated_2015_apps.xml" )
# xml_files = list.files("../../CV_examples/CV_XML", full.names = TRUE)[c(14, 20, 22, 24, 26, 27, 30, 41, 44)]
# invisible( lapply(xml_files, parse_cv) )


# write( tolower(group_by[[1]]), "../../section_names.txt")
# update_section_names(tolower(group_by[[1]]), "../../section_names.txt")

# doc = "../../CV_examples/cv_amir.pdf"
# doc = "../../CV_examples/JBLucks_CV_Cornell_2015_Web1.pdf"
# doc = "../../CV_examples/CVTsoukiasweb.pdf"
# doc = "../../CV_examples/Mulhearn_CV.pdf"

# doc = pdfMinerDoc(doc)
# df = doc_to_df( doc, short_text = FALSE )
# head(df, 20)

# section_names = common_sections("../../section_names.txt"); section_names
# new_sections = cv_search_tree(df, section_names); new_sections

# update_section_names(new_sections, "../../section_names.txt")

# df[df$text_size_norm > 1.25, ]
# 
# sum( df$positive_space )
# 
# quantile( df$left_norm, probs = seq(0, 1, 0.1) )
# 
# sum( df$left_norm == min(df$left_norm) )

# strange examples:
"../../CV_examples/CV_XML/CV_Behler_2015_LaTex.xml" # columns
"../../CV_examples/CV_XML/rubincv.xml" # columns
"../../CV_examples/CV_XML/Resume-8-2015.xml" # centered titles




###############
# Extra Stuff #  
###############

# doc = pdfMinerDoc(doc)
# 
# root <- xmlRoot(doc)
# num_pages = as.numeric( xmlGetAttr(root, "numPages") )
# 
# by_page = getNodeSet(doc, "//page")
# 
# lapply( 1:num_pages, 
#         function(page_num) xpathSApply(doc, sprintf("//page[@id=%s]//textbox/textline", page_num), xmlValue) )
# 
# location_text(doc)
# 
# xpathSApply(doc, "/pages/page/textbox/textline/text", xmlValue)
# 
# xpathApply(r, "//textbox[@id='1']", xmlValue)
# 
# length( xmlChildren(r) )
# 
# xmlAttrs(r[[1]][[1]][[1]])
# 
# xmlSize(r[[5]])
# xmlName(doc)
# xmlChildren(r)
# 
# getNodeSet(doc, "/pages/page/textbox/textline")[1:10]
# table( xpathSApply(doc, "/pages/page/textbox/textline/text", xmlGetAttr, "font") )
# 
# bbox = xpathSApply(doc, "/pages/page/textbox/textline", xmlGetAttr, "bbox")
# df = do.call( rbind, strsplit( bbox, ",") )
# df = as.data.frame( df, stringsAsFactors = FALSE)
# 
# for( col in names(df) ){
#     df[[col]] = as.numeric( floor(df[[col]]) )
# }
# sapply( df, class )
# 
# xpathSApply(doc, "/pages/page/textbox/textline", xmlValue)[1:30]
# head(df, 30)
# 
# table(df$V1)
# 
# text_box = xpathApply(r, "//textbox", xmlValue)
# text_box = unlist(text_box)
# text_box = text_box[ nchar(text_box) > 0 ]

# is_upper = 
#     # return TRUE if text is all uppercase, FALSE otherwise
# function( text ) 
# {
#     upper_case_text = toupper(text)
#     
#     text == upper_case_text
# }

# white_space = 
#     # finds the amount of white space between each line of text
# function(doc)
# {
#     bbox = xpathSApply(doc, "/pages/page/textbox/textline", xmlGetAttr, "bbox")
#     bbox_df = bbox_to_df(bbox)[, c("bottom", "top")]
#     
#     top = bbox_df$top
#     bottom = bbox_df$bottom
#     
#     below = bottom - c(top[-1], NA)
#     above = c(NA, bottom[-length(bottom)]) - top
#     
#     data.frame(above = above, 
#                below = below, 
#                text = substring( xpathSApply(doc, "/pages/page/textbox/textline/text", xmlValue), 1, 20 ) )
# }


# ways to create sections:
# all caps
# indent
# size change
# font change
# underline

## to implement
# series of function, first_pass, second_pass, .....
# only keep nchar > 1, do before checking line spacing - DONE
# function for min sections based on number of pages
# left_norm_round - DONE
