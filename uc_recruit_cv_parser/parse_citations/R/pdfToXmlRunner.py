import os
import sys
dir = os.getcwd()



def main():
  if(len(sys.argv)<2):
    print("Syntax: python pdfToXmlRunner.py pathToPDFFilesParentDirectory")
  elif(len(sys.argv)==2):
      os.system("Rscript pdf_to_xml_runner.R"+ " "+ dir+ " "+sys.argv[1])



  #os.system("Rscript mainRunner.R"+ " "+ dir+ "")



if __name__ == '__main__':
  main()
