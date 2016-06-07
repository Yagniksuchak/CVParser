
#usage: create Application_Level_draft table
#current issue: need to add other campuses
USE ucrecruit;
USE ucrecruit_ucb;
USE ucrecruit_ucd;
USE ucrecruit_ucla;
USE ucrecruit_ucm;
USE ucrecruit_ucr;
USE ucrecruit_ucsb;
USE ucrecruit_ucsc;
USE ucrecruit_ucsd;
USE ucrecruit_ucsf;



# Only include academic year 2013-2015
# Merge applicants and positions table
CREATE TABLE mywork.app0
SELECT a.*, 
    `positions`.`recruitment_id`,
    `recruitments`.`academic_year_id`                                                                                                                                                                                                                                                                                                                                              
FROM applications a
LEFT JOIN positions ON a.position_id = `positions`.`id`
INNER JOIN recruitments ON `positions`.`recruitment_id` = `recruitments`.`id`
WHERE `recruitments`.`academic_year_id` IN (14, 15)
ORDER BY a.id;

ALTER TABLE mywork.app0 DROP updated_at, DROP created_at;

#SELECT * FROM mywork.app0;

CREATE TABLE mywork.app1
SELECT a.*,
	`applicants`.`first_name`,
    `applicants`.`last_name`,
    `applicants`.`email`,
    `applicants`.`affiliation`,
    `applicants`.`current_job_title`,
	`applicant_degrees`.`name` AS degree_name,
    `applicant_degrees`.`institution` ,
    `applicant_degrees`.`dissertation_title`,
    `applicant_degrees`.`date` AS degree_date,
    `applicant_degrees`.`advisor_1`,
    `applicant_degrees`.`advisor_2`
FROM mywork.app0 a
LEFT JOIN applicants ON a.applicant_id = `applicants`.`id`
LEFT JOIN applicant_degrees ON  a.applicant_id = `applicant_degrees`.`applicant_id`;


#create mywork.decline_reasons table
#can have more than one decline reason
CREATE TABLE mywork.decline_reasons1 
SELECT * FROM applications_decline_reasons
WHERE application_id IN (SELECT DISTINCT id FROM mywork.app0)
ORDER BY application_id;

#SELECT count(application_id), application_id FROM mywork.decline_reasons1 GROUP BY application_id;

CREATE TABLE mywork.decline_reasons2 
SELECT C.*, D.decline_reason_cnt FROM
(
	SELECT A.*, B.decline_reason_id  FROM 
	(
/* generating combination of application_id with decline_reasons_cnt */
		SELECT DISTINCT (A.application_id), B.cnt FROM mywork.decline_reasons1 AS A JOIN
		(SELECT 1 cnt UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) B 
		ORDER BY A.application_id, B.cnt
	) A
	LEFT JOIN /* Combinations of id with decline_reasons_cnt left join with decline_reason_id*/
	(
		SELECT 
		x.*,
		@cumcnt:=IF(@previous = x.application_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
		@previous:=x.application_id pre_id
		FROM
		(SELECT * FROM mywork.decline_reasons1 ORDER BY application_id) x,
		(SELECT @cnt:=0, @cumcnt:=0) vals
	) B
ON A.application_id = B.application_id AND A.cnt = B.cnt
) C
LEFT JOIN 
#create table with decline_reasons count 
(
	SELECT application_id, COUNT(application_id) as decline_reason_cnt FROM mywork.decline_reasons1 
	GROUP BY application_id
) D
ON C.application_id = D.application_id;

/*Pivot table*/ 
SET group_concat_max_len=1500000;
SET @sql1 = NULL;
SET @sql2 = NULL;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', decline_reason_id, NULL)) AS ',
      CONCAT('decline_reason_id_',cnt)
    )
  ) INTO @sql1
FROM mywork.decline_reasons2 ;

SET @sql2 = CONCAT('CREATE TABLE mywork.decline_reasons SELECT application_id, decline_reason_cnt, ', @sql1, 
' FROM mywork.decline_reasons2 GROUP BY application_id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;



#create mywork.disposition_reasons table
#can have more than one disposition reason
#caution: need to be careful about customized disposition reasons for some recruitment_id, add them in codebook
CREATE TABLE mywork.disposition_reasons1 
SELECT * FROM applications_disposition_reasons
WHERE application_id IN (SELECT DISTINCT id FROM mywork.app0)
ORDER BY application_id;

#SELECT count(application_id), application_id FROM mywork.disposition_reasons1 GROUP BY application_id;

CREATE TABLE mywork.disposition_reasons2 
SELECT C.*, D.disposition_reason_cnt FROM
(
	SELECT A.*, B.disposition_reason_id  FROM 
	(
/* generating combination of application_id with disposition_reasons_cnt */
		SELECT DISTINCT (A.application_id), B.cnt FROM mywork.disposition_reasons1 AS A JOIN
		(SELECT 1 cnt UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 ) B 
		ORDER BY A.application_id, B.cnt
	) A
	LEFT JOIN /* Combinations of id with decline_reasons_cnt left join with decline_reason_id*/
	(
		SELECT 
		x.*,
		@cumcnt:=IF(@previous = x.application_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
		@previous:=x.application_id pre_id
		FROM
		(SELECT * FROM mywork.disposition_reasons1 ORDER BY application_id) x,
		(SELECT @cnt:=0, @cumcnt:=0) vals
	) B
ON A.application_id = B.application_id AND A.cnt = B.cnt
) C
LEFT JOIN 
#create table with decline_reasons count 
(
	SELECT application_id, COUNT(application_id) as disposition_reason_cnt FROM mywork.disposition_reasons1 
	GROUP BY application_id
) D
ON C.application_id = D.application_id;

/*Pivot table*/ 
SET group_concat_max_len=1500000;
SET @sql1 = NULL;
SET @sql2 = NULL;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', disposition_reason_id, NULL)) AS ',
      CONCAT('disposition_reason_id_',cnt)
    )
  ) INTO @sql1
FROM mywork.disposition_reasons2 ;

SET @sql2 = CONCAT('CREATE TABLE mywork.disposition_reasons SELECT application_id, disposition_reason_cnt, ', @sql1, 
' FROM mywork.disposition_reasons2 GROUP BY application_id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SHOW ERRORS;


CREATE TABLE mywork.app2
SELECT A.*, `decline_reasons`.`decline_reason_cnt`,
    `decline_reasons`.`decline_reason_id_1`,
    `decline_reasons`.`decline_reason_id_2`,
    `decline_reasons`.`decline_reason_id_3`,
    `decline_reasons`.`decline_reason_id_4`,
    `disposition_reasons`.`disposition_reason_cnt`,
    `disposition_reasons`.`disposition_reason_id_1`,
    `disposition_reasons`.`disposition_reason_id_2`,
    `disposition_reasons`.`disposition_reason_id_3`,
    `disposition_reasons`.`disposition_reason_id_4`,
    `disposition_reasons`.`disposition_reason_id_5`,
    `disposition_reasons`.`disposition_reason_id_6`,
    `disposition_reasons`.`disposition_reason_id_7`
FROM mywork.app1 A
LEFT JOIN mywork.decline_reasons ON A.id = `decline_reasons`.`application_id`
LEFT JOIN mywork.disposition_reasons ON A.id = `disposition_reasons`.`application_id`;

#merge offers table
CREATE TABLE mywork.app3
SELECT A.*, B.id AS offer_id, B.recruitment_title_id, B.discipline, B.starting_salary, B.step
FROM mywork.app2 A
LEFT JOIN offers B ON A.id = B.application_id
GROUP BY A.id;


#merge appointments table
#can have joint appointment from multiple departments with different percent time.
#match with lisitng department
#create mywork.decline_reasons table
CREATE TABLE mywork.appointments1
SELECT * FROM 
(
	SELECT offer_id, department_id, percent_time 
	FROM appointments GROUP BY offer_id, department_id ORDER BY offer_id, department_id, percent_time DESC 
) A
WHERE offer_id IN (SELECT DISTINCT offer_id FROM mywork.app0);


#SELECT COUNT(OFFER_ID),offer_id FROM mywork.appointments1 GROUP BY offer_id;


CREATE TABLE mywork.appointments2
SELECT C.*, D.appointment_cnt FROM
(
	SELECT A.*, B.department_id, B.percent_time as appointment_pct_time FROM 
	(
/* generating combination of id with cnt */
		SELECT DISTINCT (A.offer_id), E.cnt FROM mywork.appointments1 AS A JOIN
		(SELECT 1 cnt UNION SELECT 2 UNION SELECT 3) E
		ORDER BY A.offer_id, E.cnt
	) A
	LEFT JOIN /* Combinations of id with cnt left join with B.department_id, B.percent_time*/
	(
		SELECT 
		x.*,
		@cumcnt:=IF(@previous = x.offer_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
		@previous:=x.offer_id pre_id
		FROM
		(SELECT * FROM mywork.appointments1 ORDER BY offer_id) x,
		(SELECT @cnt:=0, @cumcnt:=0) vals
	) B
ON A.offer_id = B.offer_id AND A.cnt = B.cnt
) C
LEFT JOIN 
#create table with appiontment count 
(
	SELECT COUNT(offer_id) as appointment_cnt, offer_id FROM mywork.appointments1 GROUP BY offer_id
) D
ON C.offer_id = D.offer_id;

/*Pivot table*/ 
SET group_concat_max_len=1500000;
SET @sql1 = NULL;
SET @sql2 = NULL;
SET @sql3 = NULL;
SET @sql4 = NULL;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', department_id, NULL)) AS ',
      CONCAT('department_id',cnt)
    )
  ) INTO @sql1
FROM mywork.appointments2;

SET @sql2 = CONCAT('CREATE TABLE mywork.appointments3 SELECT offer_id, appointment_cnt, ', @sql1, 
' FROM mywork.appointments2 GROUP BY offer_id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', appointment_pct_time, NULL)) AS ',
      CONCAT('appointment_pct_time',cnt)
    )
  ) INTO @sql3
FROM mywork.appointments2;

SET @sql4 = CONCAT('CREATE TABLE mywork.appointments4 SELECT offer_id, ', @sql3, 
' FROM mywork.appointments2 GROUP BY offer_id');
PREPARE stmt FROM @sql4;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


CREATE TABLE mywork.app4
SELECT A.*, B.appointment_cnt, B.department_id1, B.department_id2, B.department_id3, 
C.appointment_pct_time1, C.appointment_pct_time2, C.appointment_pct_time3
FROM mywork.app3 A
LEFT JOIN mywork.appointments3 B ON A.offer_id = B.offer_id
LEFT JOIN mywork.appointments4 C ON A.offer_id = C.offer_id;

#add disposition comments
SET group_concat_max_len=1500000;
SET @sql = NULL;
SET @sql = CONCAT("CREATE TABLE mywork.dis_comment
SELECT  
  on_id as application_id, user_id, 
  GROUP_CONCAT(if(type = 'DispositionComment', markup, NULL)) AS DispositionComment
FROM base_comments
WHERE on_type='Application' 
GROUP BY  on_id");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

#SELECT * FROM mywork.dis_comment;
#Need remove duplicated disposition comments
#SELECT * FROM base_comments where ON_TYPE='Application' and type = 'DispositionComment' GROUP BY on_id;

#have multiple comments
#SELECT count(on_id), on_id FROM ucrecruit.base_comments where ON_TYPE='Application' and type = 'Comment' GROUP BY on_id;

CREATE TABLE mywork.app5
SELECT A.*, B.DispositionComment, C.gender, C.ethnicity, C.ad_source, C.veteran_status, C.disability_status
FROM mywork.app4 A
LEFT JOIN mywork.dis_comment B on A.id = B.application_id
LEFT JOIN survey_responses C ON A.id = C.application_id;

#add referrals table
CREATE TABLE mywork.referrals1
SELECT `referrals`.`application_id`,
    `referrals`.`name`,
    `referrals`.`email`,
    `referrals`.`title`,
    `referrals`.`affiliation` FROM referrals 
WHERE application_id IN (SELECT id FROM mywork.app0)
ORDER BY application_id;

#SELECT COUNT(application_id),application_id FROM mywork.referrals1 GROUP BY application_id;


CREATE TABLE mywork.referrals2
SELECT A.*, C.name AS referral_name, C.email AS referral_email, C.title AS referral_title, C.affiliation AS referral_affiliation 
FROM 
	(
/* generating combination of id with cnt */
		SELECT DISTINCT (A.application_id), B.cnt FROM mywork.referrals1 AS A JOIN
		(SELECT 1 cnt UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
        UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15) B 
		ORDER BY A.application_id, B.cnt
	) A
	LEFT JOIN /* Combinations of id with cnt left join with B.department_id, B.percent_time*/
	(
		SELECT 
		x.*,
		@cumcnt:=IF(@previous = x.application_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
		@previous:=x.application_id pre_id
		FROM
		(SELECT * FROM mywork.referrals1 ORDER BY application_id) x,
		(SELECT @cnt:=0, @cumcnt:=0) vals
	) C
ON A.application_id = C.application_id AND A.cnt = C.cnt;


#SELECT * FROM mywork.referrals2;
/*Pivot table*/ 
SET group_concat_max_len=1500000;
SET @sql1 = NULL;
SET @sql2 = NULL;
SET @sql3 = NULL;
SET @sql4 = NULL;
SET @sql5 = NULL;
SET @sql6 = NULL;
SET @sql7 = NULL;
SET @sql8 = NULL;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', referral_name, NULL)) AS ',
      CONCAT('referral_name',cnt)
    )
  ) INTO @sql1
FROM mywork.referrals2;

SET @sql2 = CONCAT('CREATE TABLE mywork.referrals3 SELECT application_id, ', @sql1, 
' FROM mywork.referrals2 GROUP BY application_id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', referral_email, NULL)) AS ',
      CONCAT('referral_email',cnt)
    )
  ) INTO @sql3
FROM mywork.referrals2;

SET @sql4 = CONCAT('CREATE TABLE mywork.referrals4 SELECT application_id, ', @sql3, 
' FROM mywork.referrals2 GROUP BY application_id');
PREPARE stmt FROM @sql4;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', referral_title, NULL)) AS ',
      CONCAT('referral_title',cnt)
    )
  ) INTO @sql5
FROM mywork.referrals2;

SET @sql6 = CONCAT('CREATE TABLE mywork.referrals5 SELECT application_id, ', @sql5, 
' FROM mywork.referrals2 GROUP BY application_id');
PREPARE stmt FROM @sql6;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', referral_affiliation, NULL)) AS ',
      CONCAT('referral_affiliation',cnt)
    )
  ) INTO @sql7
FROM mywork.referrals2;

SET @sql8 = CONCAT('CREATE TABLE mywork.referrals6 SELECT application_id, ', @sql7, 
' FROM mywork.referrals2 GROUP BY application_id');
PREPARE stmt FROM @sql8;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE mywork.app6
SELECT A.*, B.reference_cnt, 
	`referrals3`.`referral_name1`,
    `referrals3`.`referral_name2`,
    `referrals3`.`referral_name3`,
    `referrals3`.`referral_name4`,
    `referrals3`.`referral_name5`,
    `referrals3`.`referral_name6`,
    `referrals3`.`referral_name7`,
    `referrals3`.`referral_name8`,
    `referrals3`.`referral_name9`,
    `referrals3`.`referral_name10`,
    `referrals3`.`referral_name11`,
    `referrals3`.`referral_name12`,
    `referrals3`.`referral_name13`,
    `referrals3`.`referral_name14`,
    `referrals3`.`referral_name15`,
    `referrals4`.`referral_email1`,
    `referrals4`.`referral_email2`,
    `referrals4`.`referral_email3`,
    `referrals4`.`referral_email4`,
    `referrals4`.`referral_email5`,
    `referrals4`.`referral_email6`,
    `referrals4`.`referral_email7`,
    `referrals4`.`referral_email8`,
    `referrals4`.`referral_email9`,
    `referrals4`.`referral_email10`,
    `referrals4`.`referral_email11`,
    `referrals4`.`referral_email12`,
    `referrals4`.`referral_email13`,
    `referrals4`.`referral_email14`,
    `referrals4`.`referral_email15`,
    `referrals5`.`referral_title1`,
    `referrals5`.`referral_title2`,
    `referrals5`.`referral_title3`,
    `referrals5`.`referral_title4`,
    `referrals5`.`referral_title5`,
    `referrals5`.`referral_title6`,
    `referrals5`.`referral_title7`,
    `referrals5`.`referral_title8`,
    `referrals5`.`referral_title9`,
    `referrals5`.`referral_title10`,
    `referrals5`.`referral_title11`,
    `referrals5`.`referral_title12`,
    `referrals5`.`referral_title13`,
    `referrals5`.`referral_title14`,
    `referrals5`.`referral_title15`,
    `referrals6`.`referral_affiliation1`,
    `referrals6`.`referral_affiliation2`,
    `referrals6`.`referral_affiliation3`,
    `referrals6`.`referral_affiliation4`,
    `referrals6`.`referral_affiliation5`,
    `referrals6`.`referral_affiliation6`,
    `referrals6`.`referral_affiliation7`,
    `referrals6`.`referral_affiliation8`,
    `referrals6`.`referral_affiliation9`,
    `referrals6`.`referral_affiliation10`, 
    `referrals6`.`referral_affiliation11`,
    `referrals6`.`referral_affiliation12`,
    `referrals6`.`referral_affiliation13`,
    `referrals6`.`referral_affiliation14`,
    `referrals6`.`referral_affiliation15`
FROM mywork.app5 A
LEFT JOIN (SELECT COUNT(application_id) as reference_cnt ,application_id FROM mywork.referrals1 GROUP BY application_id) B ON A.id = B.application_id
LEFT JOIN mywork.referrals3 ON A.id = `referrals3`.`application_id`
LEFT JOIN mywork.referrals4 ON A.id = `referrals4`.`application_id`
LEFT JOIN mywork.referrals5 ON A.id = `referrals5`.`application_id`
LEFT JOIN mywork.referrals6 ON A.id = `referrals6`.`application_id`;

#add campus_id
ALTER TABLE mywork.app6 ADD campus_id INT FIRST;
UPDATE mywork.app6 SET campus_id = 1;
#change labels into values, rules based on codebook
#need to take care of variations from difference campuses
#add source may change among campuses
UPDATE mywork.app6 SET gender =  1 WHERE gender = "male";
UPDATE mywork.app6 SET gender =  2 WHERE gender = "female";
UPDATE mywork.app6 SET gender =  3 WHERE gender = "gender_decline_to_state";
UPDATE mywork.app6 SET gender =  1 WHERE gender = "male";
UPDATE mywork.app6 SET ethnicity = 1 WHERE ethnicity = "african";
UPDATE mywork.app6 SET ethnicity = 2 WHERE ethnicity = "asian";
UPDATE mywork.app6 SET ethnicity = 3 WHERE ethnicity = "latino";
UPDATE mywork.app6 SET ethnicity = 4 WHERE ethnicity = "native_american";
UPDATE mywork.app6 SET ethnicity = 5 WHERE ethnicity = "white";
UPDATE mywork.app6 SET ethnicity = 6 WHERE ethnicity = "Applicant declined to state their ethnicity";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "ad_source_decline_to_state";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "chronicle_higher_ed";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "herc";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "inside_higher";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "other";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "posted_announcement";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "professional_journal";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "professional_org";
UPDATE mywork.app6 SET ad_source = 1 WHERE ad_source = "uc_website";




