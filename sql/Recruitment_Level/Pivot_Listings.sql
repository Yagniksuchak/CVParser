CREATE TABLE mywork.listings0 
SELECT a.id, b.department_id, b.school_id
FROM mywork.job5 AS a 
LEFT JOIN listings AS b ON a.id = b.recruitment_id;

#create table with listing count col
CREATE TABLE mywork.list_cnt
SELECT id, COUNT(id) as cnt FROM mywork.listings0
GROUP BY id;

SELECT * FROM mywork.list_cnt;

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
