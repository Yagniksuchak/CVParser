/*Only use ucb data*/
USE ucrecruit_ucb;

/*Only include application files no reference at this point of time*/
CREATE TABLE mywork.app_file_ucb0 SELECT * FROM uploaded_files WHERE type='ApplicationFile' AND resource_type ='Application';


/*Join upload file table with applications table*/
CREATE TABLE mywork.app_file_ucb1 SELECT a.*, b.applicant_id, b.position_id, b.application_status_id 
FROM mywork.app_file_ucb0 as a 
LEFT JOIN applications as b on a.resource_id = b.id 
order by resource_id;

SELECT * FROM mywork.app_file_ucb2;
/*Drop unwantted columns and change column names and orders */
ALTER TABLE mywork.app_file_ucb1 DROP id, DROP application_id, CHANGE resource_id application_id INT;
ALTER TABLE mywork.app_file_ucb1 MODIFY application_id INT FIRST, 
MODIFY applicant_id INT AFTER application_id,
MODIFY application_status_id INT AFTER applicant_id,  
MODIFY position_id INT AFTER application_status_id;  

/*Use application_file_types table to add upload file types*/
CREATE TABLE mywork.app_file_ucb2 SELECT a.*, b.name as file_type 
FROM mywork.app_file_ucb1 as a LEFT JOIN application_file_types as b
on a.application_file_type_id=b.id and a.position_id=b.position_id;

/*Only include cv*/
CREATE TABLE mywork.app_file_ucb3 SELECT * FROM mywork.app_file_ucb2 WHERE file_type in 
(SELECT DISTINCT file_type FROM mywork.app_file_ucb2 WHERE lower(file_type) LIKE '%cv%' or lower(file_type) LIKE '%resume%' 
or lower(file_type) LIKE '%curriculum%');

DROP TABLE IF EXISTS  mywork.app_file_ucb4;
/*Add job number, year, recruitment column from recruitments table*/
CREATE TABLE  mywork.app_file_ucb4 SELECT a.*, c.job_number, c.academic_year_id, b.recruitment_id
FROM  mywork.app_file_ucb3 AS a 
LEFT JOIN positions AS b ON a.position_id = b.id
LEFT JOIN recruitments AS c on b.recruitment_id = c.id;

/*Only include STEM application*/
CREATE TABLE mywork.app_file_ucb5 SELECT A.*, B.department_name
FROM mywork.app_file_ucb4 A 
INNER JOIN 
(
/*Add department name*/
SELECT A.*, B.DEPARTMENT_NAME FROM
/*May need to depulicate listings later*/
/*Only include STEM listings*/
(SELECT recruitment_id, department_id FROM listings where  department_id in (SELECT id FROM mywork.ucb_department)) A
LEFT JOIN mywork.ucb_department B
ON a.department_id=b.id
) B
ON A.recruitment_id = B.recruitment_id;


ALTER TABLE mywork.app_file_ucb5 MODIFY job_number VARCHAR(32) AFTER position_id,
MODIFY recruitment_id INT AFTER job_number,
MODIFY academic_year_id INT AFTER recruitment_id;

SELECT applicant_id, count(*) FROM mywork.app_file_ucb5 group by applicant_id;

SELECT * FROM mywork.app_file_ucb5 where applicant_id=38954;


/*Only include STEM department name for berkeley in file UCOP Departments by CIP and STEM flag.xlsx*/
CREATE TABLE mywork.ucb_department
SELECT a.DEPARTMENT_NAME, b.id
FROM mywork.ucb_department_stem a
LEFT JOIN ucrecruit_ucb.departments b
ON LOWER(b.name) LIKE LOWER(a.DEPARTMENT_NAME);

SELECT * FROM  ucrecruit_ucb.departments where name like '%energy%';
/*Manually fix some mismatching id*/
UPDATE mywork.ucb_department 
SET id =42  WHERE DEPARTMENT_NAME='AGRICULTURAL & RESOURCE ECON';
UPDATE mywork.ucb_department 
SET id =65  WHERE DEPARTMENT_NAME='CHEMICAL ENGINEERING';
UPDATE mywork.ucb_department 
SET id =44  WHERE DEPARTMENT_NAME='CHEMISTRY';
UPDATE mywork.ucb_department 
SET id =71  WHERE DEPARTMENT_NAME='CIVIL & ENVIRONMENTAL ENGINEERING';
UPDATE mywork.ucb_department 
SET id =202  WHERE DEPARTMENT_NAME='ELEC ENGR & COMPUTER SCI';
UPDATE mywork.ucb_department 
SET id =16  WHERE DEPARTMENT_NAME='ENERGY & RESOURCES GROUP';
UPDATE mywork.ucb_department 
SET id =136  WHERE DEPARTMENT_NAME='ENVIRONMENTAL SCI, POLICY & MGMT';
UPDATE mywork.ucb_department 
SET id =132  WHERE DEPARTMENT_NAME='INDUSTRIAL ENG & OPERATIONS RSRCH';
UPDATE mywork.ucb_department 
SET id =89  WHERE DEPARTMENT_NAME='MATERIALS SCIENCE & ENGINEERING';
UPDATE mywork.ucb_department 
SET id =153  WHERE DEPARTMENT_NAME='NUTRITIONAL SCI & TOXICOLOGY';

SELECT * FROM mywork.ucb_department;

/*Subset critrion*/
SELECT * FROM mywork.ucb_department;
SELECT DISTINCT file_type FROM mywork.app_file_ucb2 WHERE lower(file_type) LIKE '%cv%' or lower(file_type) LIKE '%resume%' 
or lower(file_type) LIKE '%curriculum%';
