
%macro preprocess();

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1, 1);
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
drop n;
run;

%mend preprocess;


%macro makeRD(input, output);

data rd; set &input;
keep code portyear rd;
if RD=0 then RD=.;;
proc sort data=rd nodup; 
by code portyear;
run; 

%do i=0 %to 3;
%let j=%eval(&i+1);
data rd; set rd;
by code;
lag0_rd=rd;
lag&j._rd=lag(lag&i._rd);
if first.code then lag&j._rd=.;
run;
%end;

data rd; set rd;
RD1 = rd;
RD2 = rd;
RD3 = rd;
run;

%do i=1 %to 4;
data rd; set rd;
RD2 = RD2 + (1-&i*0.2)*lag&i._rd;
if &i<3 then RD3 = RD2;
if &i=4 then do
RD2 = RD2/3;
RD3 = RD3/2.4;
end;
run;
%end;

proc sort data=&input;
by code portyear;
run;
data rd1; set rd;
keep code portyear RD1 RD2 RD3;
data &output; merge &input rd1;
by code portyear;
run;

proc datasets library=work noprint;
delete rd rd1;
run;

%mend makeRD;


%macro makeEMP(input, output, absolute);

data emp; set &input;
keep code portyear emp;
if emp=0 then emp=.;
proc sort data=emp nodup;
by code portyear;
run;

%if &absolute %then %do;
data emp; set emp; 
by code;
lag_emp=lag(emp);
if first.code then lag_emp=.;
delta_emp=abs(emp-lag_emp);
%end;
%else %do;
data emp; set emp; 
by code;
lag_emp=lag(emp);
if first.code then lag_emp=.;
delta_emp=emp-lag_emp;
%end;
proc sort data=emp;
by code portyear;
run;

proc sort data=&input;
by code portyear;
run;

data &output; merge &input emp;
by code portyear;
EMP1=delta_emp/EMP;
EMP2=delta_emp/COG;
EMP3=delta_emp/SGA;
drop lag_emp delta_emp;
run;

%mend makeEMP;


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
/* get lagmv_us
/******************************************
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
*/

/*************** This is new ****************************/
/* use Dec value weights for month 7~18
/* get lagmv_us */
proc sort; by code portyear;
run;

data mvdec1; set mvdec;
portyear = year+1;
lagmv_us = mv_us;
keep code portyear lagmv_us;
proc sort data=mvdec1;
by code portyear;
run;

data agret1; merge agret1(in=a) mvdec1(in=b);
by code portyear;
if a and b;
run;

%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=lagmv_us, type=winsor, pctl=1 99);

%mend;



%macro mergeRegion(input, output);

data temp&input; set &input;
proc sort data=temp&input; by country; 
run;

proc sort data=region; by country; 
run;

data &output; merge temp&input region;
by country;
world = 'world';
run;

proc datasets library=work noprint;
delete temp&input;
run;

%mend mergeRegion;


