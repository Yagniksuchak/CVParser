###################################
##Create seperate committee table##
###################################
# need to create code book use role and tool table
/*UCM has less departments in departments table than department in users table, external_code doesn't match department_code
  UCSC has no department information in users table
  UCSD has missing department_code in user table, doing exact department name macthing to add department_id
  
/*
DROP TABLE IF EXISTS final.committee1, final.committee2, final.committee3, final.committee4,  
final.committee5, final.committee6, final.committee7, final.committee8, final.committee9;    
*/
USE ucrecruit_ucsf;

DROP TABLE IF EXISTS mywork.committee1,  mywork.committee2,  mywork.committee;

##merge user_roles table through resouce_id
##merge department_roles table through resouce_id and inherited_from_department_role_id
CREATE TABLE mywork.committee1
SELECT c.*, d.department_id, d.role_id as department_role
FROM
(
SELECT a.id as recruitment_id, a.committee_id, b.user_id, b.role_id as user_role, b.inherited_from_department_role_id
FROM recruitments AS a
LEFT JOIN user_roles AS b on a.committee_id = b.resource_id WHERE a.academic_year_id in (14,15) and b.resource_type='Committee'
) c
LEFT JOIN department_roles AS d on c.committee_id = d.resource_id and c.inherited_from_department_role_id = d.id;


#merge users table to get user info
#merge department table to get school_id and department_id through department_code
CREATE TABLE mywork.committee2
SELECT a.*, b.department as user_department, b.department_code as user_department_code, b.faculty_level,
c.id as user_department_id, c.name as user_department_name, c.school_id as user_school_id, 
d.school_id as department_school_id, e.gender, e.ethnicity, e.member_type
FROM mywork.committee1 AS a
LEFT JOIN users AS b ON a.user_id = b.campus_id
LEFT JOIN departments AS c ON c.external_id = b.department_code
LEFT JOIN departments AS d ON d.id = a.department_id
LEFT JOIN user_demographic_data AS e ON a.user_id = e.user_id;

#get tool_id through roles table
CREATE TABLE mywork.committee
SELECT A.*, B.tool_id
FROM mywork.committee2 A
LEFT JOIN roles B ON A.user_role = B.id
ORDER BY recruitment_id, committee_id, user_id;
#LEFT JOIN tools C ON B.tool_id = C.id

#SELECT * FROM mywork.committee;

/*
SELECT a.*, b.gender, b.ethnicity FROM mywork.committee a 
LEFT JOIN user_demographic_data b ON a.user_id=b.user_id ;
*/
/*
UPDATE mywork.committee3
SET user_department = user_department_name
WHERE user_department_name IS NULL;
*/

ALTER TABLE mywork.committee
ADD campus_id INT FIRST,
MODIFY tool_id INT AFTER user_role,
MODIFY department_school_id INT AFTER department_id,
DROP inherited_from_department_role_id,
DROP user_department_name, 
DROP user_department_code;

#UCSD has missing department_code in user table, doing exact department name macthing to add department_id
/*
UPDATE mywork.committee a INNER JOIN departments b
ON LOWER(a.user_department) = LOWER(b.name)
SET a.user_department_id = b.id, a.user_school_id = b.school_id;
*/

UPDATE mywork.committee
SET campus_id = 10;

/*
CREATE TABLE final.committee1
SELECT * FROM mywork.committee;
*/

CREATE TABLE final.committee
SELECT * FROM final.committee9
UNION ALL SELECT * FROM mywork.committee;



UPDATE final.committee
SET gender=1 WHERE gender='male';
UPDATE final.committee
SET gender=2 WHERE gender='female';
UPDATE final.committee
SET gender=3 WHERE gender='gender_unknown';


SELECT DISTINCT ethnicity from final.committee;

# ethnicity
UPDATE final.committee
SET ethnicity = 1 WHERE ethnicity = 'african';
UPDATE final.committee
SET ethnicity = 2 WHERE ethnicity = 'asian';
UPDATE final.committee
SET ethnicity = 3 WHERE ethnicity = 'latino';
UPDATE final.committee
SET ethnicity = 4 WHERE ethnicity = 'native_american';
UPDATE final.committee
SET ethnicity = 5 WHERE ethnicity = 'white';
UPDATE final.committee
SET ethnicity = 6 WHERE ethnicity = 'ethnicity_unknown';

SELECT DISTINCT member_type FROM final.committee;
UPDATE final.committee
SET member_type = 1 WHERE member_type = 'faculty';
UPDATE final.committee
SET member_type = 2 WHERE member_type = 'graduate_student';
UPDATE final.committee
SET member_type = 3 WHERE member_type = 'other';
