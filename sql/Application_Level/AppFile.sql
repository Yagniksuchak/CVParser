/*This code is used to link upload files(reference letter and application file) with applicants and applications informations*/


USE mywork;
DROP TABLE IF EXISTS application_files1, application_files2, application_files3, 
application_files4, application_files5, application_files6;

USE ucrecruit;

/******************Section 1******************/
/*Start some checking */
SELECT distinct resource_type FROM uploaded_files;

SELECT * FROM applications;

SELECT * FROM applicants;
/*Find anything has status*/
SELECT DISTINCT COLUMN_NAME, COLUMN_TYPE, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%Status%' OR TABLE_NAME LIKE '%Status%') AND TABLE_SCHEMA=DATABASE()
ORDER BY TABLE_NAME;


/******************Section 2******************/
/*
UPDATE
    FirstTable
    JOIN SecondTable ON FirstTable.ItemID = SecondTable.ItemID
SET
    FirstTable.Description = SecondTable.LongerDescription;
*/
/*Subset upload files to applications files of reference letters*/
CREATE TABLE mywork.application_files1 SELECT * FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Reference';
UPDATE mywork.application_files1 AS a JOIN referrals AS b ON a.resource_id = b.id
SET a.resource_id = b.application_id ;

/*Subset upload files to other applications files */
CREATE TABLE mywork.application_files2 SELECT * FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Application';

/*Union reference letters with other application files*/
CREATE TABLE mywork.application_files3 SELECT * FROM mywork.application_files1 UNION ALL SELECT * FROM mywork.application_files2;

/*Join upload file table with applications table*/
CREATE TABLE mywork.application_files4 SELECT a.*, b.applicant_id, b.position_id, b.application_status_id 
FROM mywork.application_files3 as a 
LEFT JOIN applications as b on a.resource_id = b.id 
order by resource_id;

/*Drop unwantted columns and change column names and orders */
ALTER TABLE mywork.application_files4 DROP id, DROP application_id, CHANGE resource_id application_id INT;
ALTER TABLE mywork.application_files4 MODIFY application_id INT FIRST, 
MODIFY applicant_id INT AFTER application_id,
MODIFY application_status_id INT AFTER applicant_id,  
MODIFY position_id INT AFTER application_status_id;  


/*Use application_file_types table to add upload file types*/
CREATE TABLE mywork.application_files5 SELECT a.*, b.name as file_type 
FROM mywork.application_files4 as a LEFT JOIN application_file_types as b
on a.application_file_type_id=b.id and a.position_id=b.position_id;

UPDATE mywork.application_files5 SET file_type='Reference' WHERE resource_type='Reference';


/*Merge it with applicants table to have applicants information, ie person names*/

/*Add job number column from recruitments table*/
CREATE TABLE mywork.application_files6 SELECT a.*, c.job_number
FROM mywork.application_files5 AS a 
LEFT JOIN positions AS b ON a.position_id = b.id
LEFT JOIN recruitments AS c on b.recruitment_id = c.id;
ALTER TABLE mywork.application_files6 MODIFY job_number VARCHAR(32) AFTER position_id;

/*Check one-to-one relationship between application and applicant*/
SELECT COUNT(DISTINCT application_id) AS c, applicant_id FROM mywork.application_files6 GROUP BY applicant_id HAVING c>1;