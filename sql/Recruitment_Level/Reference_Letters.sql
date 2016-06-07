
/*Subset upload files to reference letters*/
CREATE TABLE mywork.reference_letters SELECT * FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Reference';

/*Join upload file table with applications table*/
CREATE TABLE mywork.reference_letters1 SELECT a.*, b.applicant_id, b.position_id, b.application_status_id 
FROM mywork.reference_letters as a LEFT JOIN applications as b 
on a.resource_id = b.id
order by resource_id;
/*Drop unwantted columns and change column names and orders */
ALTER TABLE mywork.reference_letters1 DROP id, DROP application_id, CHANGE resource_id application_id INT;
ALTER TABLE mywork.reference_letters1 MODIFY application_id INT FIRST, 
MODIFY applicant_id INT AFTER application_id,
MODIFY application_status_id INT AFTER applicant_id,  
MODIFY position_id INT AFTER application_status_id;  

/*Use application_file_types table to find cv
application_file_type_id=id in application_file_types and position_id*/
/*Add upload file type for application */
CREATE TABLE mywork.application_files2 SELECT a.*, b.name as file_type 
FROM mywork.application_files1 as a LEFT JOIN application_file_types as b
on a.application_file_type_id=b.id and a.position_id=b.position_id;



SELECT DISTINCT type FROM uploaded_files  ;

SELECT DISTINCT COLUMN_NAME, COLUMN_TYPE, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%reference%' OR TABLE_NAME LIKE '%reference%') AND TABLE_SCHEMA=DATABASE()
ORDER BY TABLE_NAME;

SELECT * FROM reference_histories;

SELECT referral_id, COUNT(*) as cnt,email FROM reference_histories GROUP BY referral_id HAVING cnt > 1;