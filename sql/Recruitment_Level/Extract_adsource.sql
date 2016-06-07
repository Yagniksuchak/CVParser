/*
CREATE TABLE final.ad_source_index 
(source INT(4) AUTO_INCREMENT PRIMARY KEY)
ENGINE = INNODB;
*/

/*Another way to create a table with sequence value
CREATE TABLE final.ad_source_index (
  `source` int(11) DEFAULT NULL 
) ENGINE=InnoDB ;
INSERT INTO mywork.temp3 VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14) ,(15)
, (16), (17), (18), (19), (20), (21), (22), (23);
*/
USE final;

DROP PROCEDURE IF EXISTS extract_ad;

DELIMITER $$
CREATE PROCEDURE extract_ad(db_name VARCHAR(15),campus_name VARCHAR(15) , num INT)
BEGIN

DROP TABLE IF EXISTS mywork.ad_source00, mywork.ad_source0, mywork.ad_source;

SET @db = db_name;
SET @campus = campus_name;
SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE mywork.ad_source00
SELECT a.id AS recruitment_id, b.id, b.name FROM 
(
SELECT * FROM `", @db, "`.recruitments WHERE academic_year_id in (14, 15)
) a
LEFT JOIN `", @db, "`.ad_sources AS b 
ON a.id = b.recruitment_id
ORDER BY a.id, b.name;
");

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


CREATE TABLE mywork.ad_source0 
SELECT A.*, B.name FROM 
(
/* generating combination of recruitment_id with ad1-ad76 */
SELECT DISTINCT (A.recruitment_id), B.source FROM mywork.ad_source00 as A join
final.ad_source_index B 
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


ALTER TABLE mywork.ad_source ADD campus_id INT FIRST, ADD ad_cnt INT AFTER recruitment_id;

UPDATE mywork.ad_source as A
JOIN
(
SELECT recruitment_id, COUNT(id) as ad_cnt FROM mywork.ad_source00 GROUP BY recruitment_id
) B 
ON A.recruitment_id = B.recruitment_id
SET A.ad_cnt = B.ad_cnt, A.campus_id=num;

SET @sql = NULL;
SET @sql = CONCAT("
DROP TABLE IF EXISTS  `", @campus, "`.ad_source; 
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE `", @campus, "`.ad_source SELECT * FROM mywork.ad_source;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;

CALL final.extract_ad('ucrecruit', 'uci', 1);
CALL final.extract_ad('ucrecruit_ucb', 'ucb', 2);
CALL final.extract_ad('ucrecruit_ucd', 'ucd', 3);
CALL final.extract_ad('ucrecruit_ucla', 'ucla', 4);
CALL final.extract_ad('ucrecruit_ucm', 'ucm', 5);
CALL final.extract_ad('ucrecruit_ucr', 'ucr', 6);
CALL final.extract_ad('ucrecruit_ucsb', 'ucsb', 7);
CALL final.extract_ad('ucrecruit_ucsc', 'ucsc', 8);
CALL final.extract_ad('ucrecruit_ucsd', 'ucsd', 9);
CALL final.extract_ad('ucrecruit_ucsf', 'ucsf', 10);


show warnings ;
show errors;

DROP TABLE IF EXISTS final.ad_source;

CREATE TABLE final.ad_source
SELECT * FROM uci.ad_source UNION ALL
SELECT * FROM ucb.ad_source UNION ALL
SELECT * FROM ucd.ad_source UNION ALL
SELECT * FROM ucla.ad_source UNION ALL
SELECT * FROM ucm.ad_source UNION ALL
SELECT * FROM ucr.ad_source UNION ALL
SELECT * FROM ucsb.ad_source UNION ALL
SELECT * FROM ucsc.ad_source UNION ALL
SELECT * FROM ucsd.ad_source UNION ALL
SELECT * FROM ucsf.ad_source 
;

