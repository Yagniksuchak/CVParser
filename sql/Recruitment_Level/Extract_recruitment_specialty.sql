DROP TABLE IF EXISTS final.recruitment_specialty_type;

#combine all recruitment_title_name columns and recruitment_title_code into single column
CREATE TABLE final.recruitment_specialty_type
select campus, id, academic_year_id ,recruitment_specialties_code_1 as recruitment_specialties_code, recruitment_specialties_name_1 as recruitment_specialties_name from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_2, recruitment_specialties_name_2 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_3, recruitment_specialties_name_3 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_4, recruitment_specialties_name_4 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_5, recruitment_specialties_name_5 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_6, recruitment_specialties_name_6 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_7, recruitment_specialties_name_7 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_8, recruitment_specialties_name_8 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_9, recruitment_specialties_name_9 from final.job_all0
union all
select campus, id, academic_year_id ,recruitment_specialties_code_10, recruitment_specialties_name_10 from final.job_all0
;

SELECT DISTINCT recruitment_specialties_code, recruitment_specialties_name
FROM final.recruitment_specialty_type
WHERE recruitment_specialties_code IS NOT NULL 
ORDER BY recruitment_specialties_code;
