setwd("~/Documents/ucrecruit/uc_recruit_cv_parser/parse_citations/R/testSuite")
dfActual = read.csv("!fileLevelTestcopy.csv")
dfOutput = read.csv("fileLevelTestOutput3.csv")
dfActual$FileName = tolower(dfActual$FileName)
dfOutput$FileName = tolower(dfOutput$FileName)

dfFinal = merge(x = dfActual, y = dfOutput, by = "FileName", all.x = TRUE)
write.csv(dfFinal,"comparision3.csv")

######################################################
