SET group_concat_max_len=1500000;

USE uci;
DROP TABLE IF EXISTS descriptions, descriptions1;
USE ucrecruit;

CALL ucrecruit.des_pivot('uci');
SHOW ERRORS;
SELECT * FROM ucla.descriptions;


USE ucrecruit_ucb;

CALL ucrecruit_ucb.des_pivot('ucb');
SHOW ERRORS;

use ucrecruit_ucd;
CALL ucrecruit_ucd.des_pivot('ucd');

use ucrecruit_ucla;
CALL ucrecruit_ucla.des_pivot('ucla');

use ucrecruit_ucm;
CALL ucrecruit_ucm.des_pivot('ucm');

use ucrecruit_ucr;
CALL ucrecruit_ucr.des_pivot('ucr');

use ucrecruit_ucsb;
CALL ucrecruit_ucsb.des_pivot('ucsb');

use ucrecruit_ucsc;
CALL ucrecruit_ucsc.des_pivot('ucsc');

use ucrecruit_ucsd;
CALL ucrecruit_ucsd.des_pivot('ucsd');

use ucrecruit_ucsf;
CALL ucrecruit_ucsf.des_pivot('ucsf');



DROP PROCEDURE IF EXISTS des_pivot;
DELIMITER $$
CREATE PROCEDURE des_pivot(campus_name VARCHAR(15))
BEGIN
SET @db = campus_name;

SET @sql = NULL;
SET @sql = CONCAT("CREATE SCHEMA `" ,@db,"`");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("CREATE TABLE `", @db, "`.descriptions1
SELECT  
  on_id as recruitment_id, 
  GROUP_CONCAT(if(type = 'description', text, NULL)) AS description,
  GROUP_CONCAT(if(type = 'search_effort', text, NULL)) AS search_effort,
  GROUP_CONCAT(if(type = 'approved_search_area', text, NULL)) AS approved_search_area,
  GROUP_CONCAT(if(type = 'basic_qualifications', text, NULL)) AS basic_qualifications,
  GROUP_CONCAT(if(type = 'preferred_qualifications', text, NULL)) AS preferred_qualifications,
  GROUP_CONCAT(if(type = 'selection_plan', text, NULL)) AS selection_plan,
  GROUP_CONCAT(if(type = 'selection_criteria', text, NULL)) AS selection_criteria,
  GROUP_CONCAT(if(type = 'additional_qualifications', text, NULL)) AS additional_qualifications,
  GROUP_CONCAT(if(type = 'equity_advisor_role', text, NULL)) AS equity_advisor_role,
  GROUP_CONCAT(if(type = 'actual_search_effort', text, NULL)) AS actual_search_effort,
  GROUP_CONCAT(if(type = 'internal_analyst_notes', text, NULL)) AS internal_analyst_notes
FROM descriptions
GROUP BY  recruitment_id");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE `", @db, "`.descriptions 
SELECT a.*, b.job_number, c.name as academic_year
FROM `", @db, "`.descriptions1 as a
LEFT JOIN recruitments as b on a.recruitment_id = b.id
LEFT JOIN academic_years as c on b.academic_year_id = c.id
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
ALTER TABLE `", @db, "`.descriptions
ADD campus VARCHAR(10) FIRST,
MODIFY job_number VARCHAR(32) AFTER recruitment_id,
MODIFY academic_year VARCHAR(255) AFTER job_number
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
UPDATE `", @db, "`.descriptions
SET campus = @db
WHERE recruitment_id IS NOT NULL;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;


#
#SHOW VARIABLES LIKE "secure_file_priv";
#SELECT * FROM mywork.descriptions INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/test1.csv' 
#FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';







