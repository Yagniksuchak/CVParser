
USE ucrecruit;

DROP SCHEMA `mywork`;
CREATE SCHEMA `mywork`;

#select recruitments table of academic year 2014 and 2015
CREATE TABLE mywork.job1 SELECT * FROM recruitments
WHERE academic_year_id in (14, 15); #change to 2014 and 2015
ALTER TABLE mywork.job1 
DROP created_at, DROP updated_at, DROP created_by_user_id;

#merge pivot descriptions table
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
LEFT JOIN `uci`.`descriptions` ON a.id =  `descriptions`.`recruitment_id`;


#merge herc_categories herc_divisions tables
CREATE TABLE mywork.job3 SELECT a.*, b.herc_division_id 
FROM mywork.job2 AS a
LEFT JOIN herc_categories AS b ON a.herc_category_id = b.id;
ALTER TABLE mywork.job3 MODIFY herc_division_id INT AFTER herc_category_id ;


#merge hiring_types
#link diversity_types through hiring_types

#merge search_plans table
CREATE TABLE mywork.job4
SELECT a.*, b.id AS search_plan_id
FROM mywork.job3 AS a 
LEFT JOIN search_plans AS b
ON a.id = b.recruitment_id;

#add required_reference_types through positions table
CREATE TABLE mywork.job5
SELECT a.*, b.required_reference_type_id
FROM mywork.job4 AS a
LEFT JOIN positions AS b ON b.recruitment_id=a.id;


################################################################################
##read Pivot_Listings.sql to creat mywork.listings
################################################################################
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
UPDATE mywork.job8 SET campus = 'uci' WHERE id IS NOT NULL;

SELECT * FROM mywork.job8;

################################################################################
##read Pivot_adsources.sql to creat mywork.ad_source
################################################################################
#merge ad_sources table
CREATE TABLE mywork.job2 SELECT a.*, 
b.ad1, b.ad2, b.ad3, b.ad4, b.ad5, b.ad6, b.ad7, b.ad8, b.ad9, b.ad10, b.ad11, b.ad12, 
b.ad13, b.ad14, b.ad15, b.ad16, b.ad17, b.ad18, b.ad19, b.ad20, b.ad21, b.ad22, b.ad23 
FROM mywork.job1 AS a
LEFT JOIN mywork.ad_source AS b
ON a.id = b.recruitment_id
GROUP BY a.id;


#export diversity_data as seperate dataset
#merge diversity_data through recruitment_specialty_id and diversity_type_id (8,9)
CREATE TABLE mywork.diversity_data SELECT * FROM diversity_data ORDER BY recruitment_specialty_id;
ALTER TABLE mywork.diversity_data DROP id;

SELECT * FROM mywork.diversity_data;

##merge offers through recruitment_title_id


###################################
##Create seperate committee table##
###################################
##merge user_roles table through resouce_id
##merge department_roles table through resouce_id and inherited_from_department_role_id
CREATE TABLE mywork.committee1
SELECT c.*, d.department_id, d.role_id as department_role
FROM
(
SELECT a.id, a.committee_id, b.user_id, b.role_id as user_role, b.inherited_from_department_role_id
FROM mywork.job8 AS a
LEFT JOIN user_roles AS b on a.committee_id = b.resource_id WHERE b.resource_type='Committee'
) c
LEFT JOIN department_roles AS d on c.committee_id = d.resource_id and c.inherited_from_department_role_id = d.id;

#merge users table to get user info
CREATE TABLE mywork.committee2
SELECT a.*, b.department, b.department_code, b.faculty_level
FROM mywork.committee1 AS a
LEFT JOIN users AS b
ON a.user_id = b.campus_id;

ALTER TABLE mywork.committee2 
DROP inherited_from_department_role_id, DROP department_id;

#merge department table to get school and department through department_code
CREATE TABLE mywork.committee
SELECT a.*, b.id as department_id, b.school_id
FROM mywork.committee2 as a
LEFT JOIN departments as b
ON a.department_code = b.external_id
ORDER BY a.id;

ALTER TABLE mywork.committee
MODIFY department_id INT AFTER user_role,
MODIFY school_id INT AFTER department_code;

SELECT * FROM mywork.committee;


######################
###survey questions###
######################
CREATE TABLE mywork.surveys
SELECT b.survey_id, c.survey_question_id, b.question, c.position, c.`key`,c.label,c.description,c.descriptor
FROM survey_questions AS b 
LEFT JOIN survey_options AS c on b.id=c.survey_question_id
having b.survey_id=3;
#survey responses
CREATE TABLE mywork.survey_responses
SELECT a.* 
FROM survey_responses as a
INNER JOIN mywork.job5 as b
on a.recruitment_id = b.id
order by a.recruitment_id;


SELECT * INTO OUTFILE 'data.txt'
  FIELDS TERMINATED BY ','
  FROM table2;
  
LOAD DATA INFILE 'data.txt' INTO TABLE tbl_name
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;


LOAD DATA INFILE '/Users/xuxinyan/Documents/GSR/UC_Recruit/STEM/Committee_UCI.csv' INTO TABLE mywork.test
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;

#add a unique index on combination of 3 cols
ALTER IGNORE TABLE jobs
ADD UNIQUE INDEX idx_name (site_id, title, company);
#another solution
DELETE t1 FROM my_table t1, my_table t2 WHERE t1.id < t2.id AND t1.my_field = t2.my_field AND t1.my_field_2 = t2.my_field_2 ;



/*
only select column names of interest
SET @sql = CONCAT('SELECT ', (SELECT REPLACE(GROUP_CONCAT(COLUMN_NAME),  '<columns_to_delete>,', '') 
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '<table>'   AND TABLE_SCHEMA = '<database>'), ' FROM <table>');

    PREPARE stmt1 FROM @sql;
   EXECUTE stmt1;
*/
