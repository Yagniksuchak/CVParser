
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

DROP PROCEDURE IF EXISTS diversity_data;


DELIMITER $$
CREATE PROCEDURE diversity_data(campus_name VARCHAR(15), num INT)
BEGIN
SET @db = campus_name;

SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE mywork.diversity_data_",@db , "0 
SELECT
  recruitment_specialty_id, diversity_type_id,
  GROUP_CONCAT(if(option_descriptor = 'african', value, NULL)) AS african,
  GROUP_CONCAT(if(option_descriptor = 'asian', value, NULL)) AS asian,
  GROUP_CONCAT(if(option_descriptor = 'latino', value, NULL)) AS latino,
  GROUP_CONCAT(if(option_descriptor = 'minority', value, NULL)) AS minority,
  GROUP_CONCAT(if(option_descriptor = 'native_american', value, NULL)) AS native_american,
  GROUP_CONCAT(if(option_descriptor = 'other', value, NULL)) AS other,
  GROUP_CONCAT(if(option_descriptor = 'white', value, NULL)) AS white,
  GROUP_CONCAT(if(option_descriptor = 'female', value, NULL)) AS female,
  GROUP_CONCAT(if(option_descriptor = 'male', value, NULL)) AS male
FROM diversity_data
GROUP BY recruitment_specialty_id, diversity_type_id;");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


SET @sql = NULL;
SET @sql = CONCAT("
CREATE TABLE mywork.diversity_data_", @db, 
" SELECT A.*, B.recruitment_specialty_type_id, C.name as recruitment_specialty_type_name, 
B.name as recruitment_specialty_name, B.code as recruitment_specialty_code,
D.diversity_data_set_id, D.hiring_type_id, D.name as diversity_type_name, D.description as NORC, 
E.name as hiring_type_name
FROM mywork.diversity_data_",@db, "0 A
LEFT JOIN recruitment_specialties B ON A.recruitment_specialty_id = B.id
LEFT JOIN recruitment_specialty_types C ON B.recruitment_specialty_type_id=C.id
LEFT JOIN diversity_types D ON A.diversity_type_id=D.id
LEFT JOIN hiring_types E ON D.hiring_type_id = E.id;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
ALTER TABLE mywork.diversity_data_", @db, " ADD campus_id INT FIRST, MODIFY hiring_type_id INT AFTER NORC;
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = NULL;
SET @sql = CONCAT("
UPDATE mywork.diversity_data_", @db, " SET campus_id=",num, ";
");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;

CALL ucrecruit.diversity_data('uci', 1);
CALL ucrecruit_ucb.diversity_data('ucb', 2);
CALL ucrecruit_ucd.diversity_data('ucd', 3);
CALL ucrecruit_ucla.diversity_data('ucla', 4);
CALL ucrecruit_ucm.diversity_data('ucm', 5);
CALL ucrecruit_ucr.diversity_data('ucr', 6);
CALL ucrecruit_ucsb.diversity_data('ucsb', 7);
CALL ucrecruit_ucsc.diversity_data('ucsc', 8);
CALL ucrecruit_ucsd.diversity_data('ucsd', 9);
CALL ucrecruit_ucsf.diversity_data('ucsf', 10);

CREATE TABLE mywork.diversity_data_all
SELECT * FROM mywork.diversity_data_uci UNION ALL
SELECT * FROM mywork.diversity_data_ucb UNION ALL
SELECT * FROM mywork.diversity_data_ucd UNION ALL
SELECT * FROM mywork.diversity_data_ucla UNION ALL
SELECT * FROM mywork.diversity_data_ucm UNION ALL
SELECT * FROM mywork.diversity_data_ucr UNION ALL
SELECT * FROM mywork.diversity_data_ucsb UNION ALL
SELECT * FROM mywork.diversity_data_ucsc UNION ALL
SELECT * FROM mywork.diversity_data_ucsd UNION ALL
SELECT * FROM mywork.diversity_data_ucsf; 
#ORDER BY african, asian, latino, minority, native_american, other, white, female, male;

SELECT * FROM mywork.diversity_data_all;
ALTER TABLE mywork.diversity_data_all 
DROP COLUMN hiring_type_name, DROP COLUMN NORC, 
DROP COLUMN diversity_type_name, DROP COLUMN recruitment_specialty_type_name;

#random stuff starts
CREATE TABLE mywork.diversity_cnt
SELECT african, asian, latino, minority, native_american, other, white, female, male, recruitment_specialty_type_name, NORC, COUNT(*) as Rep
FROM mywork.diversity_data_all
GROUP BY african, asian, latino, minority, native_american, other, white, female, male
ORDER BY african, asian, latino, minority, native_american, other, white, female, male;

#DROP TABLE IF EXISTS mywork.diversity_data_uci1;

CREATE TABLE mywork.test
SELECT campus_id, recruitment_specialty_id, diversity_type_id, african, asian, latino, minority, native_american, other, white, female, male, 
recruitment_specialty_type_name, recruitment_specialty_type,diversity_type_name, NORC, hiring_type_name 
FROM mywork.diversity_data_all WHERE recruitment_specialty_type_name='Accounting'
ORDER BY recruitment_specialty_type_name, african, asian, latino, minority, native_american, other, white, female, male, diversity_type_name;

SELECT * FROM mywork.test;

CREATE TABLE mywork.test_cnt
SELECT african, asian, latino, minority, native_american, other, white, female, male, recruitment_specialty_type_name, NORC, COUNT(*) as Rep
FROM mywork.test
GROUP BY african, asian, latino, minority, native_american, other, white, female, male;

ALTER TABLE mywork.test_cnt ADD COLUMN Id INT NOT NULL AUTO_INCREMENT FIRST, ADD primary KEY Id(Id);

SELECT * FROM mywork.test_cnt ;

INSERT INTO mywork.test_cnt (Id, Rep) VALUE (200, 400);

SELECT DISTINCT norc FROM mywork.diversity_data_uci;

CREATE TABLE mywork.numbers 
(num int NOT NULL AUTO_INCREMENT,
PRIMARY KEY (num));
DROP PROCEDURE IF EXISTS auto;
DELIMITER $$  
CREATE PROCEDURE auto()
BEGIN
	DECLARE a INT Default 1 ;
	simple_loop: LOOP         
		INSERT INTO mywork.numberS (num) VALUES(a);
		SET a=a+1;
		IF a=1001 THEN LEAVE simple_loop;
		END IF;
	END LOOP simple_loop;
END$$
DELIMITER ;
CALL auto();
SELECT * FROM mywork.numbers;

CREATE TABLE mywork.combination
(num int NOT NULL);

INSERT INTO mywork.combination (num)
SELECT a.id
FROM mywork.test_cnt a, mywork.numbers b
WHERE b.num <= a.rep;

SELECT num, COUNT(*) FROM mywork.combination GROUP BY num;
/*
UPDATE mywork.diversity_data_uci1 
SET norc = '1986-2000 Campus data; 2006 Health Sciences data' WHERE norc = 'campus: 1986-2000, medical: 2006 data';
UPDATE mywork.diversity_data_uci1 
SET norc =	'2001-2005 Campus data; 2006 Health Sciences data' WHERE norc = 'campus: 2001-2005, medical: 2006 data';
*/

SHOW ERRORS;