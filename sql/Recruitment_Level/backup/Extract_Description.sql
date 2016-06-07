
SET group_concat_max_len=1500000;


use ucrecruit;
CALL ucrecruit.writepivot('uci');


select * from mywork.descriptions;

use ucrecruit_ucb;
CALL ucrecruit_ucb.writepivot('ucb');

use ucrecruit_ucd;
CALL ucrecruit_ucd.writepivot('ucd');

use ucrecruit_ucla;
CALL ucrecruit_ucla.writepivot('ucla');

use ucrecruit_ucm;
CALL ucrecruit_ucm.writepivot('ucm');

use ucrecruit_ucr;
CALL ucrecruit_ucr.writepivot('ucr');

use ucrecruit_ucsb;
CALL ucrecruit_ucsb.writepivot('ucsb');

use ucrecruit_ucsc;
CALL ucrecruit_ucsc.writepivot('ucsc');

use ucrecruit_ucsd;
CALL ucrecruit_ucsd.writepivot('ucsd');

use ucrecruit_ucsf;
CALL ucrecruit_ucsf.writepivot('ucsf');


DROP TABLE IF EXISTS mywork.descriptions, mywork.descriptions1;
DROP PROCEDURE IF EXISTS writepivot;


#
#SHOW VARIABLES LIKE "secure_file_priv";
#SELECT * FROM mywork.descriptions INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/test1.csv' 
#FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
#show errors;


DELIMITER $$
CREATE PROCEDURE writepivot(campus_name VARCHAR(15))
BEGIN
CREATE TABLE mywork.descriptions1
SELECT  
  on_id as recruitment_id, 
 -- min(created_at) as earliest_created_at, max(created_at) as latest_created_at, min(updated_at) as updated_created_at, max(updated_at) as latest_updated_at,
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
-- where created_at >= '2013-07-01 00:00:00' and updated_at <'2014-07-01 00:00:00'
GROUP BY  recruitment_id;

CREATE TABLE mywork.descriptions 
SELECT a.*, b.job_number, c.name as academic_year
FROM mywork.descriptions1 as a
LEFT JOIN recruitments as b on a.recruitment_id = b.id
LEFT JOIN academic_years as c on b.academic_year_id = c.id;

ALTER TABLE mywork.descriptions
ADD campus VARCHAR(10) FIRST,
MODIFY job_number VARCHAR(32) AFTER recruitment_id,
MODIFY academic_year VARCHAR(255) AFTER job_number;

UPDATE mywork.descriptions
SET campus = campus_name
WHERE recruitment_id IS NOT NULL;

END$$

DELIMITER ;

#SHOW CREATE PROCEDURE writepivot;