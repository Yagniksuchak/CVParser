# sql directory overview

----
## Application

* **App.sql** 

> create Application_Level\_draft table

* **Extract_AppFile.sql** 

>create Application_Files\_draft table

* **Add_appfile\_rev2.sql**

>create final.appfile table (info of required application files) to merge into main recruitment level table

----
## Recruitment

* **Diversity_data.sql**

> create seperate diversity table 

* **Extract_adDocument.sql**

> extract adDocument information for selected job number listed in profrecruit_jobnumber.xlsx

* **Extract_Committee.sql**

> create seperate committee table

* **Job_rev4.sql**

> create main recruitment level table

* **Extract_UCB\_CV\_STEM\_sample.sql**

> script for creating first round random CV sample pool

