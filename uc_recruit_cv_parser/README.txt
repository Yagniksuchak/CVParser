uc_recruit_cv_parser directory overview
=======================================

The directory contains the following subdirectories:

* backup - old unused code and notes, can be ignored
* CV_examples - 65 example CVs in PDF format, also contains parsed XML files in the folder CV_XML
* CVRead - Duncan's package / code, more info available here: https://github.com/dsidavis/CVRead
* parse_citations - main code and notes for the project, see additional details below
* presentation_5_examples - high level overview, contains a presentation and related .html file which walks through the strategies used to parse five different example CVs

Lets also go through the subdirectories of the main folder parse_citations:

* images - any plots created in the code will be stored here

* other - some additional helpful resources
    ~ useful_resources.md - list of CV related parsing resources available online
    ~ XML.pdf - a presentation by Duncan for learning XML basics

* R - all the R code
    ~ backup_R folder - old R code, can be ignored
    ~ cv_parse.Rmd / cv_parse.pdf - technical overview of the CV parsing process, shows some sample code, XML output, and results. Includes a sections for "Using with UC Recruit" which shows how to use the code to parse thousands of CVs.
    ~ extract_citations.R - extracts individual citations from the publication section
    ~ extract_sections.R - finds sections from a parsed XML CV
    ~ libraries.R - all libraries needed for all files in this directory
    ~ parse_citations.R - queries crossref API with citation strings
    ~ parse_ucrecruit.R - for running the process on the thousands of UC Recruit CVs
    ~ pdf_to_xml_wrapper.R - called by pdf_to_xml.R to deal with R memory issues
    ~ pdf_to_xml.R - converts PDFs to XML

* ruby - not currently used, but contains ruby code used by anystyle parser which was an early attempt to parse citations. More info available here: http://anystyle.io/

* saved_results - final data.frame results are saved here, in the format found_citations_{date}.RData

* text_files - info kept in text files as well as log files
    ~ citation_output.txt - output captured running the whole parsing process on 65 example CVs
    ~ cv_names.txt - last names of example CVs
    ~ example_citations.txt - example citation strings, used for testing parse_citations.R
    ~ publications.txt - list of found publication section names
    ~ section_errors.txt - error log while parsing UCB XML files for section names
    ~ section_names.txt - list of all found section names (including publications)


Note. This R code relies on pdfminer, which is available here: https://pypi.python.org/pypi/pdfminer/


~/Documents/cv directory overview
=================================

The directory contains the following subdirectories:

* temp_files - temporary files containing input paths to PDFs and output paths for XML. These files are used when R makes a system call to launch a new R session.

* folders of the form ucrecruit_{university} - contain original CVs and we'll process those in .pdf format

* folders of the form ucrecruit_{university}_xml - parsed XML content
    ~ successfully parsed PDFs have the filename {original_filename}.xml
    ~ PDFs we are unable to parse into XML are added to the _error_log.txt error log file
    ~ each ucrecruit_{university}_xml folder contains a separate error log file (i.e. one per university)