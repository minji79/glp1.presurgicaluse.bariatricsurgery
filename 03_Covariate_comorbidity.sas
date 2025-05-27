
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

    /* Check for conditions and set flags */
    if code in ('E11', 'E11.0', 'E11.1', 'E11.2', 'E11.3', 'E11.4', 'E11.5', 'E11.6', 'E11.7', 'E11.8', 'E11.9', '250.00', '250.02') then do;
        cc_t2db = 1;
    end;
    else if code in ('E66', 'E66.0', 'E66.1', 'E66.2', 'E66.3', 'E66.8', 'E66.9', '278.0', "Z68.35", "Z68.36", "Z68.37", "Z68.38", "Z68.39", "Z68.41") then do;
        cc_obs = 1;
        
    end;
    else if code in ('I10', '401.1', '401.9') then do;
        cc_htn = 1;
        
    end;
    else if code in ('E78.4', 'E78.5', 'E78.81', 'E11.618', '272') then do;
        cc_dyslip = 1;
        
    end;
    else if code in ('G47.33', '327.23') then do;
        cc_osa = 1;
       
    end;
    else if code in ('I25', '414') then do;
        cc_cad = 1;
       
    end;
    else if code in ('I50', 'I50.1', 'I50.9', '428') then do;
        cc_hf = 1;
        
    end;
    else if code in ('I48', '427.3') then do;
        cc_af = 1;
       
    end;
    else if code in ('J45', '493') then do;
        cc_asthma = 1;
       
    end;
    else if code in ('K76.0', 'K75.81', '571.8') then do;
        cc_liver = 1;
        
    end;
    else if code in ('N18', '585') then do;
        cc_ckd = 1;
       
    end;
    else if code in ('E28.2', '256.4') then do;
        cc_pos = 1;
        
    end;
    else if code in ('N97', 'N46.0', 'N46.1', 'N46.8', '628', '606') then do;
        cc_infertility = 1;
        
    end;
    else if code in ('K21', '530.81') then do;
        cc_gerd = 1;
        
    end;
run;  /* 23417934 obs */


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

