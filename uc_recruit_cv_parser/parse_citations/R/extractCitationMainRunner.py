import os
import sys
dir = os.getcwd()



def main():
  if(len(sys.argv)<3):
    print("Syntax: python extractCitationMainRunner.py pathToXMLFilesParentDirectory cvNamesTextFile")
  elif(len(sys.argv)==3):
      os.system("Rscript mainRunner.R"+ " "+ dir+ " "+sys.argv[1]+" "+sys.argv[2])



  #os.system("Rscript mainRunner.R"+ " "+ dir+ "")



if __name__ == '__main__':
  main()
