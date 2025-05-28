/************************************************************************************
	STEP 1. merge BMI information with our study cohort
************************************************************************************/

* 1.0. patients - date of BMI measurement - BMI;

proc contents data=m.vitals_signs;
	title "m.vitals_signs";
run;

proc print data=m.vitals_signs (obs=30);
	title "m.vitals_signs";
run;

* 1.1. make a table with only BMI information sorted by patients.id;
/**************************************************
* new table: m.bmi
* original table: m.vitals_signs
* description: only bmi info sorted by patients.id
**************************************************/

proc sort data=m.vitals_signs
		out=m.bmi;
	where code="39156-5";
	by patient_id;
run;               /* 64,412,764 obs */

proc print data=m.bmi (obs=30) label;
	label date = "Date"
		num_value = "BMI";
	var patient_id date num_value;
	title "[m.bmi] BMI measurement date";
run;

* 1.2. add variable named 'startdate' to indicate 'minimum date of BMI measurement';
/**************************************************
* new table: m.bmi_startdate (deleted)
* original table: m.bmi
* description: indicate the min(date) as startdate
**************************************************/

proc sql;
	create table m.bmi_startdate as
	select patient_id, min(date) as startdate
	from m.bmi
	group by patient_id;
quit;
proc print data=m.bmi_startdate (obs=30);
	title "m.bmi_startdate";
run;


* 1.3. do mapping startdate with 'm.bmi' table by patient.id;
/**************************************************
* new table: m.bmi_date
* original table: m.bmi + m.bmi_startdate
* description: left join m.bmi & m.bmi_startdate
**************************************************/

proc sql;
  create table m.bmi_date as
  select distinct a.*, b.startdate
  from m.bmi a left join m.bmi_startdate b 
  on a.patient_id=b.patient_id;
quit;                  /* 60513355 obs */  

proc sort data=m.bmi_date;
	by patient_id date;
run;
proc print data=m.bmi_date (obs=30);
	title "m.bmi_date";
run;


data m.bmi_date;
    set m.bmi_date;
    date_num = input(date, yymmdd8.);
    format date_num yymmdd10.;
    drop date;
    rename date_num = date;
run;

proc means data=m.bmi_date n nmiss;
	var date;
 run;
proc contents data=m.bmi_date;
run;

/* delete */
proc datasets library=m nolist;
    delete bmi_startdate;
quit;

* 1.4. merge the BMI information with our study cohort;
/**************************************************
* new table: min.bs_glp1_bmi_v00   /* not distinct */
* original table: min.bs_glp1_user_v03 + m.bmi_date
* description: left join min.bs_glp1_user_v03 + m.bmi_date
**************************************************/

proc SQL;
	create table min.bs_preglp1_bmi_v00 as
 	select a.*, b.date, b.num_value
  	from min.bs_glp1_user_pre as a left join m.bmi_date as b
   	on a.patient_id = b.patient_id;
quit;                         /* 723676 duplicated */
    
data min.bs_preglp1_bmi_v00;
    set min.bs_preglp1_bmi_v00;
    rename date = bmi_date glp1_date = glp1_last_date num_value = bmi;
run;

proc sql;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_preglp1_bmi_v00;
quit;           /* it should be the same as "37056 - BS users" - yes, it is! */

* 1.5. remove missing BMI or BMI_date;
/* we don't exclude the extreme BMI value */

data min.bs_preglp1_bmi_v01;
	set min.bs_preglp1_bmi_v00;
 	if missing(bmi_date) then delete;
run;   /* 720228 obs */

data min.bs_preglp1_bmi_v01;
	set min.bs_preglp1_bmi_v01;
 	if missing(bmi) then delete;
run;    /* 622070 obs */

* 1.6. avg BMI if multiple BMI within a day;
Proc sql;
Create table min.bs_preglp1_bmi_v02 as
Select distinct patient_id, bs_date, temporality, bmi_date, avg(bmi) as bmi
From min.bs_preglp1_bmi_v01
Group by patient_id, bmi_date;
Quit;      /* 539141 obs */

/************************************************************************************
	STEP 2. BMI at baseline | bmi_index | the clostest value prior to the first bs_date
************************************************************************************/

/**************************************************
              Variable Definition
* table:
* 	min.bs_glp1_bmi_baseline
* 	
* variables
*  bmi_index : the clostest value prior to the first bs_date
*  bmi_bf_glp1 : the clostest value prior to the first glp1 prescription date
**************************************************/

* find pts with bmi 180 days prior first prescription;
Proc sql;
  create table min.bs_preglp1_bmi_6mprior as
  select distinct a.patient_id, a.temporality, a.bs_date, b.bmi_date, b.bmi
  from min.bs_glp1_user_pre a inner join min.bs_preglp1_bmi_v02 b 
  on (a.patient_id =b.patient_id and b.bmi_date < a.bs_date and b.bmi_date >= (a.bs_date-180));
Quit;

* latest bmi 6mon prior index, only have date in the output;
Proc sql;
  Create table bs_preglp1_bmi_latest as
  Select distinct patient_id, bs_date, max(bmi_date) as latest_bmi_date format=yymmdd10.
  From min.bs_preglp1_bmi_6mprior
  Group by patient_id, bs_date;
Quit;  

* left join latest BMI date with bmi value;
Proc sql;
Create table min.bs_preglp1_bmi_baseline as
Select distinct i.* , p.bmi,  p.temporality
From bs_preglp1_bmi_latest i left join min.bs_preglp1_bmi_6mprior p 
on (i.patient_id = p.patient_id and i.bs_date=p.bs_date and i.latest_bmi_date = p.bmi_date);
Quit;

* calculate median BMI value at baseline ; 
proc means data=min.bs_preglp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  title "bmi at baseline in total study population";
run;

proc means data=min.bs_preglp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  where temporality = 0;
  title "bmi at baseline in non-users";
run;

proc means data=min.bs_preglp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  where temporality = 1;
  title "bmi at baseline in users";
run;

/************************************************************************************
	STEP 3. BMI long dataset | min.bs_preglp1_bmi_v02
************************************************************************************/

proc print data=min.bs_preglp1_bmi_v02 (obs=20); run;







