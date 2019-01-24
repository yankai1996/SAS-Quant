/* -------------------  Three Signals ------------------------------------ */

%macro threesignals(input, n1, n2, Ngrp, rankvar1, rankvar2, rankvar3, ret, weighting, neutral, agg, timevar, output);

/*
%let input = agret;
%let n1 = 15;
%let n2 = 10000000;
%let Ngrp = 5;
%let rankvar1 = rhs;
%let rankvar2 = mv_us;
%let rankvar3 = ROE;
%let ret = ret_us;
%let weighting = equal;
%let neutral = world;
%let agg = world;
%let timevar = portyear;
%let output = summary_ew;
*/

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;
run;

/* rank by var1, var2, var3 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=rank groups=&Ngrp;
var &rankvar1 &rankvar2 &rankvar3;
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

/* average return --- aggregate by agg
can be different levels: country, region or global?
also do the NW adjustment for everything */

data sprd&Ngrp; set sprd&Ngrp;
world = 'world';
options notes;
proc sort data=sprd&Ngrp;
by &agg; 
run;

proc model data=sprd&Ngrp;
by &agg;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param;
quit;

data param0; set param; type='Average ret';run;
data param0; set param0;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.9);
param=est;
/* T=compress('('||tvalue||')'); */
T = tvalue;
keep &agg param T;
rename param=retbar;
run;


%mend threesignals;


******************* TEST ***********************;

libname disp "C:\TEMP\displace";
data agret0; set disp.agret0;
drop lagret: pat: cite:;
run;
data mvmois; set disp.mvmois;
run;

%makerhs(rdc3, 0, 10000000, 10000000);
/* scale within the globe */
proc sort data=agret1;
by mthyr;
run;
proc means data=agret1 noprint; by mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;
data agret; merge agret1(in=a) meanmv(in=b);
by mthyr;
if a and b;
world = 'world';
ew = 1;
/* mvport = lagmv_us/mvsum; */
mvport = mvsum/lagmv_us;
if rhs~=.;
if rhs>0;
portyear_old = portyear;
portyear = mthyr;
/* if portyear_old>1985; */
if ret_us~=.;
drop _type_ _freq_ ret;
run;

%threesignals(agret, 15, 10000000, 5, rhs, mv_us, ROE, ret_us, equal, world, world, portyear, summary_ew);
*%threesignals(agret, 15, 10000000, 5, rhs, mv_us, ROE, ret_us, lagmv_us, world, world, portyear, summary_vw);
