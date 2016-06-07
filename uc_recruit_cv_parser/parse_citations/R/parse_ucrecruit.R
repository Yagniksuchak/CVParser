# This code is used for processing all UC Recruit CVs. It loops over the
# directories for each university and processes all PDF / XML files.

rm(list = ls())
#setwd("~/Dropbox/GSR/parse_citations/R/")
setwd("./")

source("pdf_to_xml.R")
source("parse_citations.R")
source("extract_sections.R")
source("extract_citations.R")

######################
# Convert PDF to XML #
######################

original_pdf_folders = 
    # INPUT: vectors of folder names
    # OUTPUT: those folder which contain pdfs
    # DOC: use option end_xml = TRUE to return "_xml" folders instead
function( folders, end_xml = FALSE )
{
    end_in_xml = grepl( "_xml$", folders )
    starts_with_uc = grepl( "^ucrecruit_", folders )
    
    # keep those that start with ucrecruit_ and don't end with _xml
    original = starts_with_uc & !end_in_xml
    
    mask = 
    if( end_xml ) {
        end_in_xml
    } else {
        original
    }
    
    folders[ mask ]
}

call_pdf_to_xml = 
    # wrapper for all pdf_to_xml() and processing all UC Recruit pdfs
function( dir = "~/Documents/cv" )
{
    university = list.files( dir )
    university = original_pdf_folders( university )
    
    tmp = lapply( university, function( uni ) {
        print( uni )
        
        input_dir = file.path( dir, uni )
        output_dir = paste0( "../", uni, "_xml" )
        
        pdf_to_xml( input_dir, output_dir, via_cmd = TRUE )
    } )
    
    NULL
}

#######################
# Extracting sections #
#######################


call_parse_cv = 
    # wrapper for all parse_cv() and extracting all sections from XML
function( dir = "~/Documents/cv" ) 
{
    university = list.files( dir, full.names = TRUE )
    university = original_pdf_folders( university, end_xml = TRUE )
    
    tmp = lapply( university, function( uni_path ) {
        print( uni_path )
        
        filenames = list.files( uni_path, pattern = "\\.xml$", full.names = TRUE )

        total = 1
        count = 1
        error_count = 1
        section_length = list()
        
        start = proc.time()
        for( f in filenames ) {
            
            # printing progress
            if( ( total %% 500 ) == 0 ) {
                tmp = sprintf( "count: %s, perc.: %s", count, count / total )
                print( tmp )
                print( sprintf( "error count: %s", error_count ) )
                print( ( proc.time() - start ) / 60 )
                hist( unlist( section_length ) )
            }
            
            output = try( parse_cv( f ), silent = TRUE)
            
            if( class(output) != "try-error" ) {
                n = length( output[[2]] )
            } else {
                # on error save filename
                e_filename = "~/Dropbox/GSR/parse_citations/text_files/section_errors.txt"
                write( f, file = e_filename, sep = "\n", append = TRUE )
                error_count = error_count + 1
            }
            
            if( n > 3 ) count = count + 1
            section_length[[ total ]] = n
            
            total = total + 1
        }
    } )
}

convert_filename = 
    # convert the .xml filename and path back to the original .pdf
function( xml_filename )
{
    gsub( "(.*?ucrecruit_uc[[:lower:]]{1,2})_xml(.*)\\.xml", "\\1\\2.pdf", xml_filename  )
}

explore_section_errors = 
    # INPUT: path to section error log file
    # DOC: explore CVs which caused error with call_parse_cv() and hence
    #   no sections were extracted
function( filename = "~/Dropbox/GSR/parse_citations/text_files/section_errors.txt" )
{
    if( FALSE )
        filename = "~/Dropbox/GSR/parse_citations/text_files/section_errors.txt"
    
    files_to_explore = readLines( filename )
    
    # likely need to explore these one by one and hope many have the same issues
    file = files_to_explore[[5]]

    # we know this won't work, run to see the error and explore
    parse_cv( file )
}

#######################
# Extracting sections #
#######################

# Process all citations section of cv_parse.Rmd for outline of how code will look

####################
# Running the code #
####################

call_pdf_to_xml()

# call_parse_cv()

# Results from extracting sections from "~/Documents/cv/ucrecruit_ucb_xml/"
# using call_parse_cv()
# -------------------------------------------------------------------------
# total files: 45606
# found citation count: 38880, percent: 0.853
# error count: 1173
# time: 2.7 hours
# look at number_of_sections.png for histogram of the number of sections extracted from each CV
