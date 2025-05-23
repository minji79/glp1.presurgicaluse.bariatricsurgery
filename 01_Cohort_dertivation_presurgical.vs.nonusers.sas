
/************************************************************************************
	Started from min.bs_glp1_user_v01        
************************************************************************************/

data min.bs_glp1_user_v02;
    set min.bs_glp1_user_v01;
    by patient_id; 
    if first.patient_id; 
run;     /* 43443 obs */


/************************************************************************************
	STEP 5. Remove People with death_date < GLP1_initiation_date            (N = 52)
************************************************************************************/

data min.bs_glp1_user_pre;
    set min.bs_glp1_user_v02;
    if not missing(death_date) and death_date < glp1_initiation_date then delete;
run;   /* 43391 */


/************************************************************************************
	STEP 5. Remove the before use                (N = 5748)
************************************************************************************/

proc freq data=min.bs_glp1_user_pre;
	table temporality;
run;

/**************************************************
              Variable Definition
* table: min.bs_glp1_user_v02
* temporality
*       0  : no glp1_user   (n = 31308)
*       1  : take glp1 before BS   (n = 5748)
*       2  : take glp1 after BS    (n = 6335)
**************************************************/

data min.bs_glp1_user_pre;
    set min.bs_glp1_user_pre;
    if temporality = 2 then delete;
run;      /* 37056 obs */


/************************************************************************************
	min.bs_glp1_user_v03            (N = 37643)
 *       0  : no glp1_user   (n = 31308)
 *       1  : take glp1 before BS    (n = 5748)
************************************************************************************/
