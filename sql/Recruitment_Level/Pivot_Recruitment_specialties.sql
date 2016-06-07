
#merge mywork.recruitment_specialties_recruitments and recruitment_specialties table
CREATE TABLE mywork.recruitment_specialties_recruitments
SELECT a.id, b.recruitment_specialty_id, c.recruitment_specialty_type_id, 
c.name as recruitment_specialties_name, c.code as recruitment_specialties_code
FROM mywork.job7 AS a
LEFT JOIN recruitment_specialties_recruitments AS b ON a.id = b.recruitment_id
LEFT JOIN recruitment_specialties AS c ON b.recruitment_specialty_id = c.id;

#check max count
SELECT id,COUNT(id) AS cnt FROM mywork.recruitment_specialties_recruitments GROUP BY id;

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

show errors