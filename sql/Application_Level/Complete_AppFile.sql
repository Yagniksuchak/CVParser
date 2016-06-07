/*This code is used to link upload files with applicants and applications informations*/

USE ucrecruit;

DROP TABLE IF EXISTS mywork.application_files, mywork.application_files1, mywork.application_files2;

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
/*Subset upload files to applications type*/
/*Only include application files except reference letters*/
CREATE TABLE mywork.application_files SELECT * FROM uploaded_files WHERE type='ApplicationFile' and resource_type ='Application';

/*Join upload file table with applications table*/
CREATE TABLE mywork.application_files1 SELECT a.*, b.applicant_id, b.position_id, b.application_status_id 
FROM mywork.application_files as a LEFT JOIN applications as b 
on a.resource_id = b.id
order by resource_id;
/*Drop unwantted columns and change column names and orders */
ALTER TABLE mywork.application_files1 DROP id, DROP application_id, CHANGE resource_id application_id INT;
ALTER TABLE mywork.application_files1 MODIFY application_id INT FIRST, 
MODIFY applicant_id INT AFTER application_id,
MODIFY application_status_id INT AFTER applicant_id,  
MODIFY position_id INT AFTER application_status_id;  


/*Only keep complete application upload files by joining application_statuses table*/
/*
CREATE TABLE mywork.complete_appfile SELECT a.*, b.name as status, b.description as status_description 
FROM mywork.application_files1 as a LEFT JOIN application_statuses as b
on a.application_status_id = b.id
where a.application_status_id not in (13,27); 
/*
/*SELECT * FROM ucrecruit.application_statuses;*/
/* Below is copied from ucrecruit training system
Recommend for interview: Applicant recommended for interview  (short list)
Interviewed: Applicant has been interviewed
Proposed candidate: Applicant recommended for appointment
Offered: Approvals have been obtained and a formal offer has been made to the applicant
Accepted offer: Approvals have been obtained and a formal offer has been accepted by the applicant
Declined offer: Approvals have been obtained and a formal offer has been declined by the applicant
Hired: Applicant entered in payroll system in searched title
Withdrawn: Applicant has withdrawn themselves from consideration
*/

/*Change column orders*/
/*
ALTER TABLE mywork.complete_appfile MODIFY status VARCHAR(255) AFTER application_status_id,
MODIFY status_description VARCHAR(255) AFTER status;
*/

/*Use application_file_types table to find cv
application_file_type_id=id in application_file_types and position_id*/
/*Add upload file type for application */
CREATE TABLE mywork.application_files2 SELECT a.*, b.name as file_type 
FROM mywork.application_files1 as a LEFT JOIN application_file_types as b
on a.application_file_type_id=b.id and a.position_id=b.position_id;


/*
CREATE TABLE mywork.complete_appfile_1 SELECT a.*, b.name as file_type 
FROM mywork.complete_appfile as a LEFT JOIN application_file_types as b
on a.application_file_type_id=b.id and a.position_id=b.position_id
where b.file_type = 'application';
*/

/*Merge it with applicants table to have applicants information, ie person names*/

/*Add job number column from recruitments table*/
CREATE TABLE mywork.application_file3 SELECT a.*, c.job_number
FROM mywork.application_files2 AS a 
LEFT JOIN positions AS b ON a.position_id = b.id
LEFT JOIN recruitments AS c on b.recruitment_id = c.id;
ALTER TABLE mywork.application_file3 MODIFY job_number VARCHAR(32) AFTER position_id;

