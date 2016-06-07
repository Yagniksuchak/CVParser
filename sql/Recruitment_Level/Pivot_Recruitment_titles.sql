#merge mywork.recruitment_titles_recruitments and recruitment_titles table
CREATE TABLE mywork.recruitment_titles_recruitments0 
SELECT a.*, b.name, b.code 
FROM recruitment_titles_recruitments as a 
LEFT JOIN recruitment_titles as b ON a.recruitment_title_id = b.id 
CROSS JOIN mywork.job6 as c ON a.recruitment_id = c.id
order by a.recruitment_id;

CREATE TABLE mywork.recruitment_titles_recruitments 
SELECT DISTINCT recruitment_title_id, recruitment_id, name, code
FROM mywork.recruitment_titles_recruitments0 GROUP BY recruitment_title_id;


SELECT recruitment_id, COUNT(recruitment_title_id) as cnt FROM mywork.recruitment_titles_recruitments GROUP BY recruitment_id;


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
