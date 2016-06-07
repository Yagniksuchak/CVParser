

/*Another way to create a table with sequence value
CREATE TABLE mywork.temp3  (
  `source` int(11) DEFAULT NULL 
) ENGINE=InnoDB ;
INSERT INTO mywork.temp3 VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14) ,(15)
, (16), (17), (18), (19), (20), (21), (22), (23);
*/
CREATE TABLE mywork.ad_source00
SELECT a.id AS recruitment_id, b.id, b.name FROM mywork.job1 AS a
LEFT JOIN ad_sources AS b ON a.id = b.recruitment_id;

show errors;
SELECT recruitment_id, COUNT(id) FROM mywork.ad_source00 GROUP BY recruitment_id;

CREATE TABLE mywork.ad_source0 
SELECT A.*, B.name FROM 
(
/* generating combination of recruitment_id with ad1-ad24 */
SELECT DISTINCT (A.recruitment_id), B.source FROM mywork.ad_source00 as A join
(select 1 source union select 2 union select 3 union select 4 union select 5 union
select 6 union select 7 union select 8 union select 9 union select 10
union select 11 union select 12 union select 13 union select 14 union select 15 union select 16
union select 17 union select 18 union select 19 union select 20 union select 21 union select 22 union select 23) B 
order by A.recruitment_id, B.source 
) A
LEFT JOIN /* Combinations of id with ad left join with ad source name*/
(
SELECT 
    x.*,
    @cumcnt:=IF(@previous = x.recruitment_id, @cumcnt, 0) + 1 cnt, /*Calculate cumlative count by id*/
    @previous:=x.recruitment_id pre_id
FROM
    (SELECT * FROM mywork.ad_source00 ORDER BY recruitment_id) x,
    (SELECT @cnt:=0, @cumcnt:=0) vals
) B
ON A.recruitment_id = B.recruitment_id AND A.source = B.cnt;

/*Pivot ad_source table*/
/* Auto method  */ 

SET group_concat_max_len=1500000;

SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'GROUP_CONCAT(IF(source = ',
      source,
      ', name, NULL)) AS ',
      CONCAT('ad',source)
    )
  ) INTO @sql
FROM mywork.ad_source0;
SET @sql = CONCAT('CREATE TABLE mywork.ad_source SELECT recruitment_id, ', @sql, ' FROM mywork.ad_source0 GROUP BY recruitment_id');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

show warnings ;
show errors;

/*Manual method
create table mywork.ad_source1
SELECT  
  recruitment_id, 
  GROUP_CONCAT(if(source = 1, name, NULL)) AS ad1,
  GROUP_CONCAT(if(source = 2, name, NULL)) AS ad2,
  GROUP_CONCAT(if(source = 3, name, NULL)) AS ad3,
  GROUP_CONCAT(if(source = 4, name, NULL)) AS ad4,
  GROUP_CONCAT(if(source = 5, name, NULL)) AS ad5,
  GROUP_CONCAT(if(source = 6, name, NULL)) AS ad6,
  GROUP_CONCAT(if(source = 7, name, NULL)) AS ad7,
  GROUP_CONCAT(if(source = 8, name, NULL)) AS ad8,
  GROUP_CONCAT(if(source = 9, name, NULL)) AS ad9,
  GROUP_CONCAT(if(source = 10, name, NULL)) AS ad10,
  GROUP_CONCAT(if(source = 11, name, NULL)) AS ad11,
  GROUP_CONCAT(if(source = 12, name, NULL)) AS ad12,
  GROUP_CONCAT(if(source = 13, name, NULL)) AS ad13,
  GROUP_CONCAT(if(source = 14, name, NULL)) AS ad14,
  GROUP_CONCAT(if(source = 15, name, NULL)) AS ad15,
  GROUP_CONCAT(if(source = 16, name, NULL)) AS ad16,
  GROUP_CONCAT(if(source = 17, name, NULL)) AS ad17,
  GROUP_CONCAT(if(source = 18, name, NULL)) AS ad18,
  GROUP_CONCAT(if(source = 19, name, NULL)) AS ad19,
  GROUP_CONCAT(if(source = 20, name, NULL)) AS ad20,
  GROUP_CONCAT(if(source = 21, name, NULL)) AS ad21,
  GROUP_CONCAT(if(source = 22, name, NULL)) AS ad22,
  GROUP_CONCAT(if(source = 23, name, NULL)) AS ad23
FROM mywork.ad_source
GROUP BY recruitment_id;
*/
    
 