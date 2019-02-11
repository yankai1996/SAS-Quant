
/* -------------------  Z Score ------------------------------------ */

%macro zscore(input, neutral, timevar, signal1, signal2, signal3, label, sign);

proc sort data=&input;
by &neutral &timevar;
run;

proc rank data=&input out=rank;
var &signal1 &signal2 &signal3;
by &neutral &timevar;
ranks r1 r2 r3;

run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r1 r2 r3;
output out=rankmean mean=mu1 mu2 mu3 std=sigma1 sigma2 sigma3;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z&label=&sign*mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
run;

%mend zscore;


%macro zdistribution(input, neutral, Ngrp, label1, label2);
/*
%let input = zscore;
%let neutral = country;
%let Ngrp = 5;
%let label1 = RD;
%let label2 = EMP;
*/
%let r1=r&label1;
%let r2=r&label2;

proc sort data=&input;
by &neutral portyear;
proc rank data=&input out=rank groups=&Ngrp;
var z&label1 z&label2;
by &neutral portyear;
ranks &r1 &r2;
run;

data rank; set rank;
keep code &neutral portyear &r1 &r2;
if &r1=0 or &r2=0;
run;

%let low1 = low&label1;
%let low2 = low&label2;
%let droplow1 = dropLow&label1;
%let droplow2 = dropLow&label2;

data rank; set rank;
if &r1=0 then do &low1 = 1; end;
if &r2=0 then do &low2 = 1; end;
if &r1=0 and &r2=. then do &droplow1 = 1; end;
if &r2=0 and &r1=. then do &droplow2 = 1; end;
if &r1=0 and &r2=0 then do bothLow = 1; end;
run;

%let output=&neutral._distribution;

proc means data=rank noprint;
by &neutral;
var &low1 &low2 &droplow1 &droplow2 bothLow;
output out=&output n=&low1 &low2 &droplow1 &droplow2 bothLow;
run;
data &output; set &output;
drop _type_ _freq_;
run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

%mend zdistribution;

/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1);

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


%macro ztest(denominator);

dm 'log;clear;';
x md "C:\TEMP\displace\20181219\&denominator";
x cd "C:\TEMP\displace\20181219\&denominator";

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%zscore(tem, country, portyear, EMP1, EMP2, EMP3, EMP, -1);
%zscore(zscore, country, portyear, signal1, signal2, signal3, RD, 1);
%zdistribution(zscore, country, 5, RD, EMP);

%zscore(tem, region, portyear, EMP1, EMP2, EMP3, EMP, -1);
%zscore(zscore, region, portyear, signal1, signal2, signal3, RD, 1);
%zdistribution(zscore, region, 5, RD, EMP);

%zscore(tem, world, portyear, EMP1, EMP2, EMP3, EMP, -1);
%zscore(zscore, world, portyear, signal1, signal2, signal3, RD, 1);
%zdistribution(zscore, world, 5, RD, EMP);

%mend twowaytest;


%ztest(MC);
%ztest(TA);
%ztest(be4);
%ztest(SL);
