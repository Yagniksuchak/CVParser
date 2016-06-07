from pyPdf import PdfFileReader
import os
import pandas


INPUT_DIRECTORY = "/Users/gsr/Documents/SampledCVs/sample_all/"
fptr = open('metadata.csv','w')
fptr.write("FileName,Title,Creator\n")


def getMetaData(filepath):
    pdf_toread = PdfFileReader(open(filepath, "rb"))
    pdf_info = pdf_toread.getDocumentInfo()
    if pdf_info!=None and '/Title' in pdf_info and '/Creator' in pdf_info:
        dumpString = os.path.basename(filepath)+"," + (pdf_info['/Title'])+","+(pdf_info['/Creator'])
        fptr.write((dumpString+"\n").encode('ascii', 'ignore'))
    else:
        fptr.write(os.path.basename(filepath)+"\n")



for dir in os.listdir(INPUT_DIRECTORY):
    path= os.path.join(INPUT_DIRECTORY,dir)
    if(path.endswith(".pdf")):
        # print path
        getMetaData(path)

