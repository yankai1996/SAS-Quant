
options noxwait;

%include 'winsor.sas';



libname disp "C:\TEMP\displace";

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


data agret0; set disp.agret0;
drop lagret: pat: cite:;
run;

data mvmois; set disp.mvmois; run;

/*------------------------------------------------------------------------------- */
/* combine AG and ret; filters may be imposed
/* for example, throw out AG bigger than 10 or smaller than -10
/*------------------------------------------------------------------------------- */
%macro makerhs(rhs, lb, ub, nobs);
data agret00; set agret0;
/* data agret0; merge ipp.retmonthly2(in=a) ag(in=b) prmonthly ipp.juneret(in=d) ipp.momentum; 
by code portyear; */
rhs = rdc3;
/*if a and b;
*/

if country='US' then ret_us=ret;
/* if rhs ne .;
if ret_us ne .;

*/
if p_us_updated>=p_us_10;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10;

/* if rhs>=&lb and rhs=<&ub;  /* remove RHS > 10 and < -10; dont do this on SIZE and BM */
/* keep ret ret_us mthyr code country ctyid portyear ta rhs rdme rdme2 rdme3 rda rdbe cm mc sl ag rd rdc ia slaga ia2 roe roa dte maba tobinq capex lev cfa mpk pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 calret1y calret1y_us opm myroa myroe sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us momenret; */



keep ret ret_us mthyr code country portyear ta rhs cm mc sl rd rdc3 roe roa momenret_mth;
run;
proc sort; by code mthyr;
run;

/*
proc sort data=agret0; by mthyr;
proc univariate data=agret0 noprint;
by mthyr;
var ret ret_us rhs rdme rdme2 rdme3 rdbe rda;
output out=ext p1=p1 p1us p1rhs p1rdme p1rdme2 p1rdme3 p1rdbe p1rda p99=p99 p99us p99rhs p99rdme p99rdme2 p99rdme3 p99rdbe p99rda;
run;


data agret1; merge agret0 ext; by mthyr;
/*if country ~="US" then do;
	if ret1y<=p1 then ret1y=.;
	if ret1y>=p99 then ret1y=.;
	if ret1y_us<=p1us then ret1y_us=.;
	if ret1y_us>=p99us then ret1y_us=.;
end;

if ret<=p1 then ret=.;
if ret>=p99 then ret=.;
if ret_us<=p1us then ret_us=.;
if ret_us>=p99us then ret_us=.;
if rhs<=p1rhs then rhs=p1rhs;
if rhs>=p99rhs then rhs=p99rhs;
proc sort; by code portyear;
run;

proc sql;
 create table agret1 as
 select *
 from agret0
 where code in (select code from work.retannual) and portyear in (select portyear from work.retannual);
quit;
*/
data agret1; set agret00;
/* %winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=ret_us, type=winsor, pctl=1 99);  */
proc sort; by code mthyr;
run;

data agret1; merge agret1(in=a) mvmois(in=b);
by code mthyr;
if a and b;
/*if mv ne .;  */
run;


/*%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=lagmv_us, type=winsor, pctl=1 99);*/

%mend;




%macro mthtest(rhs, lb, ub, nobs, outp);

%makerhs(&rhs, &lb, &ub, &nobs);
/*
Omitted 
*/
%mend;


*%mthtest(rdc3,0,1000000,15);
%makerhs(rdc3, 0, 1000000, 15);

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
