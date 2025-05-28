/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 
| Date (update): June 2024
| Task Purpose : 
|    
| Main dataset : (1) min.bs_glp1_user_v03
************************************************************************************/


/************************************************************************************
	STEP 1. Analysis of glp1 initiation only for pre-surgical GLP-1 users (n=5748)
************************************************************************************/

/**************************************************
* new dataset: min.glp1_users_6335
* original dataset: min.bs_glp1_user_v03 (N = 37643)
* description: 
**************************************************/

data min.glp1_users_5748;
  set min.bs_glp1_user_pre;
  if temporality = 1;
run; /* 5748 */

proc means data=min.glp1_users_5748
  n nmiss mean std min max median p25 p75;
  var gap_glp1_bs;
  title "distribution of time to pre-surgical GLP-1 use";
run;

/* histogram */
proc sgplot data=min.glp1_users_5748;
  histogram gap_glp1_bs / binwidth=90;
  xaxis label="Days Before Surgery" values=(0 to -6000 by 365);
  yaxis label="Frequency";
  title "Histogram of Time to Pre-surgical GLP-1 Use";
run;

/************************************************************************************
	STEP 2. Analysis of glp1 initiation by glp1 types - calendar time
************************************************************************************/

/**************************
	figure 3
 
 * xaxis:'calender year' 
 * excl. exenatide, lixi, missing
 * added table with number under the graph
 
**************************/

/**************************************************
* new dataset: min.glp1_users_5748_v01
* original dataset: min.glp1_users_5748
* description: add 'total' colunm by time_to_ini_cat
**************************************************/

* add calender year;
data min.glp1_users_5748_v01;
	set min.glp1_users_5748;
 	format glp1_init_year 4.;
	glp1_init_year = year(glp1_initiation_date);
run;
proc print data=min.glp1_users_5748_v01 (obs=30);
	var patient_id glp1_initiation_date glp1_init_year ;
	where glp1_user =1;
run;

/* plotting purpose */
proc freq data=min.glp1_users_5748_v01 noprint;
    tables Molecule*glp1_init_year / out=min.glp1_users_5748_v01_pct;
run;

proc sql;
    create table min.glp1_user_linegraph as
    select Molecule,
           glp1_init_year,
           count, 
           percent, 
           100 * count / sum(count) as col_pct  /* Calculate column percentage within time_to_init_cat */
    from min.glp1_users_5748_v01_pct
    group by glp1_init_year;
quit;
proc print data=min.glp1_user_linegraph (obs=30);
	title "min.glp1_user_linegraph";
run;

/* add 'total' colunm by time_to_ini_cat */
/**************************************************
* new dataset: min.glp1_user_linegraph_v01
* original dataset: min.glp1_user_linegraph 
* description: add 'total' colunm by time_to_ini_cat
**************************************************/

data min.glp1_user_linegraph_v01;
    set min.glp1_user_linegraph;
    format total 8.;

    /* Calculate total count for each time_to_init_cat */
    by glp1_init_year;
    if first.glp1_init_year then total = 0; 
    total + count; 

    /* Output only the last record for each time_to_init_cat */
    if last.glp1_init_year then output; 
run;

/* merge */
data min.glp1_user_linegraph_v02;
    merge min.glp1_user_linegraph (in=indata)
          min.glp1_user_linegraph_v01 (in=totaldata keep=glp1_init_year total);
    by glp1_init_year;
run;
proc print data=min.glp1_user_linegraph_v02 (obs=30);
run;

/* line graph */
proc sgplot data=min.glp1_user_linegraph_v02;
	where Molecule in ('Semaglutide', 'Dulaglutide', 'Liraglutide', 'Tirzepatide'); /* Filter for specific Molecule values */
    scatter x=glp1_init_year y=col_pct / group=Molecule
                                           markerattrs=(symbol=circlefilled size=7)  /* Customize marker appearance */
                                           datalabel=col_pct datalabelattrs=(size=8); /* Add data labels */
    series x=glp1_init_year y=col_pct / group=Molecule lineattrs=(thickness=2);

    xaxis label="Calender Year" 
           valueattrs=(weight=bold size=10) /* Adjust label style */
           ;

    yaxis label="Percentage of GLP-1 initiation (%)" values=(0 to 80 by 10);
    title "GLP-1 Initiation Year by GLP-1 Type";
    xaxistable count / class=Molecule title = "Number of initiators by GLP1 types";
run;

/* total number */
proc freq data=min.glp1_user_linegraph_v01;
	table total*glp1_init_year;
run;


/************************************************************************************
	STEP 3. Make time-to-initiation variable 
************************************************************************************/

data min.glp1_users_5748_v02;
    set min.glp1_users_5748_v01;
    format time_to_glp1_cat 8.;
    
    if -365*1 <= glp1_initiation_date - bs_date < 0 then time_to_glp1_cat = 1;        /* started within -1 year */
    else if -365*2 <= glp1_initiation_date - bs_date < -365*1 then time_to_glp1_cat = 2; /* started between - 1-2 years */
    else if -365*3 <= glp1_initiation_date - bs_date < -365*2 then time_to_glp1_cat = 3; /* started between - 2-3 years */
    else if -365*4 <= glp1_initiation_date - bs_date < -365*3 then time_to_glp1_cat = 4; /* started between - 3-4 years */
    else if -365*5 <= glp1_initiation_date - bs_date < -365*4 then time_to_glp1_cat = 5; /* started between - 4-5 years */
    else if -365*6 <= glp1_initiation_date - bs_date < -365*5 then time_to_glp1_cat = 6; /* started between - 5-6 years */
    else if -365*7 <= glp1_initiation_date - bs_date < -365*6 then time_to_glp1_cat = 7; /* started between - 6-7 years */
    else if glp1_initiation_date - bs_date < -365*7 then time_to_glp1_cat = 8;       /* started before - 7 years */
    
run;

proc freq data= min.glp1_users_5748_v02; table time_to_glp1_cat; run;







