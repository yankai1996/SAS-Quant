
/* -------------------  Three Way Sorting ------------------------------------ */

%macro threewaysprd(input, n1, n2, Ngrp1, Ngrp2, Ngrp3, rankvar1, rankvar2, rankvar3, ret, weighting, neutral, agg, timevar, output);

/*
%let input = agret;
%let n1 = 15;
%let n2 = 10000000;
%let Ngrp1 = 3;
%let Ngrp2 = 3;
%let Ngrp3 = 3;
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

/* sort by var1 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=var1 groups=&Ngrp1;
var &rankvar1;
by &neutral &timevar;
ranks rank_var1;
proc sort; by code &neutral &timevar;
run;
data var1; set var1;
if rank_var1=. then delete;
run;

/* sort by var2 into tercile/quintile/decile */
proc rank data=workable2 out=var2 groups=&Ngrp2;
var &rankvar2;
by &neutral &timevar;
ranks rank_var2;
proc sort; by code &neutral &timevar;
run;
data var2; set var2;
if rank_var2=. then delete;
run;

/* sort by var3 into tercile/quintile/decile */
proc rank data=workable2 out=var3 groups=&Ngrp3;
var &rankvar3;
by &neutral &timevar;
ranks rank_var3;
proc sort; by code &neutral &timevar;
run;
data var3; set var3;
if rank_var3=. then delete;
run;

/* combine three way sort  */
/* note this is the INTERSECTION not by a particular order */
data intx; merge var1(in=a) var2(in=b) var3(in=c);
by code &neutral &timevar;
if a and b and c;
proc sort;
by code &neutral &timevar rank_var1 rank_var2 rank_var3;
run;

data intx2; set intx;
equal = 1;
portnum2 = (rank_var1+1)*100 + (rank_var2+1)*10 + rank_var3;
proc sort; by &neutral &timevar portnum2;
run;


option nonotes;
proc means data=intx2 noprint;
var &ret;
by &neutral &timevar portnum2 rank_var1 rank_var2 rank_var3;
weight &weighting;
output out=port mean=retbar n=num;
run;

option notes;
data port2; set port;
/* if portnum2 ~=.; */
run;
proc sort data=port2;
by rank_var1 rank_var2 rank_var3 &neutral &timevar;
run;
proc transpose data=port2 out=port3;
by rank_var1 rank_var2 rank_var3 &neutral &timevar; var retbar;
run;
proc sort data=port3;
by _name_ rank_var1 rank_var2 rank_var3 &neutral &timevar;
run;



/*Find H-L difference for rank variable 3; */
proc sort data=port2 out=sum;
by rank_var1 rank_var2  &neutral &timevar rank_var3;
run;
data sum_diff; set sum(where=(rank_var3>-1));
by rank_var1 rank_var2  &neutral &timevar rank_var3;
if first.&timevar or last.&timevar; 
if first.&timevar then rank_var3=1;
if last.&timevar then rank_var3=2; 
run;
proc transpose data=sum_diff out=sum_diff2; 
by rank_var1 rank_var2 &neutral &timevar;
var retbar; id rank_var3;
run;
data sum_diff2; set sum_diff2; rank_var3=99; col1=_2-_1; drop _2 _1; run;
data sum_diff2; set port3 sum_diff2; run;


/*Find H-L difference for rank variable 2; */
proc sort data=sum_diff2;
by _name_ rank_var1 rank_var3 &neutral &timevar rank_var2;
run;
data sum_diff3; set sum_diff2(where=(rank_var2>-1));
by _name_ rank_var1 rank_var3 &neutral &timevar rank_var2;
if first.&timevar or last.&timevar; 
if first.&timevar then rank_var2=1;
if last.&timevar then rank_var2=2; 
run;
proc transpose data=sum_diff3 out=sum_diff3; 
by _name_ rank_var1 rank_var3 &neutral &timevar;
var col1; id rank_var2; 
run;
data sum_diff3; set sum_diff3; rank_var2=100; col1 = _2 - _1; drop _2 _1; run;
data sum_diff3; set sum_diff2 sum_diff3; run;


/*Find H-L difference for rank variable 1; */
proc sort data=sum_diff3;
by _name_ rank_var2 rank_var3 &neutral &timevar rank_var1;
run;
data sum_diff4; set sum_diff3(where=(rank_var1>-1));
by _name_ rank_var2 rank_var3 &neutral &timevar rank_var1;
if first.&timevar or last.&timevar;
if first.&timevar then rank_var1=1;
if last.&timevar then rank_var1=2; 
run;
proc transpose data=sum_diff4 out=sum_diff4;
by _name_ rank_var2 rank_var3 &neutral &timevar; 
var col1; id rank_var1; 
run;
data sum_diff4; set sum_diff4; rank_var1=101; col1 = _2 - _1; drop _2 _1; run;
data sum_diff4; set sum_diff4 sum_diff3;run;


proc sort data=sum_diff4;
by _name_ rank_var1 rank_var2 rank_var3 &neutral &timevar; run;
data sum_diff4; set sum_diff4;
if rank_var1=101 or rank_var2=100 or rank_var3=99 then exret=col1; run;

/* average return --- aggregate by agg
can be different levels: country, region or global?
also do the NW adjustment for everything */

data sum_diff4; set sum_diff4;
world = 'world';
options notes;
proc sort data=sum_diff4;
by _name_ &agg; 
run;

proc model data=sum_diff4;
by _name_ &agg rank_var1 rank_var2 rank_var3;
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
if rank_var1=101 or rank_var2=100 or rank_var3=99 then param=compress(est||p);
/* T=compress('('||tvalue||')'); */
T = tvalue;
keep &agg rank_var1 rank_var2 rank_var3 param T;
rename param=retbar;
run;

proc sort data=param0 out=&output;
by &agg rank_var1 rank_var2 rank_var3;
run;


%mend threewaysprd;


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

%threewaysprd(agret, 15, 10000000, 3, 3, 3, rhs, mv_us, ROE, ret_us, equal, world, world, portyear, summary_ew);
%threewaysprd(agret, 15, 10000000, 3, 3, 3, rhs, mv_us, ROE, ret_us, mv_us, world, world, portyear, summary_vw);

data disp.summary_ew; set summary_ew; run;
data disp.summary_vw; set summary_vw; run;

x md "C:\TEMP\displace\20181115";
x cd "C:\TEMP\displace\20181115";

ods tagsets.tablesonlylatex file="summary_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=summary_ew; run; quit;
ods tagsets.tablesonlylatex file="summary_vw.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=summary_vw; run; quit;


