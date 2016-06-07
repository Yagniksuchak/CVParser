# testing functions from Duncan
# rm(list = ls())
setwd("~/Dropbox/GSR/parse_citations/R/")

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
require(zoo) # for using na.fill

# R files from Duncan
source("~/Dropbox/GSR/CVRead/R/freecite.R")
source("~/Dropbox/GSR/CVRead/R/procMiner.R")
source("~/Dropbox/GSR/CVRead/R/crossref.R")
source("~/Dropbox/GSR/CVRead/R/text.R")
source("~/Dropbox/GSR/CVRead/R/utils.R")

# for querying citations
source("parse_citations.R")

# set path to pdfminer
options(PDF2TXT = "~/anaconda/bin/pdf2txt.py")

escape_char_fix = 
    # INPUT: character vector of length 1 and optionally a string of characters to fix
    # DOC: fixes file name, adds '\' before special character to avoid error in bash
function(file, char_to_fix = "[]{}() ,!@$^&*`'")
{
    char_to_fix = unlist( strsplit( char_to_fix, "" ) ); char_to_fix
    
    # add '\' a forward slash before each char_to_fix
    for( c in char_to_fix ) {
        file = gsub( c, paste0("\\", c), file, fixed = TRUE )
    }
    file
}

pdf_to_xml = 
    # INPUT: an input and output directory location
    # DOC: batch convert .pdf file to .xml in the given directory
function(input_dir, output_dir = "../CV_XML") 
{
    # get all the pdf files in the input directory
    all_files = list.files(input_dir, pattern = "\\.pdf$")

    # fix file names with problem characters
    all_files_pdf = sapply(all_files, escape_char_fix)
    
    # create directory for xml files
    output_dir = file.path(input_dir, output_dir)
    dir.create(output_dir, showWarnings = FALSE)
    
    # output file names (keep original names) and full paths
    new_filenames = gsub( "\\.pdf$", ".xml", all_files)
    output_full_path = file.path(output_dir, new_filenames)
    input_full_path = file.path(input_dir, all_files_pdf)
 
    mapply( function(pdf_doc, filename) {
        # in case we get an error with a file, we print the file name and move on
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
dir = "~/Dropbox/GSR/CV_examples/SampleCVs"
if(FALSE) pdf_to_xml(dir)

##################
# Main Functions #
##################

# for reading in saved section names from a txt file
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
    # INPUT: XML doc and a page number
    # OUTPUT: the text size from every line of the doc
    # DOC: currently assigns the text size as the most common character size
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
    # INPUT: XML doc and a page number
    # OUTPUT: 
    #   - data.frame of text lines, in the correct order (from top to bottom)
    #   - currently contains columns for text, text location, size, and font
    # DOC: pdfminer creates textboxes, which don't necessarily go line by line
    # thus it's possible for lines to be shuffled in their vertical order. Taking the document
    # page by page and ordering the text locations solves this issue.
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
    # INPUT: a data.frame with columns for text location ( specifically top and bottom )
    # OUTPUT: 2 element list, with space above and below text
    # DOC: still working to understand the spacing (i.e. sometimes we get negative values??)
    # not an issue with the code but the info from pdfminer
function(df)
{
    top = df$top
    bottom = df$bottom
    
    # at the top/bottom of a page we'll mark with NA
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


trim = 
    # trim leading and training whitespace from a character vector
    # also remove punctuation with punct = TRUE
function( char_vector, punct = FALSE) 
{
    reg = 
        if( punct ) {
            "[[:space:][:punct:]]"
        } else {
            "[[:space:]]"
        }
    
    rx = sprintf( "^%s+|%s+$", reg, reg )
    gsub( rx, "", char_vector )
}

# remove everything not alphanumeric or space
remove_punct = function(char_vector) {
    gsub( "[^[:alnum:][:space:]]", "", char_vector )
}


df_per_page = 
    # INPUT: XML doc and a page number
    # DOC: calls previous functions to get text, capitalization, and spacing info
    # for each line of text on a page
function(doc, page_number)
{
    # get text and location info
    df = get_text_info(doc, page_number)
    
    # get capitalization info
    df$caps = all_caps( df )
    df$caps_tf = as.integer( nchar( df$caps ) != 0 )
    
    # get spacing info
    space = white_space(df)
    df$above = space$above
    df$below = space$below
    
    df$page_num = page_number
    
    df 
}

doc_to_df = 
    # INPUT: document in xml format
    # OUTPUT: data.frame with relevant text location, size, type extracted
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
    df$right_norm = round(df[, "right"], 0)
    
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

update_section_names = 
function(new_sections, filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt")
{
    write( tolower(new_sections), filename, append = TRUE)
}

word_count = function(vect) {
    length( unlist( strsplit(vect, "[[:space:]]") ) )
}

search_section_names = 
    # returns to total number and percentage of elements in vect that are in sections_names
function(vect, section_names, use_sum = TRUE)
{
    vect = tolower( as.character(vect) )
    sections_found = vect %in% section_names
    
    if( use_sum ) {
        return( sum(sections_found) )
    } else {
        return( mean(sections_found) )
    }
}

# use number of pages to estimate the minimum allowed sections
get_min_sections = function(df) {
    pages = max(df$page_num)
    
    # min_sections in the interval (3, 7)
    min_sect = 0.5 * pages + 2
    min_sect = max( c(3, min_sect) )
    min_sect = min( c(7, min_sect) )
    
    floor(min_sect)
}


# ask for user input to identify sections (not currently used)
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
    # fix leading and trailing white space
    # also fix = TRUE to fix " T H I S  E X A M P L E "
function(vect, fix = FALSE)
{
    vect = trim( remove_punct( as.character(vect) ) )
    if( fix ) {
        vect = sapply( strsplit(vect, "  "), function(text) {
            paste( gsub("[[:space:]]", "", text), collapse = " " ) 
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
function( group_by, section_names, min_match = 1)
{
    match_sum = sapply( group_by, function(vect) search_section_names( vect, section_names ) )
    mask = match_sum > min_match
    if( sum(mask) == 0 ){
        # similar to above, but we first fix the character vector and then search
        match_sum = sapply( group_by, function(vect) {
            search_section_names( fix_group_text(vect, fix = TRUE), section_names ) 
            })
    }
    match_sum
}

cv_search_tree =
    # INPUT:
    #   - df: data.frame with feature for text
    #   - section_names: found section names to compare with groups that are created
    #   - group_list: the ways to groups the text features
    #
    # OUTPUT: the subsections found ( if any )
    #
    # DOC: 
    #   - function is call somewhat recursively, by specifying a new group_list and iterating pass
    #   - pass 1, we'll use uppercase and left justified as a give away for sections
    #   - pass 2, we'll search for centered text and add font and grouping variable
function(df, section_names, group_list, min_sections = get_min_sections(df), max_sections = 50, pass = 1) 
{
    print( sprintf( "Pass: %s", pass) )
    
    # for testing
    if( FALSE ) {
        min_sections = get_min_sections(df)
        max_sections = 50
        group_list = list(df$caps_tf, df$text_size, df$font_bold, df$font_italic, df$font)
    }
    
    # group_by contains all the text for each group found
    group_by = aggregate( df$text, by = group_list, function(x) x, simplify = FALSE )$x
    
    # filter group_by list, to those between min/max section length, and convert to character
    mask = sapply(group_by, function(vect) (length(vect) > min_sections) & (length(vect) < max_sections) )
    
    # remove punctuation and leading and trailing white space
    group_by = unname( lapply( group_by[mask], fix_group_text ) )
    
    # still need to play with this parameter, important to determine when a group is considered the subsections
    match_sum = compare_with_sections( group_by, section_names )
    mask = match_sum > 1
    
    if( length(group_by) != 0) {
        if( sum(mask) == 1 ) {
            return( tolower( group_by[mask][[1]]) )
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
    # remove common sections which often have similar features to section names
function( sections )
{
    to_replace = c( "curriculum vitae", "mailing address", "address", "affiliations", 
                    "contact", "contact information")
    
    if( length(sections) > 0 ) {
        
        to_replace = paste( to_replace, collapse = "|" )
        sections = grep(to_replace, sections, invert = TRUE, value = TRUE)
        
        # in case we included a line with their name (using the assumption it's first)
        if( grepl("phd", sections[1]) ) sections = sections[-1]
        
    }
    sections
}


parse_cv =
    # INPUT:
    #   - filename: path to CV in either .pdf or .xml
    #   - section_filename: path to .txt file containing found section names (one per line)
    #   - short_text: TRUE/FALSE whether or not to include the full line text in df
    #
    # OUTPUT: 
    #   - 2 element list: a data.frame with text features and the sections found
function(filename, section_filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt", 
         short_text = FALSE, print_sections = FALSE)
{
    print( filename )
    
    # for testing
    if( FALSE ) {
        section_filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt"
        filename = "~/Dropbox/GSR/CV_examples/CV_XML/CV (2).xml"
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
    
    df = doc_to_df( doc, short_text )
    
    section_names = unique( common_sections( section_filename ) )
    
    # initial groups for searching for subsections
    group_list = list(df$caps_tf, df$text_size, df$font_bold, df$font_italic, df$left_norm)
    new_sections = cv_search_tree(df, section_names, group_list)
    
    new_sections = fix_sections( new_sections )
    
    if( print_sections ) {
        print( new_sections )
        cat("\n\n")
    }
    
    list( df, new_sections )
}


find_sequence = 
    # given a list of numbers, find the longest sequential list
    # searches both ascending and descending
function( numbers, starting = 1 ) 
{
    find_match = function( biggest, sequence ) {
        tf = biggest:1 %in% sequence
        mean(tf) == 1
    }
    
    if( (starting == 6) | (starting == length(numbers)) ) return( NULL )
    
    numbers = as.numeric(numbers)
    start = numbers[starting]
    
    if( start == 1 ) {
        max_num = Inf
        num_temp = numbers
        while( max_num > 1 ) {
            max_index = which.max( num_temp )
            max_num = num_temp[max_index]
            if( find_match( max_num, numbers) ) {
                return( 1:max_num )
            } else {
                num_temp = num_temp[-max_index]
            }
        }
    } else {
        if( find_match( start, numbers) ) return( start:1 )
    }
    find_sequence( numbers, starting + 1 )
}


extract_numbered_list = 
    # INPUT: text, each line of a citation
    # OUTPUT: NA, or the potential numbers in the numbered list
function(text) 
{
    nums = na.omit( str_extract( text, "^[[:digit:]]{1,2}[^[:digit:]]") )

    if( length(nums) == 0 ) return( NA )
    
    # exclude numbers from list that don't end with most common ending character
    last_char = str_extract( nums, ".$")
    keep_char = names( which.max( table(last_char) ) )
    nums = nums[ last_char == keep_char]
    
    as.numeric( gsub( "[^[:digit:]]", "", nums ) )
}


tf_numbered_list = 
    # is citation use a numbered list scheme, uses the numbers to 
    # group each line of text into corresponding citations
function( text, list_numbers ) 
{
    sequence = find_sequence(list_numbers)
    current_index = 1
    
    # count used for incrementing through groups vector
    count = 1
    groups = numeric( length(text) )
    
    for( string in text ) {
        # looking for a line of text starting with the next number in the list
        num_to_match = sequence[ current_index ]
        num = extract_numbered_list( string )
        
        skip = 
            if( is.na(num) | current_index > length(sequence) ) {
                TRUE
            } else {
                FALSE
            }
        
        # if we found the next number, increment groups and add current line to the next group
        if( !skip & num == num_to_match ) {
            current_index = current_index + 1
        }
        
        groups[count] = current_index
        count = count + 1
    }
    groups
    
    # for the last group
    if( which.max( groups ) + 2 <= length(groups) ) {
        groups[ (which.max( groups ) + 2) : length(groups) ] = max(groups) + 1
    }
    
    groups
}


right_left_groups = 
    # used to create citation groups based on right and left side indentation
    # right side groups work when text is justified
function(df, which_side = "right", side_norm = "right_norm") 
{
    side = table( df[[side_norm]] )
    
    # more common indentation value
    value = names( which.max( side ) )
    
    side_tf = 
        if( which_side == "right" ) {
            side = as.integer( df[[side_norm]] == value ) 
            side + c( 0, side[-length(side)] ) == 2
        } else {
            side = as.integer( df[[side_norm]] != value ) 
            side + c( side[-1], 0 ) == 2
        }
    
    side[ side_tf ] = 0
    setNames( list( side, cumsum( side ) + 1 ), c("tf", "group") )
}

get_citation_group = 
    # currently finds citation groups by a numbered list
    # split on groups and combine all text for each group
function( df, method ) 
{
    # if method not in supported list, issue warning and use default
    all_methods = c( "numbered", "bulleted", "left", "right" )
    if( !(method %in% all_methods) ) {
        warn_message = sprintf( "Methods supported are: %s. Using default method = numbered.", 
                                paste( all_methods, collapse = ", " ))
        warning( warn_message )
        method = "numbered"
    }
    
    split_group = 
    if( method == "numbered" ) {
        df$numbered_list
    } else if( method == "bulleted" ) {
        df$bulleted_list
    } else if( method == "left" ) {
        df$left_group
    } else if( method == "right" ) {
        df$right_group
    } 
    
    split_group
}

combine_citations = 
    # INPUT: 
    #   - character vector of citation strings
    #   - groupings for citation text
    #
    # OUTPUT: citation strings combined into groups 
function( citation_text, groups ) 
{
    # split on groups and combine all text for each group
    text_groups = split( citation_text, groups )
    citations = sapply( text_groups, function(group) paste( group, collapse = " " ) )
    
    # some lines end with "-" for continuing a word and should be removed, other times the hyphen 
    # is supposed to be there. The below code attempts to fix this issue
    rx = "([[:alpha:]])- ([[:alpha:]])"
    citations = gsub( rx, "\\1\\2", citations )
    
    rx = "([[:digit:]])- ([[:digit:]])"
    citations = gsub( rx, "\\1-\\2", citations )
    
    # if citations are too long or short, remove
    cite_length = nchar( citations )
    mask = cite_length > 85 & cite_length < 375
    
    citations[mask]
}

keep_values_between = 
    # INPUT: logical vector with 1 or 2 TRUE values
    # OUTPUT: logical vector with all TRUE values between the original two
function(tf)
{
    tf = cumsum(tf)
    tf[ tf > 1 ] = 0
    
    # remove first TRUE value
    tf[ which.max(tf) ] = 0
    as.logical(tf)
}

groups_by_period = 
    # group by text ending with a period
function(period)
{
    period = as.integer(period)

    count = 1
    group = 1
    groups = NULL
    for( p in period ) {
        if( p == 0 ) {
            count = count + 1
        } else {
            groups = c( groups, rep(group, count) )
            group = group + 1
            count = 1
        }
    }
    c( groups, rep(group, count - 1) )
}

get_citation_textbox = 
    # first attempt to fix line breaks, combine lines so they end with a period
function( filename_xml, start_section, end_section )
{
    # for testing
    if( FALSE ) {
        filename_xml = "~/Dropbox/GSR/CV_examples/CV_XML/cv_amir.xml"
        filename_xml = "~/Dropbox/GSR/CV_examples/CV_XML/CVTsoukiasweb.xml"
        start_section = starting_section
        end_section = next_section
    }
    
    doc = xmlParse(filename_xml)
    
    textbox = xpathSApply(doc, "//textbox", xmlValue )
    
    # clean data in the same fashion as section names
    text_tf = fix_group_text( tolower(textbox) ) %in% c(start_section, end_section)
    text_tf = keep_values_between( text_tf )
    
    citation_text = textbox[ text_tf ]
    
    # remove blank lines
    citation_text = citation_text[ nchar(citation_text) > 0 ]
    
    tf = grepl( "\\.$", citation_text )
    
    split_group = groups_by_period(tf)
    combine_citations( citation_text, split_group )
}


start_end_section = 
    # INPUT: 
    #   - text: all lines of text in CV
    #   - found_sections: character vector of section names (or NULL is none found)
    #   - pub_reg: regular expression for finding publication section
    #   - other_reg: regular expression for finding sections not publication
    # 
    # OUTPUT: 4 element list: "start_index", "start_section", "end_index", "end_section"
    #   - start_section will be a publication section
    #   - end_section will be the next section after publication
    #   - start_index, index of first line of text after start_section
    #   - end_index, index of last line of text before end_section
    #
    # DOC: if we found sections, we identify the publication section and next section
    # if no sections found, we walk through the text of CV and look for lines
    # that start with something like "publications." We then identify the next
    # section for looking for lines that begin with "any other section name."
function( text, found_sections, pub_reg, other_reg )
{

    # index location of the publication section
    index = grep( pub_reg, found_sections )
    
    start_index = which( text == found_sections[index] ) + 1
    
    # either we take the next section, or publications is the last section
    # and we extract all text until the end of document
    end_index = 
        if( index == length(found_sections) ) {
            length(text)
        } else {
            which( text == found_sections[index + 1] ) - 1
        }
    
    # also get the actual section names
    start_section = found_sections[ index ]
    end_section = 
        if( index == length(found_sections) ) {
            NULL
        } else {
            found_sections[index + 1]
        }
    
    list_names = c( "start_index", "start_section", "end_index", "end_section" )
    setNames( list( start_index, start_section, end_index, end_section ), list_names )
}

start_end_no_section = 
    # see start_end_section()
    # use if no sections found
function( text, pub_reg, other_reg )
{
    get_index_name = 
    function(text, mask, start = TRUE)
    {
        if( start ) {
            list_names = c( "start_index", "start_section" )
            add_term = 1
        } else {
            list_names = c( "end_index", "end_section" )
            add_term = -1
        } 
        
        if( sum(mask) > 0 ) {
            index = which.max( mask ) + add_term
            section = text[ index + (-1) * add_term ]
        } else {
            index = NULL
            section = NULL
        }
        setNames( list(index, section), list_names )
    }

    mask_pub = grepl( paste0("^", pub_reg), text )
    
    start = get_index_name( text, mask_pub, TRUE )
    
    # skipping index location of publications
    mask_pub = as.logical( cumsum( mask_pub ) )
    mask_pub[ start_index - 1 ] = FALSE
    
    # get first section that appears after publication
    other_mask = grepl( paste0("^", other_reg), text )
    other_mask = other_mask & mask_pub

    end = get_index_name( text, other_mask, FALSE )
    
    c( start, end )
}
    

get_section_locations = 
function( text, found_sections, pub_filename, section_filename )
{
    # build regular expression from character vector of section names
    create_reg = function(vect) {
        vect = paste( vect, collapse = "|")
        sprintf( "(%s)", vect )
    }
    
    # for testing
    if( FALSE ) {
        text = df$text
        found_sections = output[[2]]
        pub_filename = "~/Dropbox/GSR/parse_citations/text_files/publications.txt"
        section_filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt"
    }
    
    # sections found for publication section
    pub_sections = readLines( pub_filename )
    pub_reg = create_reg( pub_sections )
    
    # sections found for everything but publication section
    other_sections = readLines( section_filename )
    other_reg = create_reg( other_sections )
    
    text = fix_group_text( tolower(df$text) )
    
    name_index =
    if( length(found_sections) != 0 ) {
        start_end_section( text, found_sections, pub_reg, other_reg )
    } else {
        start_end_no_section( text, pub_reg, other_reg )
    }
    
    name_index
}

get_citations_helper = 
    # gets potential citation groups using:
    #   - numbered list ( all that works currently )
    #   - bulleted list ( to do )
    #   - left indentation
    #   - right indentation
    #   - textbox ( to do )
    # method can be: numbered, bulleted, left, right, textbox
    #
    # Notes on textbox: issues with pages and not capturing whole citation, we can look at line 
    # lengths to see where textboxs went wrong.
function( df, method = "numbered" ) 
{
    # groups for left / right indentation
    right = right_left_groups( df )
    left = right_left_groups( df, "left", "left_norm" )
    
    df$right_side = right$tf
    df$right_group = right$group
    df$left_side = left$tf
    df$left_group = left$group
    
    # get the group to split on and combine citations by that grouping
    split_group = get_citation_group( df, method )
    combine_citations( df$text, split_group )
}

get_citations = 
    # INPUT: 
    #   - filename of xml 
    #   - data.frame
    # 
    # DOC:
    #   - search for numbered list,
    #   - then by textbox,
    #   - then by left indentation
function( filename, df, name_index, pass = 1 )
{
    # for testing
    if( FALSE ) {
        filename = cv_filename
        df = df_text
    }
    
    print( sprintf( "Citation Pass: %s", pass ) )
    # couldn't extract any citations
    if( pass == 4 ) return( NULL )
    
    citations = 
    if( pass == 1 ) {
        # groups for numbered list
        text = df$text
        nums = find_sequence( extract_numbered_list( text ) )
        
        # assume we don't have numbered list in this case
        if( length(nums) < 4 ) return( get_citations(filename, df, name_index, pass + 1 ) )
        
        df$numbered_list = tf_numbered_list( text, nums )
        
        get_citations_helper( df, "numbered" )
    } else if( pass == 2 ) {
        get_citation_textbox( filename, name_index$start_section, name_index$end_section )
    } else if( pass == 3 ) {
        get_citations_helper( df, "left" )
    }
    
    # we didn't find any
    if( length(citations) < 3 ) {
        get_citations(filename, df, name_index, pass + 1 ) 
    }
    
    citations
}

main = 
function( cv_filename, pub_filename, section_filename,
          print_text = FALSE)
{
    # for testing
    if( FALSE ) {
        cv_filename = "~/Dropbox/GSR/CV_examples/CV_XML/JBLucks_CV_Cornell_2015_Web1.xml"
        cv_filename = "~/Dropbox/GSR/CV_examples/CV_XML/CVTsoukiasweb.xml"
        pub_filename = "~/Dropbox/GSR/parse_citations/text_files/publications.txt"
        section_filename = "~/Dropbox/GSR/parse_citations/text_files/section_names.txt"
    }
    
    output = parse_cv( cv_filename, short_text = FALSE )
    df = output[[1]]
    found_sections = output[[2]]
    
    # contains: "start_index", "start_section", "end_index", "end_section"
    name_index = get_section_locations( df$text, found_sections, pub_filename, section_filename )
    
    df_text = df[ name_index$start_index : name_index$end_index, c("left_norm", "right_norm", "text")]
    
    if( print_text ) {
        # print first 10 citation lines
        print( df_text$text[1:10] )
    }
    
    citations = get_citations( cv_filename, df_text, name_index )
    
    citations = trim( citations )
    
    # extract doi and year (if they appear in citation)
    doi = get_doi( citations )
    year = get_year( citations )
    
    # make citations begin with a letter (remove numbering)
    citations = str_extract( citations, "[[:alpha:]].*" )
    
    # n = 72
    # subset = c(18, 37, 38, 49, 54)
    # subset = 1:n
    # citations[subset]
    # doi[subset]
    # year[subset]
    # found_citations = query_crossref( citations[subset], doi[subset], year[subset] )
    
    found_citations = query_crossref( citations, doi, year ) 
}

####################
# Testing the Code #  
####################

# still need to fix for this CV
# file = "~/Dropbox/GSR/CV_examples/CV_XML/CVTsoukiasweb.xml"

# file = "~/Dropbox/GSR/CV_examples/CV_XML/cv_amir.xml"
file = "~/Dropbox/GSR/CV_examples/CV_XML/JBLucks_CV_Cornell_2015_Web1.xml"
# file = "~/Dropbox/GSR/CV_examples/CV_XML/Mulhearn_CV.xml"

output = parse_cv( file, short_text = FALSE )

df = output[[1]]
found_sections = output[[2]]

# sections found for publication section
pub_sections = readLines( "~/Dropbox/GSR/parse_citations/text_files/publications.txt" )
reg = paste( pub_sections, collapse = "|")

# index location of the publication section
index = grep( reg, found_sections )

text = fix_group_text( tolower(df$text) )
start_index = which( text == found_sections[index] ) + 1

# either we take the next section, or publications is the last section
# and we extract all text until the end of document
end_index = 
    if( index == length(found_sections) ) {
        length(text)
    } else {
        which( text == found_sections[index + 1] ) - 1
    }

# all citation text
text = df[start_index:end_index, ]$text
text[1:10]

# group citations, currently by numbered list
df_text = df[start_index:end_index, c("left_norm", "right_norm", "text")]
citations = get_citations(df_text, "numbered")

# get citations using textbox from XML
if( TRUE ) {
    starting_section = grep( reg, found_sections, value = TRUE )
    next_section = 
        if( index == length(found_sections) ) {
            NULL
        } else {
            found_sections[index + 1]
        }
    
    citations = get_citation_textbox( file, starting_section, next_section )
    
    # will most likely happen if textbox doesn't put section title on it's own line
    if( length(citations) == 0 ) {
        warn_message = "No citations found, another method needed"
        warning( warn_message )
    }
}

citations = trim( citations )

# extract doi and year (if they appear in citation)
doi = get_doi( citations )
year = get_year( citations )

# make citations begin with a letter (remove numbering)
citations = str_extract( citations, "[[:alpha:]].*" )

# n = 72
# subset = c(18, 37, 38, 49, 54)
# subset = 1:n
# citations[subset]
# doi[subset]
# year[subset]
# found_citations = query_crossref( citations[subset], doi[subset], year[subset] )

found_citations = query_crossref( citations, doi, year )

# removing these columns for display only
col_names = c("original_citation", "fullCitation", "authors", "title")
found_citations[ c(col_names, "title_score") ]
found_citations[, !names(found_citations) %in% col_names]
found_citations

# strange examples:
"../../CV_examples/CV_XML/CV_Behler_2015_LaTex.xml" # columns
"../../CV_examples/CV_XML/rubincv.xml" # columns
"../../CV_examples/CV_XML/Resume-8-2015.xml" # centered titles
"../../CV_examples/CV_XML/CV_-_Whooley_updated_2015_apps.xml" # centered titles and spaces between every other letter in sections
"../../CV_examples/CV_XML/CV_Shi.xml" # has a thin line, need to investigate how to detect this
"../../CV_examples/CV_XML/CV_-_Berry_2015.xml" # also uses lines

# Notes:
#
# make prob higher for selecting a group (with contain sections)
#
#

# How to find citations:
# - numbered list
# - if no numbers found, use textbox
# - if textbox returns zero results use left indentation
#
#
# fix function using periods to find end of citation, use most common character, example ends with [# citation] 
# break code into seperate files
