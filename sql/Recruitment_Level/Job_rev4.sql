#need to rerun and add application and offer count

#usage: create main recruitment level table
#First, run use statement to select the database to use
#Second, run the procedure
#Third, run call statement
#Back to step run, to select a different database
#Finally, join the tables together, starting from line 234

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


DROP PROCEDURE IF EXISTS add_campus;

DELIMITER $$
CREATE PROCEDURE add_campus(campus_name VARCHAR(15), num INT)
BEGIN
SET @db = campus_name;

DROP SCHEMA `mywork`;
CREATE SCHEMA `mywork`;

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

#merge herc_categories tables and 'InitialSearchOutcomeComment' in base_comments table
CREATE TABLE mywork.job3 
SELECT a.*, b.herc_division_id, c.markup as initial_search_outcome_comment 
FROM mywork.job2 AS a
LEFT JOIN herc_categories AS b ON a.herc_category_id = b.id
LEFT JOIN 
(SELECT * FROM base_comments WHERE on_type = 'Recruitment') AS c ON A.id = c.on_id
;

ALTER TABLE mywork.job3 MODIFY herc_division_id INT AFTER herc_category_id, 
MODIFY initial_search_outcome_comment TEXT(65535) AFTER initial_search_outcome_code;


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
SELECT a.*, b.required_reference_type_id, b.min_required_references, b.max_required_references
FROM mywork.job4 AS a
LEFT JOIN
(
 SELECT DISTINCT recruitment_id, required_reference_type_id, min_required_references, max_required_references FROM positions 
 )
 AS b ON b.recruitment_id=a.id;

################################################################################
##read Pivot_Listings.sql to creat mywork.listings
################################################################################
CREATE TABLE mywork.listings0 
SELECT a.id, b.department_id, b.school_id
FROM mywork.job1 AS a 
LEFT JOIN listings AS b ON a.id = b.recruitment_id
GROUP BY a.id, b.department_id, b.school_id
ORDER BY a.id, b.department_id, b.school_id;

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

CREATE TABLE mywork.listings4 
SELECT a.*, b.listing_school_id_1, b.listing_school_id_2, b.listing_school_id_3, b.listing_school_id_4, b.listing_school_id_5, b.listing_school_id_6
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
##read Pivot_Recruitment_titles.sql to create mywork.recruitment_titles
################################################################################
CREATE TABLE mywork.recruitment_titles_recruitments
SELECT a.*, b.name, b.code 
FROM recruitment_titles_recruitments as a 
LEFT JOIN recruitment_titles as b ON a.recruitment_title_id = b.id 
WHERE a.recruitment_id in (SELECT id FROM mywork.job6)
GROUP BY a.recruitment_id, a.recruitment_title_id
ORDER BY a.recruitment_id, a.recruitment_title_id;

#generate table with all comb of name and code for each id
CREATE TABLE mywork.recruitment_titles0 
SELECT A.*, B.name, B.code FROM 
(
/* generating combination of recruitment_id with cnt1-6 */
SELECT DISTINCT (A.recruitment_id), B.cnt FROM mywork.recruitment_titles_recruitments as A join
(select 1 cnt union select 2 union select 3 union select 4 union select 5 
union select 6 union select 7 union select 8 union select 9 union select 10 
union select 11 union select 12 union select 13 union select 14 union select 15
union select 16 union select 17 union select 18 union select 19 union select 20
union select 21 cnt union select 22 union select 23 union select 24 union select 25 
union select 26 union select 27 union select 28 union select 29 union select 30 
union select 31 cnt union select 32) B 
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
      ', code, NULL)) AS ',
      CONCAT('recruitment_title_code_',cnt)
    )
  ) INTO @sql1
FROM mywork.recruitment_titles0 ;
SET @sql2 = CONCAT('CREATE TABLE mywork.recruitment_titles SELECT recruitment_id, ', @sql1, ' FROM mywork.recruitment_titles0 GROUP BY recruitment_id');
PREPARE stmt FROM @sql2;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


#merge recruitment_title
CREATE TABLE mywork.job7 
SELECT a.*, 
b.recruitment_title_code_1,b.recruitment_title_code_2, b.recruitment_title_code_3, b.recruitment_title_code_4, b.recruitment_title_code_5, 
b.recruitment_title_code_6,b.recruitment_title_code_7, b.recruitment_title_code_8, b.recruitment_title_code_9, b.recruitment_title_code_10, 
b.recruitment_title_code_11, b.recruitment_title_code_12, b.recruitment_title_code_13, b.recruitment_title_code_14, b.recruitment_title_code_15,
b.recruitment_title_code_16,b.recruitment_title_code_17, b.recruitment_title_code_18, b.recruitment_title_code_19, b.recruitment_title_code_20, 
b.recruitment_title_code_21,b.recruitment_title_code_22, b.recruitment_title_code_23, b.recruitment_title_code_24, b.recruitment_title_code_25, 
b.recruitment_title_code_26,b.recruitment_title_code_27, b.recruitment_title_code_28, b.recruitment_title_code_29, b.recruitment_title_code_30, 
b.recruitment_title_code_31,b.recruitment_title_code_32
FROM mywork.job6 AS a 
LEFT JOIN mywork.recruitment_titles AS b
ON a.id = b.recruitment_id ;


################################################################################
##read Pivot_Recruitment_specialties.sql to creat mywork.recruitment_specialties
################################################################################

#Deduplicates of recruitment_specialty, should only have 5 for each recruitment_id
CREATE TABLE mywork.recruitment_specialties_recruitments0
SELECT * FROM recruitment_specialties_recruitments 
#add code to delete duplicates
GROUP BY recruitment_id, recruitment_specialty_id ORDER BY recruitment_id;

#merge with Recruitment_Specialty_Type_recode.xlsx
#add recode and rename
CREATE TABLE mywork.recruitment_specialties0
SELECT a.id, a.recruitment_specialty_type_id, a.code, a.name, b.recruitment_specialties_recode, b.recruitment_specialties_rename
FROM recruitment_specialties AS a
LEFT JOIN final.specialties_recode AS b
ON a.code = b.recruitment_specialties_code and a.name=b.recruitment_specialties_name;

#SELECT * FROM mywork.recruitment_specialties0;
#SELECT * FROM recruitment_specialties;
#SELECT * FROM mywork.recruitment_specialties_recruitments0;

#merge mywork.recruitment_specialties_recruitments and recruitment_specialties table
CREATE TABLE mywork.recruitment_specialties_recruitments
SELECT a.id, b.recruitment_specialty_id, c.recruitment_specialty_type_id, 
c.name as recruitment_specialties_name, c.code as recruitment_specialties_code,
c.recruitment_specialties_rename, c.recruitment_specialties_recode
FROM mywork.job7 AS a
LEFT JOIN mywork.recruitment_specialties_recruitments0 AS b ON a.id = b.recruitment_id
LEFT JOIN mywork.recruitment_specialties0 AS c ON b.recruitment_specialty_id = c.id
#GROUP BY b.recruitment_id, b.recruitment_specialty_id
#GROUP BY b.recruitment_id
ORDER BY b.recruitment_id, b.recruitment_specialty_id;

#create all comb
CREATE TABLE mywork.recruitment_specialties1
SELECT A.*, B.recruitment_specialty_id, B.recruitment_specialties_name, B.recruitment_specialties_rename, 
B.recruitment_specialties_code, B.recruitment_specialties_recode, B.recruitment_specialty_type_id 
FROM 
(
/* generating combination of recruitment_id with ad1-ad24 */
SELECT DISTINCT (A.id), B.cnt FROM mywork.recruitment_specialties_recruitments as A join
(select 1 cnt union select 2 union select 3 union select 4 union select 5 ) B 
#union select 6 cnt union select 7 union select 8 union select 9 union select 10
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
SET @sql9 = NULL;
SET @sql10 = NULL;
SET @sql11 = NULL;
SET @sql12 = NULL;
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

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', recruitment_specialties_rename, NULL)) AS ',
      CONCAT('recruitment_specialties_rename_',cnt)
    )
  ) INTO @sql9
FROM mywork.recruitment_specialties1;

SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(cnt = ',
      cnt,
      ', recruitment_specialties_recode, NULL)) AS ',
      CONCAT('recruitment_specialties_recode_',cnt)
    )
  ) INTO @sql11
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
SET @sql10 = CONCAT('CREATE TABLE mywork.recruitment_specialties6 SELECT id, ', @sql9, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql10;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql12 = CONCAT('CREATE TABLE mywork.recruitment_specialties7 SELECT id, ', @sql11, ' FROM mywork.recruitment_specialties1 GROUP BY id');
PREPARE stmt FROM @sql12;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

#SHOW ERRORS;

CREATE TABLE mywork.recruitment_specialties8 
SELECT a.*,
    `recruitment_specialties3`.`recruitment_specialties_name_1`,
    `recruitment_specialties3`.`recruitment_specialties_name_2`,
    `recruitment_specialties3`.`recruitment_specialties_name_3`,
    `recruitment_specialties3`.`recruitment_specialties_name_4`,
    `recruitment_specialties3`.`recruitment_specialties_name_5`,
    `recruitment_specialties4`.`recruitment_specialties_code_1`,
    `recruitment_specialties4`.`recruitment_specialties_code_2`,
    `recruitment_specialties4`.`recruitment_specialties_code_3`,
    `recruitment_specialties4`.`recruitment_specialties_code_4`,
    `recruitment_specialties4`.`recruitment_specialties_code_5`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_1`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_2`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_3`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_4`,
    `recruitment_specialties5`.`recruitment_specialty_type_id_5`,
	`recruitment_specialties6`.`recruitment_specialties_rename_1`, 
    `recruitment_specialties6`.`recruitment_specialties_rename_2`, 
    `recruitment_specialties6`.`recruitment_specialties_rename_3`,
    `recruitment_specialties6`.`recruitment_specialties_rename_4`,
    `recruitment_specialties6`.`recruitment_specialties_rename_5`,
	`recruitment_specialties7`.`recruitment_specialties_recode_1`,
    `recruitment_specialties7`.`recruitment_specialties_recode_2`,
    `recruitment_specialties7`.`recruitment_specialties_recode_3`,
    `recruitment_specialties7`.`recruitment_specialties_recode_4`,
    `recruitment_specialties7`.`recruitment_specialties_recode_5`
#    `recruitment_specialties5`.`recruitment_specialty_type_id_6`,
#    `recruitment_specialties5`.`recruitment_specialty_type_id_7`,
#    `recruitment_specialties5`.`recruitment_specialty_type_id_8`,
#    `recruitment_specialties5`.`recruitment_specialty_type_id_9`,
#    `recruitment_specialties5`.`recruitment_specialty_type_id_10`
FROM mywork.recruitment_specialties2 as a 
JOIN mywork.recruitment_specialties3 ON a.id=`recruitment_specialties3`.id
JOIN mywork.recruitment_specialties4 ON a.id=`recruitment_specialties4`.id
JOIN mywork.recruitment_specialties5 ON a.id=`recruitment_specialties5`.id
JOIN mywork.recruitment_specialties6 ON a.id=`recruitment_specialties6`.id
JOIN mywork.recruitment_specialties7 ON a.id=`recruitment_specialties7`.id;

#add count
CREATE TABLE mywork.recruitment_specialties 
SELECT a.*, b.recruitment_specialties_cnt 
FROM mywork.recruitment_specialties8 AS a
LEFT JOIN
(
SELECT id,COUNT(recruitment_specialty_id) AS recruitment_specialties_cnt FROM mywork.recruitment_specialties_recruitments GROUP BY id
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
#    `recruitment_specialties`.`recruitment_specialty_id_6`,
#    `recruitment_specialties`.`recruitment_specialty_id_7`,
#    `recruitment_specialties`.`recruitment_specialty_id_8`,
#    `recruitment_specialties`.`recruitment_specialty_id_9`,
#    `recruitment_specialties`.`recruitment_specialty_id_10`,
    `recruitment_specialties`.`recruitment_specialties_name_1`,
    `recruitment_specialties`.`recruitment_specialties_name_2`,
    `recruitment_specialties`.`recruitment_specialties_name_3`,
    `recruitment_specialties`.`recruitment_specialties_name_4`,
    `recruitment_specialties`.`recruitment_specialties_name_5`,
    `recruitment_specialties`.`recruitment_specialties_rename_1`,
    `recruitment_specialties`.`recruitment_specialties_rename_2`,
    `recruitment_specialties`.`recruitment_specialties_rename_3`,
    `recruitment_specialties`.`recruitment_specialties_rename_4`,
    `recruitment_specialties`.`recruitment_specialties_rename_5`,
    `recruitment_specialties`.`recruitment_specialties_code_1`,
    `recruitment_specialties`.`recruitment_specialties_code_2`,
    `recruitment_specialties`.`recruitment_specialties_code_3`,
    `recruitment_specialties`.`recruitment_specialties_code_4`,
    `recruitment_specialties`.`recruitment_specialties_code_5`,
    `recruitment_specialties`.`recruitment_specialties_recode_1`,
    `recruitment_specialties`.`recruitment_specialties_recode_2`,
    `recruitment_specialties`.`recruitment_specialties_recode_3`,
    `recruitment_specialties`.`recruitment_specialties_recode_4`,
    `recruitment_specialties`.`recruitment_specialties_recode_5`,
    `recruitment_specialties`.`recruitment_specialty_type_id_1`,
    `recruitment_specialties`.`recruitment_specialty_type_id_2`,
    `recruitment_specialties`.`recruitment_specialty_type_id_3`,
    `recruitment_specialties`.`recruitment_specialty_type_id_4`,
    `recruitment_specialties`.`recruitment_specialty_type_id_5`
#    `recruitment_specialties`.`recruitment_specialty_type_id_6`,
#    `recruitment_specialties`.`recruitment_specialty_type_id_7`,
#    `recruitment_specialties`.`recruitment_specialty_type_id_8`,
#    `recruitment_specialties`.`recruitment_specialty_type_id_9`,
#    `recruitment_specialties`.`recruitment_specialty_type_id_10`
FROM mywork.job7 AS a
LEFT JOIN mywork.recruitment_specialties  ON a.id = `recruitment_specialties`.id;

ALTER TABLE mywork.job8 ADD campus_id INT FIRST, ADD ad_cnt INT;


UPDATE mywork.job8
SET campus_id = num
WHERE id IS NOT NULL;

UPDATE mywork.job8 a
LEFT JOIN 
(
SELECT recruitment_id, COUNT(id) as ad_cnt FROM ad_sources GROUP BY recruitment_id
) b 
ON a.id = b.recruitment_id
SET a.ad_cnt = b.ad_cnt;


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


CALL ucrecruit.add_campus('uci', 1);
CALL ucrecruit_ucb.add_campus('ucb', 2);
CALL ucrecruit_ucd.add_campus('ucd', 3);
CALL ucrecruit_ucla.add_campus('ucla', 4);
CALL ucrecruit_ucm.add_campus('ucm', 5);
CALL ucrecruit_ucr.add_campus('ucr', 6);
CALL ucrecruit_ucsb.add_campus('ucsb', 7);
CALL ucrecruit_ucsc.add_campus('ucsc', 8);
CALL ucrecruit_ucsd.add_campus('ucsd', 9);
CALL ucrecruit_ucsf.add_campus('ucsf', 10);


#CREATE SCHEMA final;
DROP TABLE IF EXISTS final.job_all0;

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

/*
DROP TABLE IF EXISTS final.job_all1;
#make a copy
CREATE TABLE final.job_all1 SELECT * FROM final.job_all0 ;
#drop columns unwanted 
ALTER TABLE final.job_all1 
DROP recruitment_title_name_1, DROP recruitment_title_name_2, DROP recruitment_title_name_3, 
DROP recruitment_title_name_4, DROP recruitment_title_name_5, DROP recruitment_title_name_6,
DROP recruitment_title_name_7, DROP recruitment_title_name_8, DROP recruitment_title_name_9,
DROP recruitment_title_name_10, DROP recruitment_title_name_11, DROP recruitment_title_name_12,
DROP recruitment_title_name_13, DROP recruitment_title_name_14, DROP recruitment_title_name_15;
#DROP recruitment_specialties_name_1, DROP recruitment_specialties_name_2,
#DROP recruitment_specialties_name_3, DROP recruitment_specialties_name_4,
#DROP recruitment_specialties_name_5;
*/

#join appfile table with application files info
DROP TABLE IF EXISTS final.job_all;
CREATE TABLE final.job_all
SELECT a.* ,
    `appfile`.`cv`, `appfile`.`cv_required`,
    `appfile`.`biosketch`, `appfile`.`biosketch_required`,
    `appfile`.`publist`, `appfile`.`publist_required`,
    `appfile`.`cover`, `appfile`.`cover_required`,
    `appfile`.`resstmnt`, `appfile`.`resstmnt_required`,
    `appfile`.`resfuture`, `appfile`.`resfuture_required`,
    `appfile`.`resproposal`, `appfile`.`resproposal_required`,
    `appfile`.`teachstmnt`, `appfile`.`teachstmnt_required`,
    `appfile`.`mentorstmnt`, `appfile`.`mentorstmnt_required`,
    `appfile`.`teacheval`, `appfile`.`teacheval_required`,
    `appfile`.`teachdocs`, `appfile`.`teachdocs_required`,
    `appfile`.`ressample`, `appfile`.`ressample_required`,
    `appfile`.`dissertation`, `appfile`.`dissertation_required`,
    `appfile`.`additional`, `appfile`.`additional_required`,
    `appfile`.`creative`, `appfile`.`creative_required`,
    `appfile`.`transcript`, `appfile`.`transcript_required`,
    `appfile`.`degreeproof`, `appfile`.`degreeproof_required`,
    `appfile`.`divstmnt`, `appfile`.`divstmnt_required`,
    `appfile`.`reflist`, `appfile`.`reflist_required`,
    `appfile`.`refletter`, `appfile`.`refletter_required`,
    `appfile`.`certification`, `appfile`.`certification_required`,
    `appfile`.`application`, `appfile`.`application_required`,
    `appfile`.`grantlist`, `appfile`.`grantlist_required`,
    `appfile`.`patentlist`, `appfile`.`patentlist_required`,
    `appfile`.`software`, `appfile`.`software_required`,
    `appfile`.`extension`, `appfile`.`extension_required`,
    `appfile`.`credential`, `appfile`.`credential_required`,
    `appfile`.`clinical`, `appfile`.`clinical_required`,
    `appfile`.`salaryinfo`, `appfile`.`salaryinfo_required`,
    `appfile`.`training`, `appfile`.`training_required`,
    `appfile`.`photoid`, `appfile`.`photoid_required`,
    `appfile`.`leadadmin`, `appfile`.`leadadmin_required`,
    `appfile`.`other`, `appfile`.`other_required`
FROM final.job_all0 a
LEFT JOIN `final`.`appfile`
ON a.campus_id = `appfile`.`campus_id` AND a.id =  `appfile`.`id`;



