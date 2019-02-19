
/* -------------------  Z Score ------------------------------------ */

%macro zscore(input, neutral, timevar, signal);

data zscore; set &input;
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
output out=rankmean mean=mu std=sigma n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
z&signal = (r-mu)/sigma;
drop r mu sigma;
run;

%mend zscore;

/* -------------------  One Way Sprd------------------------------------ */

%macro sprd(input, n1, n2, ret, neutral, timevar, weighting, Ngrp, rhs);

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;
proc sort; by &neutral &timevar;
run;

proc rank data=workable2 out=rank groups=&Ngrp;
var &rhs;
by &neutral &timevar;
ranks r;
run;

data rank; set rank;
if r=. then delete;
r = r + 1;
proc sort; by &neutral &timevar r;
run;

option nonotes;
proc means data=rank noprint;
var &rhs &ret;
by &neutral &timevar r;
weight &weighting;
output out=port mean=&rhs.bar &ret.bar;
run;
option notes;

data bot; set port; if r=1;
bot1=&rhs.bar;
bot2=&ret.bar;
keep &neutral &timevar bot1 bot2;
run;

data top; set port;if r=&Ngrp;
top1=&rhs.bar;
top2=&ret.bar;
keep &neutral &timevar top1 top2;
run;

data sprd&Ngrp; merge bot top;
by &neutral &timevar;
rhssprd = top1-bot1;
retsprd = top2-bot2;
stdsprd = retsprd/rhssprd;
keep &neutral &timevar rhssprd retsprd stdsprd;
run;

%mend sprd;


%macro NWavg(output, sort, lags, outstat);

option nonotes;
proc model data=&output;
by &sort;
parms rhssprdbar retsprdbar slopebar; exogenous rhssprd retsprd slope;
instruments / intonly;
rhssprd = rhssprdbar;
retsprd = retsprdbar;
stdsprd = stdsprdbar;
slope = slopebar;
/* fit rhssprd retsprd stdsprd slope / gmm kernel=(bart, %eval(2), 0); */
fit retsprd slope / gmm kernel=(bart, %eval(1+&lags), 0);
ods output parameterestimates=param0;
quit;
option notes;

data &outstat; set param0;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.3);
prob=put(probt,7.3);
stder=put(stderr, 7.3);
T=compress('('||tvalue||')');
drop EstType est StdErr probt DF T _type_;  /*may keep these information */
run;

proc sort data=&outstat;
by parameter;
run;
%mend NWavg;


%macro zeffect(input, ret, sort, weighting, output, z);

%sprd(&input, 11, 30, &ret, &sort, portyear, &weighting, 3, &z);
*%sprd(&input, 31, 50, &ret, &sort, portyear, &weighting, 5, &z);
*%sprd(&input, 51, 100000, &ret, &sort, portyear, &weighting, 10, &z);
%sprd(&input, 51, 100000, &ret, &sort, portyear, &weighting, 5, &z);

data sprd; set sprd3 sprd5 sprd10;
proc sort; by &sort portyear;
run;

proc sort data=&input; by &sort portyear;
run;

option nonotes;
proc reg data=&input noprint outest=coef edf;
model &ret=&z;
by &sort portyear;
weight &weighting;
run;
option notes;
data coef; set coef;
slope=&z;
keep &sort portyear slope;
run;

data &output._outp; merge sprd coef;
by &sort portyear;
proc sort; by &sort;
run;

%NWavg(&output._outp, &sort, 0, &output);

data &output; set &output;
proc sort; by &sort parameter;
run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

%mend zeffect;



/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);
/*
%makeRD(agret1, agret1);

%makeEMP(agret1, agret1);
*/
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
bm1 = bm;
bm2 = be2/mc;
bm3 = be3/mc;
bm4 = be4/mc;
if n>&nobs;
drop n;
run;


%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=bm1 bm2 bm3 bm4, type=winsor, pctl=1 99);




data test; set tem;
if portyear=199505 and ret_us > 5 then delete;
if country='RH' then delete;
run;



%macro bm4test();

%let pwd = "C:\TEMP\displace\20190109\bm4-quintile";
x md &pwd;
x cd &pwd;
libname bm4 &pwd;

%zscore(test, country, portyear, bm4);
%zeffect(zscore, ret_us, country, ew, country_ew, zbm4);
%zeffect(zscore, ret_us, country, lagmv_us, country_vw, zbm4);

%zscore(test, region, portyear, bm4);
%zeffect(zscore, ret_us, region, ew, region_ew, zbm4);
%zeffect(zscore, ret_us, region, lagmv_us, region_vw, zbm4);

%zscore(test, world, portyear, bm4);
%zeffect(zscore, ret_us, world, ew, world_ew, zbm4);
data bm4.world_ew_sprd; set sprd; run;
%zeffect(zscore, ret_us, world, lagmv_us, world_vw, zbm4);
data bm4.world_vw_sprd; set sprd; run;

%mend bm4test;

%bm4test();


%zscore(zscore, world, portyear, ret_us);

data outliers; set tem;
if portyear=199505 and ret_us > 5;
*if ret_us > 5;
*keep code country region world portyear ret_us lagmv_us bm4 be4 MC zBM;
run;

data test; set tem;
if portyear=199505 and ret_us > 5 then delete;
if country='US' then delete;
run;
%zeffect(test, ret_us, world, lagmv_us, world_vw, zbm4);

data outliers2; set zscore;
if lagmv_us > 900161;
run;

data lagmv; set zscore;
if lagmv_us <= 900161;
keep code country region world portyear ret_us lagmv_us bm4 be4 MC zBM;
proc sort data=lagmv;
by descending lagmv_us;
run;

data lagmv2; set tem;
if lagmv_us > 900000;
run;

proc means data=sprd10;
run;


proc sql;
create table cty as
select distinct country, region from tem;
quit;


data sprdex; set sprd;
if abs(retsprd) > 0.1;
run;



data return; set zscore;
if 200607 <= portyear <= 200906;
if 200607 <= portyear <= 200706 then portyear=2006;
if 200707 <= portyear <= 200806 then portyear=2007;
if 200807 <= portyear <= 200906 then portyear=2008;
keep code country portyear region ret_us lagmv_us bm4 zbm4;
run;

proc means data=return;
var ret_us lagmv_us;
by portyear;
run;


data sprd_check; set sprd;
proc sort; by retsprd;
run;
