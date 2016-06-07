setwd("~/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/R")
source("pdf_to_xml.R") 
source("parse_citations.R") 
source("extract_sections.R") 
source("extract_citations.R")
library(plyr)




#To test the xmlParsing
cv_filename=filename="~/Documents/cvTest/testUniversity_xml/cv_amir.xml"
cv_name = "aghakouchak"
doc=xmlParse(filename)
doc
#############################


#To intialize the publication file and section file name
pub_filename="~/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/publications.txt"
section_filename="~/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/section_names.txt"
####################################################


#Initial test set
xml_files=list.files("/Users/gsr/Documents/cvTest/testUniversity_xml",full.names=TRUE)
cv_names= c("aghakouchak","tsoukias","lucks","mulhearn")


#First set of 65 CVs
xml_files = list.files("/Users/gsr/Documents//ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML", full.names = TRUE)
cv_names_file = "/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/text_files/cv_names.txt"
cv_names=readLines(cv_names_file)
##################################################

#Second set of CVs. Tag: sample_all_xml
xml_files = list.files("/Users/gsr/Documents/SampledCVs/sample_all_xml",full.names = TRUE)
cv_names_file = "/Users/gsr/Documents/SampledCVs/sample_all_names.txt"
cv_names=readLines(cv_names_file)
##################################################


xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Rajat_CV_21st_November_2014.xml"
cv_names="Mazumder"

xml_files=list.files("/Users/gsr/Documents/cvTest/testUniversity_xml",full.names=TRUE)
cv_names= c("AghaKouchak","Weber")


xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/Curriculum_Vitae_Ori_Swed.xml"
cv_names="swed"

xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/CV_Cohen___September_2015.xml"
cv_names="cohen"

xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/CV.xml"
cv_names="stevens"

xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/Mulhearn_CV.xml"
cv_names="mulhearn"

xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/JBLucks_CV_Cornell_2015_Web1.xml"
cv_names="lucks"

#Need to debug following cv. Probably problem with parsing xml
xml_files = "/Users/gsr/Documents/SampledCVs/Weber_Karen_CV_CFSC_020614.xml"
cv_names="weber"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/BDoll_CV.xml"
cv_names="doll"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/CBCVDec_2013.xml"
cv_names="brumwell"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/cv_Ran_Budnik_Nov2012_ac.xml"
cv_names="budnik"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/CV_Subhojit_Das_IITG_INDIA.xml"
cv_names="das"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Cv-_Raghavendra_Nunna.xml"
cv_names="nunna"


xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/anat_cv_t.xml"
cv_names="natarajan"

xml_files="~/Documents/cvTest/testUniversity_xml/cv_amir.xml"
cv_names="aghakouchak"


xml_files="~/Documents/cvTest/testUniversity_xml/CV___refe.xml"
cv_names="wang"

xml_files="~/Documents/cvTest/testUniversity_xml/CV__10102014_.xml"
cv_names="lee"

xml_files="~/Documents/cvTest/testUniversity_xml/fanidakis_cv.xml"
cv_names="Fanidakis"

xml_files="~/Documents/cvTest/testUniversity_xml/GGLoots_CV2012.xml"
cv_names="Loots"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Alabi_CV_2012_Berkeley.xml"
cv_names="alabi"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/GGLoots_CV2012.xml"
cv_names="Loots"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Kemkes_CV.xml"
cv_names="kemkes"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Poffenroth_CV_May_2015.xml"
cv_names="Poffenroth"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Resume_CivilEngineering_2014-10-7.xml"
cv_names="zhou"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Siddiqi_CV_2013-11-15.xml"
cv_names="SIDDIQI"

xml_files="/Users/gsr/Documents/ucrecruit/uc_recruit_cv_parser/CV_examples/CV_XML/CV (2).xml"
cv_names = "BANERJEE"


xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Berteletti-CV_10_11_14.xml"
cv_names = "Berteletti"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Jill_Bronfman.xml"
cv_names = "Bronfman"

xml_files="/Users/gsr/Documents/SampledCVs/sample_all_xml/Tola_CV_-_November_2013.xml"
cv_names = "tola"

xml_files=list.files("/Users/gsr/Documents/SampledCVs/regressionTestingDir/testUni_xml",full.names=TRUE)
cv_names = c("Lee","Fanidakis")
#fileLevelDF = data.frame(FileName=character(),StartSection=character(),EndSection=character(),NumOfPublication=character(),stringsAsFactors=FALSE)

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

mainRunner(xml_files,cv_names)



dir="/Users/gsr/Documents/SampledCVs"

pdf_to_xml_runner = function(dir="/Users/gsr/Documents/SampledCVs"){
#dir = "/Users/gsr/Documents/cvTest"
university = list.files( dir )[3]
input_dir = file.path( dir, university )
input_dir
output_dir = paste0( "../", university, "_xml" )
output_dir
#CHANGE THE FLAG TO TRUE

pdf_to_xml( input_dir, output_dir, via_cmd = TRUE )
}


pdf_to_xml_runner("/Users/gsr/Documents/SampledCVs/regressionTestingDir")
#write(c("a","b","c"),"fileLevelTestOutput.csv",append = TRUE)
#query_crossref("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890",NULL,NULL,cv_name="random")
