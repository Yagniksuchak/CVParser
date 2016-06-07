
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

DROP SCHEMA `mywork`;
CREATE SCHEMA `mywork`;

DROP PROCEDURE IF EXISTS add_campus;

DELIMITER $$
CREATE PROCEDURE add_campus(campus_name VARCHAR(15))
BEGIN
SET @db = campus_name;

#select recruitments table of academic year 2014 and 2015
CREATE TABLE mywork.job1 SELECT * FROM recruitments
WHERE academic_year_id in (14, 15); #change to 2014 and 2015
ALTER TABLE mywork.job1 
DROP created_at, DROP updated_at, DROP created_by_user_id;


#merge pivot descriptions table
SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE mywork.job2
AS SELECT a.*, 
    `descriptions`.`description`,
    `descriptions`.`search_effort`,
    `descriptions`.`approved_search_area`,
    `descriptions`.`basic_qualifications`,
    `descriptions`.`preferred_qualifications`,
    `descriptions`.`selection_plan`,
    `descriptions`.`selection_criteria`,
    `descriptions`.`additional_qualifications`,
    `descriptions`.`equity_advisor_role`,
    `descriptions`.`actual_search_effort`,
    `descriptions`.`internal_analyst_notes`
FROM mywork.job1 AS a
LEFT JOIN `", @db, "`.descriptions 
ON a.id =  `descriptions`.`recruitment_id`;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

#merge herc_categories herc_divisions tables
CREATE TABLE mywork.job3 SELECT a.*, b.herc_division_id 
FROM mywork.job2 AS a
LEFT JOIN herc_categories AS b ON a.herc_category_id = b.id;
ALTER TABLE mywork.job3 MODIFY herc_division_id INT AFTER herc_category_id ;


################################################################################
##read Pivot_Search_Plan.sql to creat mywork.search_plan
################################################################################
CREATE TABLE mywork.search_plan0 
SELECT A.*, B.id as search_plan_id FROM 
(
/* generating combination of recruitment_id with ad1-ad24 */
SELECT DISTINCT (A.id), B.cnt FROM mywork.job3 as A join
(select 1 cnt union select 2 ) B 
order by A.id, B.cnt
) A
LEFT JOIN /* Combinations of id with ad left join with ad source name*/
(
SELECT 
    x.*,
    @cumcnt:=IF(@previous = x.recruitment_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
    @previous:=x.recruitment_id pre_id
FROM
    (SELECT * FROM search_plans ORDER BY recruitment_id) x,
    (SELECT @cnt:=0, @cumcnt:=0) vals
) B
ON A.id = B.recruitment_id AND A.cnt = B.cnt;

/*Pivot ad_source table*/
/* Auto method  */ 

SET group_concat_max_len=1500000;

SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', search_plan_id, NULL)) AS ',
      CONCAT('search_plan_id',cnt)
    )
  ) INTO @sql
FROM mywork.search_plan0;
SET @sql = CONCAT('CREATE TABLE mywork.search_plan SELECT id, ', @sql, ' FROM mywork.search_plan0 GROUP BY id');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

#merge search_plans table
CREATE TABLE mywork.job4
SELECT a.*, b.search_plan_id1, b.search_plan_id2
FROM mywork.job3 AS a 
LEFT JOIN mywork.search_plan AS b
ON a.id = b.id;


#add required_reference_types through positions table
CREATE TABLE mywork.job5
SELECT a.*, b.required_reference_type_id
FROM mywork.job4 AS a
LEFT JOIN
(
 SELECT DISTINCT recruitment_id, required_reference_type_id FROM positions 
 )
 AS b ON b.recruitment_id=a.id;

################################################################################
##read Pivot_Listings.sql to creat mywork.listings
################################################################################
CREATE TABLE mywork.listings0 
SELECT a.id, b.department_id, b.school_id
FROM mywork.job5 AS a 
LEFT JOIN listings AS b ON a.id = b.recruitment_id;

#create table with listing count col
CREATE TABLE mywork.list_cnt
SELECT id, COUNT(id) as cnt FROM mywork.listings0
GROUP BY id;

CREATE TABLE mywork.listings1 
SELECT A.*, B.department_id, B.school_id FROM 
(
/* generating combination of recruitment_id with ad1-ad24 */
SELECT DISTINCT (A.id), B.cnt FROM mywork.listings0 as A join
(select 1 cnt union select 2 union select 3 union select 4 union select 5 union select 6) B 
order by A.id, B.cnt
) A
LEFT JOIN /* Combinations of id with ad left join with ad source name*/
(
SELECT 
    x.*,
    @cumcnt:=IF(@previous = x.id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
    @previous:=x.id pre_id
FROM
    (SELECT * FROM mywork.listings0 ORDER BY id) x,
    (SELECT @cnt:=0, @cumcnt:=0) vals
) B
ON A.id = B.id AND A.cnt = B.cnt;

/*Pivot listing table*/
/* Auto method  */ 

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
      CONCAT('listing_department_id_',cnt)
    )
  ) INTO @sql1
FROM mywork.listings1 ;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', school_id, NULL)) AS ',
      CONCAT('listing_school_id_',cnt)
    )
  ) INTO @sql2
FROM mywork.listings1 ;
SET @sql3 = CONCAT('CREATE TABLE mywork.listings2 SELECT id, ', @sql1, ' FROM mywork.listings1 GROUP BY id');
PREPARE stmt FROM @sql3;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql4 = CONCAT('CREATE TABLE mywork.listings3 SELECT id, ', @sql2, ' FROM mywork.listings1 GROUP BY id');
PREPARE stmt FROM @sql4;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE mywork.listings4 SELECT a.*, 
b.listing_school_id_1, b.listing_school_id_2, b.listing_school_id_3, b.listing_school_id_4, b.listing_school_id_5, b.listing_school_id_6
FROM mywork.listings2 as a JOIN mywork.listings3 AS b ON a.id=b.id;

CREATE TABLE mywork.listings SELECT a.*, b.cnt 
FROM mywork.listings4 AS a
LEFT JOIN mywork.list_cnt AS b
ON a.id = b.id;

#merge listings table to get department_id & school_id
#one position may have more than one listing from several department
CREATE TABLE mywork.job6 
SELECT a.*, b.cnt as listing_cnt, 
b.listing_department_id_1, b.listing_department_id_2, b.listing_department_id_3, b.listing_department_id_4, b.listing_department_id_5, b.listing_department_id_6,
b.listing_school_id_1, b.listing_school_id_2, b.listing_school_id_3, b.listing_school_id_4, b.listing_school_id_5, b.listing_school_id_6
FROM mywork.job5 AS a 
LEFT JOIN mywork.listings AS b ON a.id = b.id;

################################################################################
##read Pivot_Recruitment_titles.sql to creat mywork.recruitment_titles
################################################################################
CREATE TABLE mywork.recruitment_titles_recruitments0 
SELECT a.*, b.name, b.code 
FROM recruitment_titles_recruitments as a 
LEFT JOIN recruitment_titles as b ON a.recruitment_title_id = b.id 
CROSS JOIN mywork.job6 as c ON a.recruitment_id = c.id
order by a.recruitment_id;

CREATE TABLE mywork.recruitment_titles_recruitments 
SELECT DISTINCT recruitment_title_id, recruitment_id, name, code
FROM mywork.recruitment_titles_recruitments0 GROUP BY recruitment_title_id;

#generate table with all comb of name and code for each id
CREATE TABLE mywork.recruitment_titles0 
SELECT A.*, B.name, B.code FROM 
(
/* generating combination of recruitment_id with cnt1-6 */
SELECT DISTINCT (A.recruitment_id), B.cnt FROM mywork.recruitment_titles_recruitments as A join
(select 1 cnt union select 2 union select 3 union select 4 union select 5 
union select 6 union select 7 union select 8 union select 9 union select 10 
union select 11 union select 12 union select 13 union select 14 union select 15) B 
order by A.recruitment_id, B.cnt
) A
LEFT JOIN
(
#COUNT MAXMIUM
SELECT 
    x.*,
    @cumcnt:=IF(@previous = x.recruitment_id, @cumcnt, 0) + 1 as cnt, /*Calculate cumlative count by id*/
    @previous:=x.recruitment_id as pre_id
FROM
    (SELECT * FROM mywork.recruitment_titles_recruitments ORDER BY recruitment_id) x,
    (SELECT @cnt:=0, @cumcnt:=0) vals
) B
ON A.recruitment_id = B.recruitment_id AND A.cnt = B.cnt;



/*Pivot recruitment_titles table*/
/* Auto method  */ 

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
      ', name, NULL)) AS ',
      CONCAT('recruitment_title_name_',cnt)
    )
  ) INTO @sql1
FROM mywork.recruitment_titles0 ;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', code, NULL)) AS ',
      CONCAT('recruitment_title_code_',cnt)
    )
  ) INTO @sql2
FROM mywork.recruitment_titles0 ;
SET @sql3 = CONCAT('CREATE TABLE mywork.recruitment_titles1 SELECT recruitment_id, ', @sql1, ' FROM mywork.recruitment_titles0 GROUP BY recruitment_id');
PREPARE stmt FROM @sql3;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql4 = CONCAT('CREATE TABLE mywork.recruitment_titles2 SELECT recruitment_id, ', @sql2, ' FROM mywork.recruitment_titles0 GROUP BY recruitment_id');
PREPARE stmt FROM @sql4;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE mywork.recruitment_titles SELECT a.*, 
b.recruitment_title_code_1,b.recruitment_title_code_2, b.recruitment_title_code_3, 
b.recruitment_title_code_4, b.recruitment_title_code_5, b.recruitment_title_code_6,
b.recruitment_title_code_7, b.recruitment_title_code_8, b.recruitment_title_code_9, 
b.recruitment_title_code_10, b.recruitment_title_code_11, b.recruitment_title_code_12,
b.recruitment_title_code_13, b.recruitment_title_code_14, b.recruitment_title_code_15
FROM mywork.recruitment_titles1 as a JOIN mywork.recruitment_titles2 AS b ON a.recruitment_id=b.recruitment_id;

#merge recruitment_title
CREATE TABLE mywork.job7 
SELECT a.*, 
b.recruitment_title_name_1, b.recruitment_title_name_2, b.recruitment_title_name_3, 
b.recruitment_title_name_4, b.recruitment_title_name_5, b.recruitment_title_name_6,
b.recruitment_title_name_7, b.recruitment_title_name_8, b.recruitment_title_name_9,
b.recruitment_title_name_10, b.recruitment_title_name_11, b.recruitment_title_name_12,
b.recruitment_title_name_13, b.recruitment_title_name_14, b.recruitment_title_name_15,
b.recruitment_title_code_1,b.recruitment_title_code_2, b.recruitment_title_code_3, 
b.recruitment_title_code_4, b.recruitment_title_code_5, b.recruitment_title_code_6,
b.recruitment_title_code_7, b.recruitment_title_code_8, b.recruitment_title_code_9,
b.recruitment_title_code_10, b.recruitment_title_code_11, b.recruitment_title_code_12, 
b.recruitment_title_code_13, b.recruitment_title_code_14, b.recruitment_title_code_15
FROM mywork.job6 AS a 
LEFT JOIN mywork.recruitment_titles AS b
ON a.id = b.recruitment_id ;


################################################################################
##read Pivot_Recruitment_specialties.sql to creat mywork.recruitment_specialties
################################################################################
#merge mywork.recruitment_specialties_recruitments and recruitment_specialties table
CREATE TABLE mywork.recruitment_specialties_recruitments
SELECT a.id, b.recruitment_specialty_id, c.recruitment_specialty_type_id, 
c.name as recruitment_specialties_name, c.code as recruitment_specialties_code
FROM mywork.job7 AS a
LEFT JOIN recruitment_specialties_recruitments AS b ON a.id = b.recruitment_id
LEFT JOIN recruitment_specialties AS c ON b.recruitment_specialty_id = c.id;

#create all comb
CREATE TABLE mywork.recruitment_specialties1
SELECT A.*, B.recruitment_specialty_id, B.recruitment_specialties_name, B.recruitment_specialties_code, B.recruitment_specialty_type_id 
FROM 
(
/* generating combination of recruitment_id with ad1-ad24 */
SELECT DISTINCT (A.id), B.cnt FROM mywork.recruitment_specialties_recruitments as A join
(select 1 cnt union select 2 union select 3 union select 4 union select 5
union select 6 cnt union select 7 union select 8 union select 9 union select 10) B 
order by A.id, B.cnt
) A
LEFT JOIN /* Combinations of id with ad left join with ad source name*/
(
SELECT 
    x.*,
    @cumcnt:=IF(@previous = x.id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
    @previous:=x.id pre_id
FROM
    (SELECT * FROM mywork.recruitment_specialties_recruitments ORDER BY id) x,
    (SELECT @cnt:=0, @cumcnt:=0) vals
) B
ON A.id = B.id AND A.cnt = B.cnt;


/*Pivot recruitment_specialties1 table*/
/* Auto method  */ 

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
      ', recruitment_specialty_id, NULL)) AS ',
      CONCAT('recruitment_specialty_id_',cnt)
    )
  ) INTO @sql1
FROM mywork.recruitment_specialties1;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', recruitment_specialties_name, NULL)) AS ',
      CONCAT('recruitment_specialties_name_',cnt)
    )
  ) INTO @sql3
FROM mywork.recruitment_specialties1;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', recruitment_specialties_code, NULL)) AS ',
      CONCAT('recruitment_specialties_code_',cnt)
    )
  ) INTO @sql5
FROM mywork.recruitment_specialties1;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', recruitment_specialty_type_id, NULL)) AS ',
      CONCAT('recruitment_specialty_type_id_',cnt)
    )
  ) INTO @sql7
FROM mywork.recruitment_specialties1;


SET @sql2 = CONCAT('CREATE TABLE mywork.recruitment_specialties2 SELECT id, ', @sql1, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql4 = CONCAT('CREATE TABLE mywork.recruitment_specialties3 SELECT id, ', @sql3, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql4;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql6 = CONCAT('CREATE TABLE mywork.recruitment_specialties4 SELECT id, ', @sql5, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql6;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql8 = CONCAT('CREATE TABLE mywork.recruitment_specialties5 SELECT id, ', @sql7, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql8;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE mywork.recruitment_specialties6 
SELECT a.*,
    `recruitment_specialties3`.`recruitment_specialties_name_1`,
    `recruitment_specialties3`.`recruitment_specialties_name_2`,
    `recruitment_specialties3`.`recruitment_specialties_name_3`,
    `recruitment_specialties3`.`recruitment_specialties_name_4`,
    `recruitment_specialties3`.`recruitment_specialties_name_5`,
	`recruitment_specialties3`.`recruitment_specialties_name_6`, 
    `recruitment_specialties3`.`recruitment_specialties_name_7`, 
    `recruitment_specialties3`.`recruitment_specialties_name_8`,
    `recruitment_specialties3`.`recruitment_specialties_name_9`,
    `recruitment_specialties3`.`recruitment_specialties_name_10`,
    `recruitment_specialties4`.`recruitment_specialties_code_1`,
    `recruitment_specialties4`.`recruitment_specialties_code_2`,
    `recruitment_specialties4`.`recruitment_specialties_code_3`,
    `recruitment_specialties4`.`recruitment_specialties_code_4`,
    `recruitment_specialties4`.`recruitment_specialties_code_5`,
    `recruitment_specialties4`.`recruitment_specialties_code_6`,
    `recruitment_specialties4`.`recruitment_specialties_code_7`,
    `recruitment_specialties4`.`recruitment_specialties_code_8`,
    `recruitment_specialties4`.`recruitment_specialties_code_9`,
    `recruitment_specialties4`.`recruitment_specialties_code_10`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_1`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_2`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_3`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_4`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_5`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_6`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_7`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_8`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_9`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_10`
FROM mywork.recruitment_specialties2 as a 
JOIN mywork.recruitment_specialties3 ON a.id=`recruitment_specialties3`.id
JOIN mywork.recruitment_specialties4 ON a.id=`recruitment_specialties4`.id
JOIN mywork.recruitment_specialties5 ON a.id=`recruitment_specialties5`.id;

#add count
CREATE TABLE mywork.recruitment_specialties 
SELECT a.*, b.recruitment_specialties_cnt 
FROM mywork.recruitment_specialties6 AS a
LEFT JOIN
(
SELECT id,COUNT(id) AS recruitment_specialties_cnt FROM mywork.recruitment_specialties_recruitments GROUP BY id
 ) b
ON a.id = b.id;

#modify column number
ALTER TABLE mywork.recruitment_specialties  
MODIFY recruitment_specialties_cnt INT AFTER id;

#merge recruitment_specialties
#one position may have more than one recruitment_specialty_id, 
#each recruitment_specialty_id has one recruitment_specialty_type_id
CREATE TABLE mywork.job8 
SELECT a.*, 
    `recruitment_specialties`.`recruitment_specialties_cnt`,
    `recruitment_specialties`.`recruitment_specialty_id_1`,
    `recruitment_specialties`.`recruitment_specialty_id_2`,
    `recruitment_specialties`.`recruitment_specialty_id_3`,
    `recruitment_specialties`.`recruitment_specialty_id_4`,
    `recruitment_specialties`.`recruitment_specialty_id_5`,
    `recruitment_specialties`.`recruitment_specialty_id_6`,
    `recruitment_specialties`.`recruitment_specialty_id_7`,
    `recruitment_specialties`.`recruitment_specialty_id_8`,
    `recruitment_specialties`.`recruitment_specialty_id_9`,
    `recruitment_specialties`.`recruitment_specialty_id_10`,
    `recruitment_specialties`.`recruitment_specialties_name_1`,
    `recruitment_specialties`.`recruitment_specialties_name_2`,
    `recruitment_specialties`.`recruitment_specialties_name_3`,
    `recruitment_specialties`.`recruitment_specialties_name_4`,
    `recruitment_specialties`.`recruitment_specialties_name_5`,
    `recruitment_specialties`.`recruitment_specialties_name_6`,
    `recruitment_specialties`.`recruitment_specialties_name_7`,
    `recruitment_specialties`.`recruitment_specialties_name_8`,
    `recruitment_specialties`.`recruitment_specialties_name_9`,
    `recruitment_specialties`.`recruitment_specialties_name_10`,
    `recruitment_specialties`.`recruitment_specialties_code_1`,
    `recruitment_specialties`.`recruitment_specialties_code_2`,
    `recruitment_specialties`.`recruitment_specialties_code_3`,
    `recruitment_specialties`.`recruitment_specialties_code_4`,
    `recruitment_specialties`.`recruitment_specialties_code_5`,
    `recruitment_specialties`.`recruitment_specialties_code_6`,
    `recruitment_specialties`.`recruitment_specialties_code_7`,
    `recruitment_specialties`.`recruitment_specialties_code_8`,
    `recruitment_specialties`.`recruitment_specialties_code_9`,
    `recruitment_specialties`.`recruitment_specialties_code_10`,
    `recruitment_specialties`.`recruitment_specialty_type_id_1`,
    `recruitment_specialties`.`recruitment_specialty_type_id_2`,
    `recruitment_specialties`.`recruitment_specialty_type_id_3`,
    `recruitment_specialties`.`recruitment_specialty_type_id_4`,
    `recruitment_specialties`.`recruitment_specialty_type_id_5`,
    `recruitment_specialties`.`recruitment_specialty_type_id_6`,
    `recruitment_specialties`.`recruitment_specialty_type_id_7`,
    `recruitment_specialties`.`recruitment_specialty_type_id_8`,
    `recruitment_specialties`.`recruitment_specialty_type_id_9`,
    `recruitment_specialties`.`recruitment_specialty_type_id_10`
FROM mywork.job7 AS a
LEFT JOIN mywork.recruitment_specialties  ON a.id = `recruitment_specialties`.id;

ALTER TABLE mywork.job8 ADD campus VARCHAR(10) FIRST;

SET @sql = NULL;
SET @sql = CONCAT("
UPDATE mywork.job8
SET campus = @db
WHERE id IS NOT NULL;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
DROP TABLE IF EXISTS `", @db, "`.job8;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE `", @db, "`.job8 SELECT * FROM mywork.job8 ORDER BY id;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

#SELECT * FROM mywork.job8;

END$$
DELIMITER ;


CALL ucrecruit.add_campus('uci');
CALL ucrecruit_ucb.add_campus('ucb');
CALL ucrecruit_ucd.add_campus('ucd');
CALL ucrecruit_ucla.add_campus('ucla');
CALL ucrecruit_ucm.add_campus('ucm');
CALL ucrecruit_ucr.add_campus('ucr');
CALL ucrecruit_ucsb.add_campus('ucsb');
CALL ucrecruit_ucsc.add_campus('ucsc');
CALL ucrecruit_ucsd.add_campus('ucsd');
CALL ucrecruit_ucsf.add_campus('ucsf');

CREATE SCHEMA final;

CREATE TABLE final.job_all0
SELECT * FROM uci.job8 UNION ALL
SELECT * FROM ucb.job8 UNION ALL
SELECT * FROM ucd.job8 UNION ALL
SELECT * FROM ucla.job8 UNION ALL
SELECT * FROM ucm.job8 UNION ALL
SELECT * FROM ucr.job8 UNION ALL
SELECT * FROM ucsb.job8 UNION ALL
SELECT * FROM ucsc.job8 UNION ALL
SELECT * FROM ucsd.job8 UNION ALL
SELECT * FROM ucsf.job8 
;

#make a copy
CREATE TABLE final.job_all1 SELECT * FROM final.job_all0 ;
#drop columns unwanted 
ALTER TABLE final.job_all1 
DROP recruitment_title_name_1, DROP recruitment_title_name_2, DROP recruitment_title_name_3, 
DROP recruitment_title_name_4, DROP recruitment_title_name_5, DROP recruitment_title_name_6,
DROP recruitment_title_name_7, DROP recruitment_title_name_8, DROP recruitment_title_name_9,
DROP recruitment_title_name_10, DROP recruitment_title_name_11, DROP recruitment_title_name_12,
DROP recruitment_title_name_13, DROP recruitment_title_name_14, DROP recruitment_title_name_15,
DROP recruitment_specialties_name_1, DROP recruitment_specialties_name_2,
DROP recruitment_specialties_name_3, DROP recruitment_specialties_name_4,
DROP recruitment_specialties_name_5, DROP recruitment_specialties_name_6,
DROP recruitment_specialties_name_7, DROP recruitment_specialties_name_8,
DROP recruitment_specialties_name_9, DROP recruitment_specialties_name_10;


SELECT DISTINCT(academic_year_id),campus FROM final.job_all0 WHERE search_plan_id1 IS NOT NULL;

SELECT id, campus, count(id) as cnt FROM final.job_all0 GROUP BY campus, id ORDER BY cnt desc;

SELECT * FROM final.job_all0 WHERE job_number = 'JPF00361';
#check duplicates of job number within campus
SELECT * FROM 
(
SELECT  id, job_number, campus, count(job_number) as cnt FROM final.job_all0 group by job_number, campus 
) A where cnt !=1 ;

#check duplicates of job number across campus
SELECT * FROM 
(
SELECT  id, job_number, campus, count(job_number) as cnt FROM final.job_all0 group by job_number order by job_number, campus
) A where cnt !=1 ;

SELECT DISTINCT job_number, campus, id FROM final.job_all0 ORDER BY job_number, campus;

SELECT DISTINCT campus, id FROM final.job_all0 ORDER BY ID, campus;


#check duplicates of job number within UCI
SELECT * FROM 
(
SELECT  id, job_number, campus, count(job_number) as cnt FROM uci.job8 group by job_number, campus order by cnt desc
) A where cnt !=1 ;