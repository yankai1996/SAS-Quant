
options noxwait;

%include 'winsor.sas';



libname disp "C:\TEMP\displac";

option notes;

/* options nonotes nosource nosource2 errors=0;*/

%let temps=20141030;
%let rhs=rdc3;
%let nobs=50;
%let input=agret0;
%let n1=50;
%let n=1000;
%let n2=10000000;
%let Ngrp1=5;
%let Ngrp2=3;
%let rankvar1=rhs;
%let rankvar2=mv_us;
%let ret=ret_us;
%let weighting1=equal;
%let neutral=world;
%let agg=world;
%let timevar=portyear;
%let output=summary521;
%let sort=country;
%let ngroup=10;




%macro mthtest(rhs, lb, ub, nobs, outp);

*%makerhs(&rhs, &lb, &ub, &nobs);

/*********************************************************************/
/**************this is new  ******************************************/
data agret1; set agret1;
if rhs~=.;
if rhs>0;
run;
/*********************************************************************/
/* scale within a country */
proc sort data=agret1;
by country mthyr;
run;
proc means data=agret1 noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret1(in=a) meanmv(in=b);
by country mthyr;
if a and b;
ew = 1;
/* mvport = lagmv_us/mvsum;
if rhs~=.;
if rhs>0;
*/
mvport = mvsum/lagmv_us;
portyear_old = portyear;
portyear = mthyr;
/* if portyear_old>1985;  */
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>&nobs;
run;

/*
%rhseffect(tem, ret_us, country, ew, ew, outpew, 0, out_us_ew);
/* data outpew; set outpew;
ew&rhs = retsprd;
drop retsprd expostyear;
run;
*/
/*
%rhseffect(tem, ret_us, country, lagmv_us, mvport, outpvw, 0, out_us_vw);
/*data outpvw; set outpvw;
vw&rhs = retsprd;
drop retsprd expostyear;
run;
*/


%mend;



%mthtest(rdc3,0,1000000,15);
