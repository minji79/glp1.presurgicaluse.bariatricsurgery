

/************************************************************************************
	STEP 1. Make total studypopulation (keep only RYGB and SG patients)
************************************************************************************/

data min.studypop_pre_v00; 
  set min.bs_glp1_user_pre; 
  if bs_type in ('rygb', 'sg');
run;  /* 34840 obs*/

proc freq data=min.studypop_pre_v00; table temporality; run;

/*
never users: 29231 (83.9%)
per-users: 5609 (16.1%)
*/

/************************************************************************************
	STEP 2. Make total studypopulation dataset incl. comorbidity & co-medication & bmi_at_baseline
************************************************************************************/

/**************************************************
* new dataset: min.studypop_pre_v00
* original dataset: min.bs_glp1_user_v03
* description: 
**************************************************/

* dataset for comorbidity at baseline;
proc sql;
    create table min.comorbidity_pre as
    select distinct a.patient_id, 
           b0.cc_t2db,
           b1.cc_obs,
           b2.cc_htn,
           b3.cc_dyslip,
           b4.cc_osa,
           b5.cc_cad,
           b6.cc_hf,
           b7.cc_af,
           b8.cc_asthma,
           b9.cc_liver,
           b10.cc_ckd,
           b11.cc_pos,
           b12.cc_infertility,
           b13.cc_gerd
    from min.studypop_pre_v00 a 
    left join min.bs_preuser_comorbidity_t2db b0 on a.patient_id = b0.patient_id
    left join min.bs_preuser_comorbidity_obs b1 on a.patient_id = b1.patient_id
    left join min.bs_preuser_comorbidity_htn b2 on a.patient_id = b2.patient_id
    left join min.bs_preuser_comorbidity_dyslip b3 on a.patient_id = b3.patient_id
    left join min.bs_preuser_comorbidity_osa b4 on a.patient_id = b4.patient_id
    left join min.bs_preuser_comorbidity_cad b5 on a.patient_id = b5.patient_id
    left join min.bs_preuser_comorbidity_hf b6 on a.patient_id = b6.patient_id
    left join min.bs_preuser_comorbidity_af b7 on a.patient_id = b7.patient_id
    left join min.bs_preuser_comorbidity_asthma b8 on a.patient_id = b8.patient_id
    left join min.bs_preuser_comorbidity_liver b9 on a.patient_id = b9.patient_id
    left join min.bs_preuser_comorbidity_ckd b10 on a.patient_id = b10.patient_id
    left join min.bs_preuser_comorbidity_pos b11 on a.patient_id = b11.patient_id
    left join min.bs_preuser_comorbidity_infer b12 on a.patient_id = b12.patient_id
    left join min.bs_preuser_comorbidity_gerd b13 on a.patient_id = b13.patient_id;
    
quit;

* dataset for co-medication at baseline;
proc sql;
    create table min.comedication_pre as
    select distinct a.patient_id, 
           b.cm_metformin,
           b.cm_dpp4,
           b.cm_sglt2,
           b.cm_su,
           b.cm_thiaz,
           b.cm_insul,
           b.cm_depres, 
           b.cm_psycho,
           b.cm_convul,
           b.cm_ob
    from min.studypop_pre_v00 a 
    left join min.bs_preuser_comedication_v09 b on a.patient_id = b.patient_id;
quit;

* dataset for bmi_index measured at baseline;
proc sql;
    create table min.studypop_pre_v01 as
    select distinct a.*,
            b.bmi as bmi_index
    from min.studypop_pre_v00 a 
    left join min.bs_preglp1_bmi_baseline b on a.patient_id = b.patient_id;
quit;

* add comorbidity and co-medication to the studypopulation;
proc sql;
    create table min.studypop_pre_v01 as
    select distinct a.*, 
           b1.cc_t2db,
           b1.cc_obs,
           b1.cc_htn,
           b1.cc_dyslip,
           b1.cc_osa,
           b1.cc_cad,
           b1.cc_hf,
           b1.cc_af,
           b1.cc_asthma,
           b1.cc_liver,
           b1.cc_ckd,
           b1.cc_pos,
           b1.cc_infertility,
           b1.cc_gerd,

           b2.cm_metformin,
           b2.cm_dpp4,
           b2.cm_sglt2,
           b2.cm_su,
           b2.cm_thiaz,
           b2.cm_insul,
           b2.cm_depres, 
           b2.cm_psycho,
           b2.cm_convul,
           b2.cm_ob
           
    from min.studypop_pre_v01 a 
    left join min.comorbidity_pre b1 on a.patient_id = b1.patient_id
    left join min.comedication_pre b2 on a.patient_id = b2.patient_id;
   
quit;

* fill null -> 0;
data min.studypop_pre_v01;
  set min.studypop_pre_v01;
  if missing(cc_t2db) then cc_t2db = 0;
  if missing(cc_obs) then cc_obs = 0;
  if missing(cc_htn) then cc_htn = 0;
  if missing(cc_dyslip) then cc_dyslip = 0;
  if missing(cc_osa) then cc_osa = 0;
  if missing(cc_cad) then cc_cad = 0;
  if missing(cc_hf) then cc_hf = 0;
  if missing(cc_af) then cc_af = 0;
  if missing(cc_asthma) then cc_asthma = 0;
  if missing(cc_liver) then cc_liver = 0;
  if missing(cc_ckd) then cc_ckd = 0;
  if missing(cc_pos) then cc_pos = 0;
  if missing(cc_infertility) then cc_infertility = 0;
  if missing(cc_gerd) then cc_gerd = 0;
  if missing(cm_metformin) then cm_metformin = 0;
  if missing(cm_dpp4) then cm_dpp4 = 0;
  if missing(cm_sglt2) then cm_sglt2 = 0;
  if missing(cm_su) then cm_su = 0;
  if missing(cm_thiaz) then cm_thiaz = 0;
  if missing(cm_insul) then cm_insul = 0;
  if missing(cm_depres) then cm_depres = 0;
  if missing(cm_psycho) then cm_psycho = 0;
  if missing(cm_convul) then cm_convul = 0;
  if missing(cm_ob) then cm_ob = 0;
  
run;


/************************************************************************************
	STEP 3. Form the logitudinal BMI dataset for the studypopulation
************************************************************************************/

* avg BMI if multiple BMI within a day;
Proc sql;
Create table min.bs_preglp1_bmi_v02 as
Select distinct patient_id, bs_date, temporality, bmi_date, avg(bmi) as bmi
From min.bs_preglp1_bmi_v01
Group by patient_id, bmi_date;
Quit;      /* 539141 obs */

* merge with the studypopulation;
proc SQL;
	create table min.bs_preglp1_bmi_v03 as
 	select a.patient_id, b.*
  	from min.studypop_pre_v01 as a left join min.bs_preglp1_bmi_v02 as b
   	on a.patient_id = b.patient_id;
quit;   /* 519059 obs */

proc print data= min.studypop_pre_v01 (obs = 20); run;
