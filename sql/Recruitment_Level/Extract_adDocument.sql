

USE mywork;
DROP PROCEDURE IF EXISTS ad_doc;

DELIMITER $$
CREATE PROCEDURE ad_doc(db_name VARCHAR(15), num INT)
BEGIN

SET @DB = db_name;
SET @CAMPUS_ID = num;
SET @sql = NULL;
SET @sql = CONCAT("CREATE TABLE mywork.ad", @CAMPUS_ID, " 
SELECT A.campus_id, A.academic_year_id, A.job_number, B.id as recruitment_id, C.* FROM
(SELECT * FROM mywork.job_ad WHERE campus_id=@CAMPUS_ID) A
LEFT JOIN ", @DB, ".recruitments B ON A.job_number = B.job_number
LEFT JOIN 
(SELECT * FROM ", @DB, ".uploaded_files WHERE type = 'AdDocument') C ON B.id = C.resource_id;");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;

CALL ad_doc("ucrecruit",1);
CALL ad_doc("ucrecruit_ucb",2);
CALL ad_doc("ucrecruit_ucd",3);
CALL ad_doc("ucrecruit_ucla",4);
CALL ad_doc("ucrecruit_ucm",5);
CALL ad_doc("ucrecruit_ucr",6);
CALL ad_doc("ucrecruit_ucsb",7);
CALL ad_doc("ucrecruit_ucsc",8);
CALL ad_doc("ucrecruit_ucsd",9);
CALL ad_doc("ucrecruit_ucsf",10);

#row combine
DROP PROCEDURE IF EXISTS rowbin;
DELIMITER $$
CREATE PROCEDURE rowbin()
BEGIN
	#DECLARE i INT;
	#DECLARE str VARCHAR(255);
    SET @i = 1;
    SET @str = '';
    
	WHILE @i < 10 DO
		SET @str = CONCAT(@str, " SELECT * FROM mywork.ad", @i," UNION ALL");
        #SELECT str;
		SET @i := @i + 1;
        #SELECT i;
	END WHILE;
    
    SET @str = CONCAT(@str, " SELECT * FROM mywork.ad", @i);

	SET @sql = CONCAT("CREATE TABLE mywork.ad_all ", @str, ";");
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;

CALL rowbin();

ALTER TABLE mywork.ad_all DROP id, DROP created_by_user_id, DROP application_file_type_id, DROP file_content_id, 
DROP application_id, DROP ad_source_id, DROP resource_type, DROP resource_id, MODIFY recruitment_id INT AFTER job_number;


SHOW ERRORS;

