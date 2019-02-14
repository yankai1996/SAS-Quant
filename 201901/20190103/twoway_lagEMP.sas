
/* -------------------  Z Score ------------------------------------ */

%macro zRD(input, neutral, timevar, signal1, signal2, signal3, label);

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
output out=rankmean mean=mu1 mu2 mu3 std=sigma1 sigma2 sigma3 n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z&label=mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
run;

%mend zRD;


%macro zEMP(input, neutral, timevar, flag);

%let EMPi = EMP1;

%if &flag=1 %then %do;
%let signal=posEMP;
data zscore; set &input;
if &EMPi>0 then &signal=&EMPi;
%end;
%else %if &flag=-1 %then %do;
%let signal=negEMP;
data zscore; set &input;
if &EMPi<0 then &signal=&EMPi;
%end;
%else %if &flag=2 %then %do;
%let signal=bothEMP;
data zscore; set &input;
&signal=&EMPi;
%end;
%else %do;
%let signal=absEMP;
data zscore; set &input;
&signal=abs(&EMPi);
%end;
if &signal~=. and &signal~=0;
drop EMP1 EMP2 EMP3;
run;

proc sort data=zscore;
by &neutral &timevar;
run;

proc rank data=zscore out=rank;
var &signal;
by &neutral &timevar;
ranks r;
run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r;
output out=rankmean mean=mu std=sigma;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
zEMP = -(r-mu)/sigma;
if zEMP~=.;
drop r mu sigma &signal;
run;

%mend zEMP;


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

/*************** test ******************/

data tem; set tem;
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
run;


%macro twowaytest(sign, flag, Ngrp1);

dm 'log;clear;';
x md "C:\TEMP\displace\20190103\two-way\&sign";
x cd "C:\TEMP\displace\20190103\two-way\&sign";

%zEMP(tem, world, portyear, &flag);
%zRD(zscore, world, portyear, signal1, signal2, signal3, RD);
%twowaysprd(zscore, 51, 10000000, &Ngrp1, 5, zEMP, zRD, ret_us, equal, world, world, portyear, world_ew);
%twowaysprd(zscore, 51, 10000000, &Ngrp1, 5, zEMP, zRD, ret_us, lagmv_us, world, world, portyear, world_vw);
ods tagsets.tablesonlylatex file="world_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_ew; run; quit;
ods tagsets.tablesonlylatex file="world_vw.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_vw; run; quit;
ods tagsets.tablesonlylatex close;

%mend twowaytest;

%twowaytest(pos, 1, 3);
%twowaytest(neg, -1, 2);
%twowaytest(both, 2, 5);
%twowaytest(abs, 0, 5);



