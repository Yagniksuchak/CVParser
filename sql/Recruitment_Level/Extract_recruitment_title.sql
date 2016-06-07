DROP TABLE IF EXISTS final.recruitment_title_name;
/*
DROP TABLE IF EXISTS final.recruitment_title_name_uni;

#combine all recruitment_title_name columns and recruitment_title_code into single column
CREATE TABLE final.recruitment_title_name
select campus_id, id, recruitment_title_name_1 as recruitment_title_name, recruitment_title_code_1 as recruitment_title_code from final.job_all
union all
select campus_id, id, recruitment_title_name_2, recruitment_title_code_2 from final.job_all0
union all
select campus_id, id, recruitment_title_name_3, recruitment_title_code_3 from final.job_all0
union all
select campus_id, id, recruitment_title_name_4, recruitment_title_code_4 from final.job_all0
union all
select campus_id, id, recruitment_title_name_5, recruitment_title_code_5 from final.job_all0
union all
select campus_id, id, recruitment_title_name_6, recruitment_title_code_6 from final.job_all0
union all
select campus_id, id, recruitment_title_name_7, recruitment_title_code_7 from final.job_all0
union all
select campus_id, id, recruitment_title_name_8, recruitment_title_code_8 from final.job_all0
union all
select campus_id, id, recruitment_title_name_9, recruitment_title_code_9 from final.job_all0
union all
select campus_id, id, recruitment_title_name_10, recruitment_title_code_10 from final.job_all0
union all
select campus_id, id, recruitment_title_name_11, recruitment_title_code_11 from final.job_all0
union all
select campus_id, id, recruitment_title_name_12, recruitment_title_code_12 from final.job_all0
union all
select campus_id, id, recruitment_title_name_13, recruitment_title_code_13 from final.job_all0
union all
select campus_id, id, recruitment_title_name_14, recruitment_title_code_14 from final.job_all0
union all
select campus_id, id, recruitment_title_name_15, recruitment_title_code_15 from final.job_all0
union all
select campus_id, id, recruitment_title_name_16, recruitment_title_code_16 from final.job_all0
union all
select campus_id, id, recruitment_title_name_17, recruitment_title_code_17 from final.job_all0
union all
select campus_id, id, recruitment_title_name_18, recruitment_title_code_18 from final.job_all0
union all
select campus_id, id, recruitment_title_name_19, recruitment_title_code_19 from final.job_all0
union all
select campus_id, id, recruitment_title_name_20, recruitment_title_code_20 from final.job_all0
union all
select campus_id, id, recruitment_title_name_21, recruitment_title_code_21 from final.job_all0
union all
select campus_id, id, recruitment_title_name_22, recruitment_title_code_22 from final.job_all0
union all
select campus_id, id, recruitment_title_name_23, recruitment_title_code_23 from final.job_all0
union all
select campus_id, id, recruitment_title_name_24, recruitment_title_code_24 from final.job_all0
union all
select campus_id, id, recruitment_title_name_25, recruitment_title_code_25 from final.job_all0
union all
select campus_id, id, recruitment_title_name_26, recruitment_title_code_26 from final.job_all0
union all
select campus_id, id, recruitment_title_name_27, recruitment_title_code_27 from final.job_all0
union all
select campus_id, id, recruitment_title_name_28, recruitment_title_code_28 from final.job_all0
union all
select campus_id, id, recruitment_title_name_29, recruitment_title_code_29 from final.job_all0
union all
select campus_id, id, recruitment_title_name_30, recruitment_title_code_30 from final.job_all0
union all
select campus_id, id, recruitment_title_name_31, recruitment_title_code_31 from final.job_all0
union all
select campus_id, id, recruitment_title_name_32, recruitment_title_code_32 from final.job_all0
;

#Get unique recruitment_title_name across campus_id
SELECT DISTINCT recruitment_title_name, recruitment_title_code, campus_id 
FROM final.recruitment_title_name 
WHERE recruitment_title_name IS NOT NULL 
ORDER BY campus_id, recruitment_title_code;

#Get unique recruitment_title_name for all campus_id
CREATE TABLE final.recruitment_title_name_uni
SELECT DISTINCT recruitment_title_code, recruitment_title_name
FROM final.recruitment_title_name 
WHERE recruitment_title_name IS NOT NULL 
ORDER BY recruitment_title_code;
*/

CREATE TABLE final.recruitment_title_name
SELECT DISTINCT A.code AS  recruitment_title_code, A.name AS recruitment_title_name FROM
(
SELECT name, code FROM ucrecruit.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucb.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucd.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucla.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucm.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucr.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucsb.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucsc.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucsd.recruitment_titles
UNION ALL
SELECT name, code FROM ucrecruit_ucsf.recruitment_titles
) A
ORDER BY A.code
;

