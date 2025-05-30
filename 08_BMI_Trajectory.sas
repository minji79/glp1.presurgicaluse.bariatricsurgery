/* for study population with covariate */
* min.studypop_pre_v01;

/* bmi long data */
* BMI of total study population overall study period | min.bs_preglp1_bmi_v03 
* post-surgical BMI of total study population | min.postbmi_pre_studypop 
* post-surgical BMI of total study population + 1 year window for pre-use | min.postbmi_pre_studypop2 

proc contents data=min.studypop_pre_v01; run;

proc print data=min.bmi_monthly_long (obs=20); 
  where temporality =1;
run;

proc print data = min.postbmi_pre_studypop2 (obs = 30);
	where temporality = 1;
run;

* only remain post-surgical BMI;
data min.postbmi_pre_studypop;
  set min.bs_preglp1_bmi_v03;
  if bs_date <= bmi_date; 
run;   /* 294786 obs */

* forming post-surgical BMI of total study population + 1 year window for pre-use;
data preusers;
	set min.studypop_pre_v01;
 	if temporality = 1 and 0 <= (bs_date - glp1_initiation_date) <= 365;
run;
data nonusers;
	set min.studypop_pre_v01;
 	if temporality = 0;
run;

data studypop2; set preusers nonusers; run;  /* 31775 obs */

proc sql;
    create table min.postbmi_pre_studypop2 as
    select distinct a.*
    from min.postbmi_pre_studypop as a
    inner join studypop2 as b
    on a.patient_id = b.patient_id;
quit;


/************************************************************************************
	 STEP 1. using monthly BMI mean
************************************************************************************/

* with total study population, calculate monthly bmi mean;
* discrete time matrix = month;

/* 1.1. create table for monthly BMI seperately */
* month 1 needs to be done separately due to the equal sign;
Proc sql;
	Create table Bmi_after_m1 as
	Select b.*
	From min.postbmi_pre_studypop2 b
	Where bs_date <= bmi_date and bmi_date <= bs_date +30;
Quit;

* month 2 - 36 with macro ;
%macro monthly (data= , time=);

Proc sql;
	Create table &data as
	Select b.*
	From min.postbmi_pre_studypop2 b
	Where &time <= bmi_date and bmi_date <= &time +30;
Quit;

%mend monthly;

%monthly (data=Bmi_after_m2, time=bs_date+30);
%monthly (data=Bmi_after_m3, time=bs_date+60);
%monthly (data=Bmi_after_m4, time=bs_date+90);
%monthly (data=Bmi_after_m5, time=bs_date+120);
%monthly (data=Bmi_after_m6, time=bs_date+150);
%monthly (data=Bmi_after_m7, time=bs_date+180);
%monthly (data=Bmi_after_m8, time=bs_date+210);
%monthly (data=Bmi_after_m9, time=bs_date+240);
%monthly (data=Bmi_after_m10, time=bs_date+270);
%monthly (data=Bmi_after_m11, time=bs_date+300);
%monthly (data=Bmi_after_m12, time=bs_date+330);
%monthly (data=Bmi_after_m13, time=bs_date+360);
%monthly (data=Bmi_after_m14, time=bs_date+390);
%monthly (data=Bmi_after_m15, time=bs_date+420);
%monthly (data=Bmi_after_m16, time=bs_date+450);
%monthly (data=Bmi_after_m17, time=bs_date+480);
%monthly (data=Bmi_after_m18, time=bs_date+510);
%monthly (data=Bmi_after_m19, time=bs_date+540);
%monthly (data=Bmi_after_m20, time=bs_date+570);
%monthly (data=Bmi_after_m21, time=bs_date+600);
%monthly (data=Bmi_after_m22, time=bs_date+630);
%monthly (data=Bmi_after_m23, time=bs_date+660);
%monthly (data=Bmi_after_m24, time=bs_date+690);


/* 1.2. creat table for averaging monthly BMI */

%macro average (data1=, data2= );

Proc sql;
	Create table &data1 as
	Select b.patient_id, bs_date, avg (bmi) as bmi
	From &data2  b
	Group by b.patient_id, b.bs_date

%mend average;

%average (data1=Bmi_after_m1_avg, data2=Bmi_after_m1);
%average (data1=Bmi_after_m2_avg, data2=Bmi_after_m2);
%average (data1=Bmi_after_m3_avg, data2=Bmi_after_m3);
%average (data1=Bmi_after_m4_avg, data2=Bmi_after_m4);
%average (data1=Bmi_after_m5_avg, data2=Bmi_after_m5);
%average (data1=Bmi_after_m6_avg, data2=Bmi_after_m6);
%average (data1=Bmi_after_m7_avg, data2=Bmi_after_m7);
%average (data1=Bmi_after_m8_avg, data2=Bmi_after_m8);
%average (data1=Bmi_after_m9_avg, data2=Bmi_after_m9);
%average (data1=Bmi_after_m10_avg, data2=Bmi_after_m10);
%average (data1=Bmi_after_m11_avg, data2=Bmi_after_m11);
%average (data1=Bmi_after_m12_avg, data2=Bmi_after_m12);
%average (data1=Bmi_after_m13_avg, data2=Bmi_after_m13);
%average (data1=Bmi_after_m14_avg, data2=Bmi_after_m14);
%average (data1=Bmi_after_m15_avg, data2=Bmi_after_m15);
%average (data1=Bmi_after_m16_avg, data2=Bmi_after_m16);
%average (data1=Bmi_after_m17_avg, data2=Bmi_after_m17);
%average (data1=Bmi_after_m18_avg, data2=Bmi_after_m18);
%average (data1=Bmi_after_m19_avg, data2=Bmi_after_m19);
%average (data1=Bmi_after_m20_avg, data2=Bmi_after_m20);
%average (data1=Bmi_after_m21_avg, data2=Bmi_after_m21);
%average (data1=Bmi_after_m22_avg, data2=Bmi_after_m22);
%average (data1=Bmi_after_m23_avg, data2=Bmi_after_m23);
%average (data1=Bmi_after_m24_avg, data2=Bmi_after_m24);

/* 1.3. join monthly BMI together */
Proc sql;
	Create table min.bmi_monthly as
	Select distinct b.patient_id, b.bs_date, b.temporality,
 
(b0.BMI) as BMI_m0,
(b1.BMI) as BMI_m1,
(b2.BMI) as BMI_m2,
(b3.BMI) as BMI_m3,
(b4.BMI) as BMI_m4,
(b5.BMI) as BMI_m5, 
(b6.BMI) as BMI_m6,
(b7.BMI) as BMI_m7,
(b8.BMI) as BMI_m8,
(b9.BMI) as BMI_m9,
(b10.BMI) as BMI_m10,
(b11.BMI) as BMI_m11,
(b12.BMI) as BMI_m12,
(b13.BMI) as BMI_m13,
(b14.BMI) as BMI_m14,
(b15.BMI) as BMI_m15,
(b16.BMI) as BMI_m16,
(b17.BMI) as BMI_m17,
(b18.BMI) as BMI_m18,
(b19.BMI) as BMI_m19,
(b20.BMI) as BMI_m20,
(b21.BMI) as BMI_m21,
(b22.BMI) as BMI_m22,
(b23.BMI) as BMI_m23,
(b24.BMI) as BMI_m24

	from min.postbmi_pre_studypop2 b
 
Left join min.bs_preglp1_bmi_baseline b0 on b.patient_id = b0.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m1_avg b1 on b.patient_id =b1.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m2_avg b2 on b.patient_id =b2.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m3_avg b3 on b.patient_id =b3.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m4_avg b4 on b.patient_id =b4.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m5_avg b5 on b.patient_id =b5.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m6_avg b6 on b.patient_id =b6.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m7_avg b7 on b.patient_id =b7.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m8_avg b8 on b.patient_id =b8.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m9_avg b9 on b.patient_id =b9.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m10_avg b10 on b.patient_id =b10.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m11_avg b11 on b.patient_id =b11.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m12_avg b12 on b.patient_id =b12.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m13_avg b13 on b.patient_id =b13.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m14_avg b14 on b.patient_id =b14.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m15_avg b15 on b.patient_id =b15.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m16_avg b16 on b.patient_id =b16.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m17_avg b17 on b.patient_id =b17.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m18_avg b18 on b.patient_id =b18.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m19_avg b19 on b.patient_id =b19.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m20_avg b20 on b.patient_id =b20.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m21_avg b21 on b.patient_id =b21.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m22_avg b22 on b.patient_id =b22.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m23_avg b23 on b.patient_id =b23.patient_id and b.bs_date =b0.bs_date
Left join Bmi_after_m24_avg b24 on b.patient_id =b24.patient_id and b.bs_date =b0.bs_date ;

Quit;

proc print data = min.bmi_monthly(obs=10);
	 title "min.bmi_monthly";
run;

/* 1.4. transpose bmi wide to long */
* transpose;
Proc transpose data=min.bmi_monthly  Out =min.bmi_monthly_long;
	By patient_id;
	VAR BMI_m0 BMI_m1 BMI_m2 BMI_m3 BMI_m4 BMI_m5 BMI_m6 BMI_m7 BMI_m8 BMI_m9 
	BMI_m10 BMI_m11 BMI_m12 BMI_m13 BMI_m14 BMI_m15 BMI_m16 BMI_m17 BMI_m18 BMI_m19 
	BMI_m20 BMI_m21 BMI_m22 BMI_m23 BMI_m24 ;
RUN;

*format long dataset;
Data min.bmi_monthly_long;
	Set min.bmi_monthly_long (rename=(COL1 = bmi));
	Month=input(substr(_NAME_, 6) ,5.);
	Drop _NAME_ ;
Run;

proc print data = min.bmi_monthly_long (obs=10);
	 title "min.bmi_monthly_long";
run;

/* 1.5. add label "temporality" */
proc sql;
	create table min.bmi_monthly_long as 
 	select distinct a.*, b.temporality
  	from min.bmi_monthly_long a left join min.studypop_pre_v01 b 
   	on a.patient_id = b.patient_id;
quit;


/* 1.6. box plot real BMI */
* total study population;
ods graphics on / obsmax=100000000;       

Title 'Post-surgical BMI by Month among total study population ';
Proc sgplot data = min.bmi_monthly_long;
	Vbox bmi / category=Month connect=mean;
	xaxis display=(nolabel);
Run;
Ods graphics off;

proc means data=min.bmi_monthly_long noprint;
	class month;
	var bmi;
	output out=monthly_bmi_summary
		mean=Mean_BMI 
  		std=SD_BMI
		median=Median_BMI 
		p25=Q1_BMI 
		p75=Q3_BMI;
run;

proc print data=monthly_bmi_summary noobs;
	title "Monthly Summary of Post-surgical BMI by Month among total study population";
run;

* glp-1 users;
data bmi_monthly_long_preusers;
  set min.bmi_monthly_long;
  if temporality =1;
run;

ods graphics on / obsmax=100000000;       

Title ' Post-surgical BMI by Month among pre-surgical GLP-1 users';
Proc sgplot data = bmi_monthly_long_preusers;
	Vbox bmi / category=Month connect=mean;
	xaxis display=(nolabel);
Run;
Ods graphics off;

proc means data=bmi_monthly_long_preusers noprint;
	class month;
	var bmi;
	output out=monthly_bmi_summary
		mean=Mean_BMI 
  		std=SD_BMI
		median=Median_BMI 
		p25=Q1_BMI 
		p75=Q3_BMI;
run;

proc print data=monthly_bmi_summary noobs;
	title "Monthly Summary of Post-surgical BMI among Pre-surgical GLP-1 Users";
run;

* non-users;
data bmi_monthly_long_nousers;
  set min.bmi_monthly_long;
  if temporality =0;
run;
ods graphics on / obsmax=100000000;       

Title ' Post-surgical BMI by Month among non-users ';
Proc sgplot data = bmi_monthly_long_nousers;
	Vbox bmi / category=Month connect=mean;
	xaxis display=(nolabel);
 	where temporality = 0;
Run;
Ods graphics off;

proc means data=bmi_monthly_long_nousers noprint;
	class month;
	var bmi;
	output out=monthly_bmi_summary
		mean=Mean_BMI 
  		std=SD_BMI
		median=Median_BMI 
		p25=Q1_BMI 
		p75=Q3_BMI;
run;

proc print data=monthly_bmi_summary noobs;
	title "Monthly Summary of Post-surgical BMI by Month among non-users";
run;

/************************************************************************************
	STEP 2. linear mixed model with natural spline term
************************************************************************************/
* make dataset for further analysis in R;
