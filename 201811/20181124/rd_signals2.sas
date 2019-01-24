

/* -------------------  Three Signals Sprd------------------------------------ */

%macro threesignals(input, n1, n2, ret, neutral, weighting, Ngrp, rhs1, rhs2, rhs3, timevar);

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;
run;

/* rank by var1, var2, var3 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=rank groups=&Ngrp;
var &rhs1 &rhs2 &rhs3;
by &neutral &timevar;
ranks rank_var1 rank_var2 rank_var3;
run;
data rank; set rank;
if rank_var1=. then delete;
if rank_var2=. then delete;
if rank_var3=. then delete;
equal=1;
rank_var1 = rank_var1 + 1;
rank_var2 = rank_var2 + 1;
rank_var3 = rank_var3 + 1;
run;
proc sort data=rank; 
by &neutral &timevar rank_var1 rank_var2 rank_var3; 
run;

option nonotes;
proc means data=rank noprint;
var &ret;
by &neutral &timevar rank_var1 rank_var2 rank_var3;
weight &weighting;
output out=port mean=retbar n=num;
run;

option notes;
proc sort data=port out=port;
by rank_var1 rank_var2 rank_var3 &neutral &timevar;
run;
proc transpose data=port out=port2;
by rank_var1 rank_var2 rank_var3 &neutral &timevar; var retbar;
run;
proc sort data=port2;
by _name_ rank_var1 rank_var2 rank_var3 &neutral &timevar;
run;


data bot; set port2;
if rank_var1=1 and rank_var2=1 and rank_var3=1;
bot1=col1;
keep &neutral &timevar bot1;
run;
data top; set port2;
if rank_var1=&Ngrp and rank_var2=&Ngrp and rank_var3=&Ngrp;
top1=col1;
keep &neutral &timevar top1;
run;


data sprd&Ngrp; merge bot top;
by &neutral &timevar;
col1 = top1 - bot1;
keep &neutral &timevar col1;
run;


%mend threesignals;



%macro signaleffect(input, ret, sort, weighting, output);

%threesignals(&input, 4, 50, &ret, &sort, &weighting, 3, signal1, signal2, signal3, portyear);
%threesignals(&input, 51, 100000, &ret, &sort, &weighting, 5, signal1, signal2, signal3, portyear);

data sprd; set sprd3 sprd5;
proc sort; by &sort portyear;
run;

proc model data=sprd;
by &sort;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param;
quit;


data &output; set param;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.9);
param=est;
T = tvalue;
keep &sort param T p;
run;
data &output; retain &sort param T; set &output; run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

%mend signaleffect;



%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);


/***************** Merge Region ***************************/
proc sort data=agret1; by country; run;
data region; set region;
keep region country;
proc sort data=region; by country; 
run;

data agret1; merge agret1 region;
by country;
world = 'world';
run;


/***************** Make RD ******************************/
%makeRD();
proc sort data=agret1;
by code country portyear;
run;
data rd1; set rd;
keep code country portyear RD1 RD2 RD3;
data agret1; merge agret1 rd;
by code country portyear;
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


x md "C:\TEMP\displace\20181126";
x cd "C:\TEMP\displace\20181126";


%macro rdtest(denominator);

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%signaleffect(tem, ret_us, country, ew, &denominator._country_ew);
%signaleffect(tem, ret_us, country, lagmv_us, &denominator._country_vw);
%signaleffect(tem, ret_us, region, ew, &denominator._region_ew);
%signaleffect(tem, ret_us, region, lagmv_us, &denominator._region_vw);
%signaleffect(tem, ret_us, world, ew, &denominator._world_ew);
%signaleffect(tem, ret_us, world, lagmv_us, &denominator._world_vw);

%mend rdtest;

%rdtest(MC);
%rdtest(TA);
%rdtest(be4);
%rdtest(SL);
