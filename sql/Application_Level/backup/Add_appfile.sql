USE final;

#position_id link to position table ( has recruitment_id)

DROP TABLE IF EXISTS mywork.appfilecnt, mywork.appfile0, mywork.appfile1, mywork.appfile2, mywork.appfile3, final.appfile;

#list all ids
CREATE TABLE mywork.appfile0
SELECT campus_id, id, job_number FROM final.job_all1;

#combine ids with all upload files
CREATE TABLE mywork.appfile1
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 1
) uci UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucb.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucb.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 2
) ucb UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucd.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucd.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 3
) ucd UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucla.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucla.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 4
) ucla
UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucm.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucm.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 5
) ucm UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucr.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucr.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 6
) ucr UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucsb.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucsb.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 7
) ucsb UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type  FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucsc.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucsc.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 8
) ucsc UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucsd.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucsd.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 9
) ucsd UNION ALL
SELECT * FROM
(
SELECT a.*, c.name , c.is_required, c.file_type FROM mywork.appfile0 a
LEFT JOIN ucrecruit_ucsf.positions b ON a.id = b.recruitment_id
LEFT JOIN ucrecruit_ucsf.application_file_types c ON b.id = c.position_id
WHERE a.campus_id = 10
) ucsf;

SELECT * FROM mywork.appfile1 where campus_id=6 and id=141 ;

SELECT * FROM mywork.appfile1 where campus_id=1 and id=1947 ;

#total count	
CREATE TABLE mywork.appfilecnt
SELECT b.campus_id, b.id, b.job_number, 
sum(b.cv) as cv, sum(b.biosketch) as biosketch, sum(b.publist) as publist, 
sum(b.cover) as cover, sum(b.resstmnt) as resstmnt, sum(b.resfuture) as resfuture, 
sum(b.resproposal) as resproposal, sum(b.teachstmnt) as teachstmnt, sum(b.mentorstmnt) as mentorstmnt,  
sum(b.teacheval) as teacheval,	sum(b.teachdocs) as teachdocs, sum(b.ressample) as ressample,
sum(b.dissertation) as dissertation, sum(b.additional) as additional, 
sum(b.creative) as creative, sum(b.transcript) as transcript, sum(b.degreeproof) as degreeproof,
sum(b.divstmnt) as divstmnt, sum(b.reflist) as reflist, sum(b.refletter) as refletter,
sum(b.certification) as certification, sum(b.application) as application,  sum(b.grantlist) as grantlist,
sum(b.patentlist) as patentlist, sum(b.software) as software, sum(b.extension) as extension,
sum(b.credential) as credential, sum(b.clinical) as clinical, sum(b.salaryinfo) as salaryinfo,
sum(b.training) as training, sum(b.photoid) as photoid, sum(b.leadadmin) as leadadmin,
sum(b.other) as other
FROM
(
SELECT a.*, `application_file_type`.`cv`,
    `application_file_type`.`biosketch`,
    `application_file_type`.`publist`,
    `application_file_type`.`cover`,
    `application_file_type`.`resstmnt`,
    `application_file_type`.`resfuture`,
    `application_file_type`.`resproposal`,
    `application_file_type`.`teachstmnt`,
    `application_file_type`.`mentorstmnt`,
    `application_file_type`.`teacheval`,
    `application_file_type`.`teachdocs`,
    `application_file_type`.`ressample`,
    `application_file_type`.`dissertation`,
    `application_file_type`.`additional`,
    `application_file_type`.`creative`,
    `application_file_type`.`transcript`,
    `application_file_type`.`degreeproof`,
    `application_file_type`.`divstmnt`,
    `application_file_type`.`reflist`,
    `application_file_type`.`refletter`,
    `application_file_type`.`certification`,
    `application_file_type`.`application`,
    `application_file_type`.`grantlist`,
    `application_file_type`.`patentlist`,
    `application_file_type`.`software`,
    `application_file_type`.`extension`,
    `application_file_type`.`credential`,
    `application_file_type`.`clinical`,
    `application_file_type`.`salaryinfo`,
    `application_file_type`.`training`,
    `application_file_type`.`photoid`,
    `application_file_type`.`leadadmin`,
     `application_file_type`.`other`
FROM mywork.appfile1 a LEFT JOIN final.application_file_type
ON a.name = `application_file_type`.name AND a.file_type = `application_file_type`.file_type
ORDER BY a.campus_id, a.id, a.name
)b 
GROUP BY b.campus_id, b.id;

#check required
CREATE TABLE mywork.appfile2
SELECT a.*, b.filename
FROM mywork.appfile1 a
LEFT JOIN t_application_file_type b 
ON a.name = b.name AND a.file_type=b.file_type;


#de-dupulicates
CREATE TABLE mywork.appfile3
SELECT a.campus_id, a.id, a.job_number, a.is_required, a.filename FROM
(
SELECT * FROM mywork.appfile2 
ORDER BY campus_id, id, filename, is_required DESC 
) a 
GROUP BY a.campus_id, a.id, a.job_number, a.filename;


SELECT * FROM mywork.appfile3 where id=184 and campus_id=7;

#0 not_asked, 1 optional, 2 required
UPDATE mywork.appfile3
SET is_required=2 WHERE is_required=1;
UPDATE mywork.appfile3
SET is_required=1 WHERE is_required=0;

#pivot required col
SET group_concat_max_len=1500000;

SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'SUM(IF(filename = "',
      filename,
      '", is_required, 0)) AS ',
      CONCAT(filename, '_required')
    )
  ) INTO @sql
FROM mywork.appfile3;
SET @sql = CONCAT('CREATE TABLE mywork.appfile4 SELECT campus_id, id, job_number, ', @sql, ' FROM mywork.appfile3 GROUP BY campus_id, id');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT * FROM mywork.appfilecnt;
SELECT * FROM mywork.appfile4 where id=184 and campus_id=7;

#merge count with required
CREATE TABLE final.appfile
SELECT a.*,  
   `appfile4`.`additional_required`,
    `appfile4`.`cover_required`,
    `appfile4`.`cv_required`,
    `appfile4`.`refletter_required`,
    `appfile4`.`resstmnt_required`,
    `appfile4`.`teachstmnt_required`,
    `appfile4`.`teacheval_required`,
    `appfile4`.`ressample_required`,
    `appfile4`.`reflist_required`,
    `appfile4`.`degreeproof_required`,
    `appfile4`.`teachdocs_required`,
    `appfile4`.`other_required`,
    `appfile4`.`creative_required`,
    `appfile4`.`biosketch_required`,
    `appfile4`.`publist_required`,
    `appfile4`.`resproposal_required`,
    `appfile4`.`dissertation_required`,
    `appfile4`.`divstmnt_required`,
    `appfile4`.`leadadmin_required`,
    `appfile4`.`transcript_required`,
    `appfile4`.`resfuture_required`,
    `appfile4`.`application_required`,
    `appfile4`.`clinical_required`,
    `appfile4`.`extension_required`,
    `appfile4`.`mentorstmnt_required`,
    `appfile4`.`certification_required`,
    `appfile4`.`salaryinfo_required`,
    `appfile4`.`photoid_required`,
    `appfile4`.`training_required`,
    `appfile4`.`credential_required`,
    `appfile4`.`grantlist_required`,
    `appfile4`.`patentlist_required`,
    `appfile4`.`software_required`
FROM mywork.appfilecnt a
LEFT JOIN mywork.appfile4
ON a.campus_id =`appfile4`.`campus_id` AND a.id = `appfile4`.`id`;
