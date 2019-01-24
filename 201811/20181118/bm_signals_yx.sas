

/* -------------------  Multi Signals Sprd------------------------------------ */

%macro multisignals(input, n1, n2, ret, neutral, weighting, Ngrp, rhs1, rhs2, rhs3, rhs4, timevar);

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;
run;

/* rank by var1, var2, var3, var4 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=rank groups=&Ngrp;
var &rhs1 &rhs2 &rhs3 &rhs4;
by &neutral &timevar;
ranks rank_var1 rank_var2 rank_var3 rank_var4;
run;
data rank; set rank;
if rank_var1=. then delete;
if rank_var2=. then delete;
if rank_var3=. then delete;
if rank_var4=. then delete;
equal=1;
rank_var1 = rank_var1 + 1;
rank_var2 = rank_var2 + 1;
rank_var3 = rank_var3 + 1;
rank_var4 = rank_var4 + 1;
run;
proc sort data=rank; 
by &neutral &timevar rank_var1 rank_var2 rank_var3 rank_var4; 
run;

option nonotes;
proc means data=rank noprint;
var &ret;
by &neutral &timevar rank_var1 rank_var2 rank_var3 rank_var4;
weight &weighting;
output out=port mean=retbar n=num;
run;

option notes;
proc sort data=port out=port;
by rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar;
run;
proc transpose data=port out=port2;
by rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar; var retbar;
run;
proc sort data=port2;
by _name_ rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar;
run;


data bot; set port2;
if rank_var1=1 and rank_var2=1 and rank_var3=1 and rank_var4=1;
bot1=col1;
keep &neutral &timevar bot1;
run;
data top; set port2;
if rank_var1=&Ngrp and rank_var2=&Ngrp and rank_var3=&Ngrp and rank_var4=&Ngrp;
top1=col1;
keep &neutral &timevar top1;
run;


data sprd&Ngrp; merge bot top;
by &neutral &timevar;
col1 = top1 - bot1;
keep &neutral &timevar col1;
run;


%mend multisignals;



%macro bmeffect(input, ret, sort, weighting, output);

%multisignals(&input, 4, 50, &ret, &sort, &weighting, 3, bm, bm2, bm3, bm4, portyear);
%multisignals(&input, 51, 100000, &ret, &sort, &weighting, 5, bm, bm2, bm3, bm4, portyear);

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

%mend bmeffect;



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

data agret1; merge agret1(in=a) region(in=b);
by country;
world = 'world';
run;

/**********************************************************/

/* this is not necessary as we have new rhs 
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


/****************** this is new ************************/

data tem; set agret;
if n>&nobs;
bm2 = be2/mc;
bm3 = be3/mc;
bm4 = be4/mc;
run;


x md "C:\TEMP\displace\20181121";
x cd "C:\TEMP\displace\20181121";


%bmeffect(tem, ret_us, country, ew, country_ew);

%bmeffect(tem, ret_us, country, lagmv_us, country_vw);

%bmeffect(tem, ret_us, region, ew, region_ew);

%bmeffect(tem, ret_us, region, lagmv_us, region_vw);

%bmeffect(tem, ret_us, world, ew, world_ew);

%bmeffect(tem, ret_us, world, lagmv_us, world_vw);


/*=============================================*/
/* quick double check                          */
/*=============================================*/

%let rankvar1 = bm;
%let rankvar2 = bm2;
%let rankvar3 = bm3;
%let rankvar4 = bm4;
%let timevar = mthyr;
%let neutral = country;
%let Ngrp =5;

data agret0; set disp.agret0;
bm = be1/mc;
bm2 = be2/mc;
bm3 = be3/mc;
bm4 = be4/mc;
run;

data agret0; set agret0;
if country="US";
keep ret ret_us mthyr code country portyear bm:;
run;

/* rank by var1, var2, var3, var4 into tercile/quintile/decile */
proc sort data=agret0; by &neutral &timevar; run;
proc rank data=agret0 out=rank groups=&Ngrp;
var &rankvar1 &rankvar2 &rankvar3 &rankvar4;
by &neutral &timevar;
ranks rank_var1 rank_var2 rank_var3 rank_var4;
run;


data rank1; set rank;
if rank_var1=0 & rank_var2=0 & rank_var3=0 & rank_var4=0;
run;
proc means data=rank1 noprint;
var ret_us;
by &neutral &timevar;
output out=port1 mean=retbar1 n=num1;
run;

data rank2; set rank;
if rank_var1=4 & rank_var2=4 & rank_var3=4 & rank_var4=4;
run;
proc means data=rank2 noprint;
var ret_us;
by &neutral &timevar;
output out=port2 mean=retbar2 n=num2;
run;


data sprd; merge port1 port2;
by &neutral &timevar;
col1 = retbar2 - retbar1;
keep &neutral &timevar col1;
run;

data sprd; set sprd;
if col1~=.;
proc means data=sprd noprint;
var col1;
by country;
output out=myport mean=eff;
run;
