/****************************************************************************
| Project name : Thesis - BS and GLP1
| Date (update):
| Task Purpose : working with 100% of dataset - for my own thesis 
****************************************************************************/

*************************************************************************
*  Set up the environment  *
*************************************************************************

* 1. Access to JHPCE;

ssh -X mkim@jhpce01.jhsph.edu
               /* ssh -X mkim@jhpce03.jhsph.edu */
cd /dcs07/trinetx/data/
cd /users/mkim/

* 2. if I have X11 connection issue;
/* This can happen if you are running the chromium browser, and your session gets interrupted, so that chromium does not exit properly and clean up after itself.*/

rm ~/.config/chromium/Singleton*


srun --pty --x11 --partition sas bash
          /* srun --pty --x11 --partition=rocky94 bash */
module load sas
sas -helpbrowser SAS -xrm "SAS.webBrowser:'/usr/bin/chromium-browser'" -xrm "SAS.helpBrowser:'/usr/bin/chromium-browser'"


* 3. use SAS;

* My own directory for analysis in my own directory:     /users/mkim/trinetx/5p_test;
* My own directory for sharing in team folder:           /dcs07/trinetx/data/Users/MJ;

* to use original-data and 5p-data from the teamfolder;
libname tx "/dcs07/trinetx/data/SAS_datasets";

* to locate my own data analysis output in the original location in team folder;
libname analysis "/dcs07/trinetx/data/test_sas/5p";
libname test "/dcs07/trinetx/data";   

* to locate my own data analysis output under users in teamfolder;
libname min "/dcs07/trinetx/data/Users/MJ";
