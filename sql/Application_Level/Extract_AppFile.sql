#usage: create Application_Files_draft table
#current issue: need to add other campuses

USE ucrecruit;
/*Subset upload files to applications files of reference letters*/
CREATE TABLE mywork.application_files1 
SELECT A.*, B.application_id, B.referral_name FROM
(SELECT 
    created_by_user_id,
    application_file_type_id,
    updated_at,
    created_at,
    description,
    filename,
    content_type,
    size,
    file_content_id,
    resource_type,
    resource_id,
    provided_content_type,
    type,
    ad_source_id,
    cloud_key FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Reference') A
INNER JOIN 
(SELECT id, application_id, name AS referral_name FROM referrals 
WHERE application_id IN (SELECT id FROM mywork.app0)) B
ON A.resource_id = B.id
ORDER BY B.application_id;

ALTER TABLE mywork.application_files1 DROP created_by_user_id, DROP updated_at, 
DROP created_at, DROP resource_id, MODIFY COLUMN application_id INT FIRST;/*DROP resource_type,*/


SELECT * FROM  mywork.application_files4;


/*Subset upload files to other applications files */
CREATE TABLE mywork.application_files2 
SELECT A.* FROM 
(SELECT * FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Application') A
INNER JOIN 
(SELECT id FROM mywork.app0) B
ON A.resource_id = B.id
ORDER BY A.resource_id;

ALTER TABLE mywork.application_files2 DROP id, DROP created_by_user_id, DROP updated_at, 
DROP created_at,/*DROP resource_type,*/DROP application_id, CHANGE resource_id application_id INT FIRST,
ADD referral_name VARCHAR(255);


/*Union reference letters with other application files*/
CREATE TABLE mywork.application_files3 
SELECT * FROM mywork.application_files1 
UNION ALL 
SELECT * FROM mywork.application_files2;


/*Use application_file_types table to add upload file types*/
CREATE TABLE mywork.application_files4 
SELECT A.*, B.NAME AS file_type_name, B.file_type, C.recruitment_id 
FROM mywork.application_files3 AS A
LEFT JOIN application_file_types AS B ON a.application_file_type_id=b.id
LEFT JOIN positions AS C ON B.position_id = C.id
ORDER BY A.application_id;

SELECT * FROM  mywork.application_files4;

ALTER TABLE mywork.application_files4 MODIFY COLUMN recruitment_id INT AFTER application_id, 
MODIFY COLUMN file_type_name varchar(255) AFTER application_file_type_id, MODIFY COLUMN file_type ENUM('APPLICATION','REFERENCE') AFTER file_type_name;

