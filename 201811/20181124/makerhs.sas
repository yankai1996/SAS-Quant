
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


if p_us_updated>=p_us_10;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10;

/* if rhs>=&lb and rhs=<&ub;  /* remove RHS > 10 and < -10; dont do this on SIZE and BM */
/* keep ret ret_us mthyr code country ctyid portyear ta rhs rdme rdme2 rdme3 rda rdbe cm mc sl ag rd rdc ia slaga ia2 roe roa dte maba tobinq capex lev cfa mpk pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 calret1y calret1y_us opm myroa myroe sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us momenret; */



/* keep ret ret_us mthyr code country portyear ta rhs cm mc sl rd rdc3 roe roa momenret_mth; */
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

/*******************************************/
/*     use monthly updated value weights    /
/*******************************************
proc sort; by code mthyr;
run;
data agret1; merge agret1(in=a) mvmois(in=b);
by code mthyr;
if a and b;
run;
*/
/*******************************************/
/* use June value weights /
/* make lagmv_us to be the same as mv_us for coding convenience
/*******************************************/
proc sort; by code portyear;
run;

proc sort data=mvjune;
by code portyear;
run;
data mvjune; set mvjune; by code;
lagmv_us = lag(mv_us);
if first.code then lagmv_us=.;
run;

data agret1; merge agret1(in=a) mvjune(in=b);
by code portyear;
if a and b;
run;

/*%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=lagmv_us, type=winsor, pctl=1 99);*/

%mend;
