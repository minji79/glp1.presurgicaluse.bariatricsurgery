
/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 04_Covariate_comorbidity
| Date (update): August 2024
| Task Purpose : 
|      1. Create Comorbidity lists using the ICD_10_CT and ICD_9_CT codes
|      2. Remain comorbidity diagnosed within 1 yr before the surgery
|      3. Calculate the distribution of each diseases comorbidities
|      4. 
|      5. CCI
| Main dataset : (1) min.bs_user_all_v07, (2) tx.diagnosis
| Final dataset: 
************************************************************************************/

* 1.1. stack diagnosis information for individuals in 'min.bs_user_all_v07';
/**************************************************
* new table: min.bs_preuser_comorbidity_v00
* original table: min.bs_user_all_v07 & tx.diagnosis
* description: stack diagnosis information for individuals in 'min.bs_user_all_v07'
**************************************************/

proc sql;
    create table min.bs_preuser_comorbidity_v00 as 
    select a.patient_id, 
           b.*  /* Select all columns from table b */
    from min.bs_glp1_user_pre as a 
    left join tx.diagnosis as b
    on a.patient_id = b.patient_id;
quit;


* 1.2. list up comorbidities;
/**************************************************
* new table: min.bs_preuser_comorbidity_v01
* original table: min.bs_preuser_comorbidity_v00
* description: list up comorbidities;
**************************************************/

%let cc_t2db=%str('E11%', '250.00', '250.02');  /* type 2 diabetes - I don;t use 'E08-E13' */
%let cc_obs=%str('E66%', '278.0%', "Z68.35", "Z68.36", "Z68.37", "Z68.38", "Z68.39", "Z68.41");  /* obesity + bmi >= 35 */
%let cc_htn=%str('I10%', '401.1', '401.9');  /* hypertentsion */
%let cc_dyslip=%str('E78%', '272%');  /* Dyslipidemia */
%let cc_osa=%str('G47.33', '327.23');  /* Obstructive sleep apnea */
%let cc_cad=%str('I25%', '414%');  /* Chronic coronary artery disease */
%let cc_hf=%str('I50%', '428%');  /* Heart failure */
%let cc_af=%str('I48%', '427.3');  /* Atrial fibrillation and flutter */
%let cc_asthma=%str('J45%', '493%');  /* Asthma */
%let cc_liver=%str('K76.0%', 'K75.81%', '571.8');  /* Fatty liver disease & nonalcoholic steatohepatitis */
%let cc_ckd=%str('N18%', '585%');  /* Chronic kidney disease */
%let cc_pos=%str('E28.2%', '256.4');  /* Polycystic ovarian syndrome */
%let cc_infertility=%str('N97%', 'N46%'. '628%', '606%');  /* Infertility */
%let cc_gerd=%str('K21%', '530.81%');  /* Gastroesophageal reflux disease */

/*
proc print data = min.bs_user_comorbidity_v00 (obs=40);
  where code like 'E11%' or code in ('250.00', '250.02');
run;
*/

data min.bs_preuser_comorbidity_v01;
    set min.bs_preuser_comorbidity_v00;
    format cc_t2db cc_obs cc_htn cc_dyslip cc_osa cc_cad cc_hf cc_af cc_asthma 
           cc_liver cc_ckd cc_pos cc_infertility cc_gerd comorbidity 8.;

    /* Initialize variables for each patient (first record) */
    by patient_id; 
    if first.patient_id then do;
        cc_t2db = 0;
        cc_obs = 0;
        cc_htn = 0;
        cc_dyslip = 0;
        cc_osa = 0;
        cc_cad = 0;
        cc_hf = 0;
        cc_af = 0;
        cc_asthma = 0;
        cc_liver = 0;
        cc_ckd = 0;
        cc_pos = 0;
        cc_infertility = 0;
        cc_gerd = 0;
    end;

    /* Set condition flags based on diagnosis codes */
    if code in: ('E11', '250.00', '250.02') then cc_t2db = 1;
    else if code in: ('E66', '278.0', 'Z68.35', 'Z68.36', 'Z68.37', 'Z68.38', 'Z68.39', 'Z68.41') then cc_obs = 1;
    else if code in: ('I10', '401.1', '401.9') then cc_htn = 1;
    else if code in: ('E78.4', 'E78.5', 'E78.81', 'E11.618', '272') then cc_dyslip = 1;
    else if code in: ('G47.33', '327.23') then cc_osa = 1;
    else if code in: ('I25', '414') then cc_cad = 1;
    else if code in: ('I50', 'I50.1', 'I50.9', '428') then cc_hf = 1;
    else if code in: ('I48', '427.3') then cc_af = 1;
    else if code in: ('J45', '493') then cc_asthma = 1;
    else if code in: ('K76.0', 'K75.81', '571.8') then cc_liver = 1;
    else if code in: ('N18', '585') then cc_ckd = 1;
    else if code in: ('E28.2', '256.4') then cc_pos = 1;
    else if code in: ('N97', 'N46.0', 'N46.1', 'N46.8', '628', '606') then cc_infertility = 1;
    else if code in: ('K21', '530.81') then cc_gerd = 1;
run;


* 1.3. add patient's bs_date and temporality;
/**************************************************
* new table: min.bs_preuser_comorbidity_v02
* original table: min.bs_user_comorbidity_v01 + min.bs_glp1_user_v03
* description: list up all comorbidities regardless types of the diseases
**************************************************/

proc sql;
    create table min.bs_preuser_comorbidity_v02 as 
    select a.*, 
           b.temporality, b.bs_date
    from min.bs_preuser_comorbidity_v01 as a 
    left join min.bs_glp1_user_pre as b
    on a.patient_id = b.patient_id;
quit;   /* 23417934 obs */

proc print data=min.bs_preuser_comorbidity_v02 (obs=30);
	where  cc_pos = 1;
  title "min.bs_user_comorbidity_v02";
run;


/************************************************************************************
	STEP 2. Remain comorbidity diagnosed within 1 yr before the surgery
************************************************************************************/

* 2.1. convert the format of the date;

data min.bs_preuser_comorbidity_v02;
	set min.bs_preuser_comorbidity_v02;
 	date_num = input(date, yymmdd8.);
  	format date_num yymmdd10.;
 	drop date comorbidity;
  	rename date_num = como_date;
run;

* 2.2. Remain comorbidity diagnosed within 1 yr before the surgery;
/**************************************************
* new table: min.bs_user_comorbidity_v03
* original table: min.bs_user_comorbidity_v02
* description: Remain comorbidity diagnosed within 1 yr before the surgery
**************************************************/

data min.bs_preuser_comorbidity_v03;
   set min.bs_preuser_comorbidity_v02;
   if bs_date - como_date ge 0 and bs_date - como_date le 365;
run;      /* 23551552 obs */

proc sql;
  create table distinct_patient_count as 
  select count(distinct patient_id) as num_patients
  from min.bs_preuser_comorbidity_v03;
quit;
proc print data=distinct_patient_count;
run;   /* 36277 distinct patients have comorbidities */

proc sort data=min.bs_preuser_comorbidity_v03;
	by patient_id;
run;


/************************************************************************************
	STEP 3. Calculate the distribution of each diseases comorbidities
************************************************************************************/

* 3.1. type 2 diabetes;
/**************************************************
* cc_t2db
* new table: min.bs_user_comorbidity_t2db
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_t2db;
	set min.bs_preuser_comorbidity_v03;
 	where cc_t2db =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 19003 obs */

proc freq data=min.bs_preuser_comorbidity_t2db;
	table temporality;
 	title "t2db among 36277";
run;

* 3.2. obesity;
/**************************************************
* cc_obs
* new table: min.bs_user_comorbidity_obs
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_obs;
	set min.bs_preuser_comorbidity_v03;
 	where cc_obs =1;
  	by patient_id;
  	if first.patient_id;
run;        

* 3.3. hypertentsion;
/**************************************************
* cc_htn
* new table: min.bs_user_comorbidity_htn
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_htn;
	set min.bs_preuser_comorbidity_v03;
 	where cc_htn =1;
  	by patient_id;
  	if first.patient_id;
run;        

* 3.4. Dyslipidemia;
/**************************************************
* cc_dyslip
* new table: min.bs_user_comorbidity_dyslip
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_dyslip;
	set min.bs_preuser_comorbidity_v03;
 	where cc_dyslip =1;
  	by patient_id;
  	if first.patient_id;
run;        

* 3.5. Obstructive sleep apnea;
/**************************************************
* cc_osa
* new table: min.bs_user_comorbidity_osa
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_osa;
	set min.bs_preuser_comorbidity_v03;
 	where cc_osa =1;
  	by patient_id;
  	if first.patient_id;
run;        

* 3.6. Chronic coronary artery disease;
/**************************************************
* cc_cad
* new table: min.bs_user_comorbidity_cad
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_cad;
	set min.bs_preuser_comorbidity_v03;
 	where cc_cad =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 0 obs */

* 3.7. Heart failure;
/**************************************************
* cc_hf
* new table: min.bs_user_comorbidity_hf
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_hf;
	set min.bs_preuser_comorbidity_v03;
 	where cc_hf =1;
  	by patient_id;
  	if first.patient_id;
run;   

* 3.8. Atrial fibrillation and flutter;
/**************************************************
* cc_af
* new table: min.bs_user_comorbidity_af
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_af;
	set min.bs_preuser_comorbidity_v03;
 	where cc_af =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 0 obs */

* 3.10. Asthma;
/**************************************************
* cc_asthma
* new table: min.bs_user_comorbidity_asthma
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_asthma;
	set min.bs_preuser_comorbidity_v03;
 	where cc_asthma =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 5 obs */

* 3.11. Fatty liver disease & nonalcoholic steatohepatitis;
/**************************************************
* cc_liver
* new table: min.bs_user_comorbidity_liver
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_liver;
	set min.bs_preuser_comorbidity_v03;
 	where cc_liver =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 5460 obs */

* 3.12. Chronic kidney disease;
/**************************************************
* cc_ckd
* new table: min.bs_user_comorbidity_ckd
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_ckd;
	set min.bs_preuser_comorbidity_v03;
 	where cc_ckd =1;
  	by patient_id;
  	if first.patient_id;
run;        /*  obs */

* 3.13. Chronic kidney disease;
/**************************************************
* cc_ckd
* new table: min.bs_user_comorbidity_ckd
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_ckd;
	set min.bs_preuser_comorbidity_v03;
 	where cc_ckd =1;
  	by patient_id;
  	if first.patient_id;
run;        /*  obs */

* 3.14. Polycystic ovarian syndrome;
/**************************************************
* cc_pos
* new table: min.bs_user_comorbidity_ckd
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_pos;
	set min.bs_preuser_comorbidity_v03;
 	where cc_pos =1;
  	by patient_id;
  	if first.patient_id;
run;        /* 2165 obs */

* 3.15. Infertility;
/**************************************************
* cc_infertility
* new table: min.bs_user_comorbidity_infertility
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_infer;
	set min.bs_preuser_comorbidity_v03;
 	where cc_infertility =1;
  	by patient_id;
  	if first.patient_id;
run;    

* 3.16. Gastroesophageal reflux disease;
/**************************************************
* cc_gerd
* new table: min.bs_user_comorbidity_infertility
* original table: min.bs_user_comorbidity_v03
**************************************************/

data min.bs_preuser_comorbidity_gerd;
	set min.bs_preuser_comorbidity_v03;
 	where cc_gerd =1;
  	by patient_id;
  	if first.patient_id;
run;    
