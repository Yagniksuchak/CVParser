# enable arguments from command line
args = commandArgs( trailingOnly = TRUE )

#source("pdf_to_xml.R") 

script_path = ( args[1] )
setwd(script_path)
source("pdf_to_xml.R") 
print(args[2])
#path of the script directory, path of directory.
#dir="/Users/gsr/Documents/SampledCVs/regressionTestingDir"
pdf_to_xml_runner = function(dir="/Users/gsr/Documents/SampledCVs/regressionTestingDir"){
        #dir = "/Users/gsr/Documents/cvTest"
        university = list.files( dir )[1]
        input_dir = file.path( dir, university )
        input_dir
        output_dir = paste0( "../", university, "_xml" )
        output_dir
        #CHANGE THE FLAG TO TRUE
        
        pdf_to_xml( input_dir, output_dir, via_cmd = TRUE )
}
if(!is.na(args[2])){
        pdf_to_xml_runner(args[2])
} else{
        pdf_to_xml_runner()
        #print("Syntax: Rscript pdf_to_xml_runner.R script_path pdfFilesParentPath")
}
#pdf_to_xml_runner()

#pdf_to_xml_runner("/Users/gsr/Documents/SampledCVs/regressionTestingDir")


