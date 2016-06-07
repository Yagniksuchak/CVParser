# enable arguments from command line
args = commandArgs( trailingOnly = TRUE )

#source("pdf_to_xml.R") 

script_path = ( args[1] )
setwd(script_path)

xml_directory_path = args[2]
cv_names_text_file_path = args[3]
source("extract_citations.R")
source("extract_sections.R") 

mainRunner = function(xml_files,cv_names){
        if(length(xml_files)!=length(cv_names)){
                stop("length of xml_files and cv_names should be same!!")
        }
        
        pub_filename=file.path(dirname(getwd()),"text_files/publications.txt")
        section_filename=file.path(dirname(getwd()),"text_files/section_names.txt")
        file.path(dirname(dirname(getwd())),"text_files/section_names.txt")
        
        start = proc.time()
        df=mapply(function(files,cvNames){
                df=main(files,cvNames,pub_filename,section_filename,log_file=TRUE,fileLevelTest=TRUE)
                df=data.frame(df)
        },xml_files,cv_names,SIMPLIFY = FALSE)
        
        df = rbind.fill(df)
        rownames(df)=NULL
        
        
        proc.time() - start
        
}

if(!is.na(xml_directory_path) && !is.na(cv_names_text_file_path)){
        xml_files = list.files(xml_directory_path,full.names = TRUE)
        cv_names = readLines(cv_names_text_file_path)
        mainRunner(xml_files,cv_names)
} else{
        
        print("Syntax: Rscript mainRunner.R script_path xml_directory_path cv_names_text_file_path")
}

# xml_files = list.files("/Users/gsr/Documents/SampledCVs/sample_all_xml",full.names = TRUE)
# cv_names_file = "/Users/gsr/Documents/SampledCVs/sample_all_names.txt"
# cv_names=readLines(cv_names_file)
# mainRunner(xml_files,cv_names)
# xml_files = list.files("/Users/gsr/Documents/SampledCVs/regressionTestingDir/sample_all_xml",full.names = TRUE)
# cv_names = readLines("/Users/gsr/Documents/SampledCVs/sample_all_names.txt")
# mainRunner(xml_files, cv_names)
