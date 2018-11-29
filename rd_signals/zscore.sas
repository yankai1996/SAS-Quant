
/* -------------------  Z Score ------------------------------------ */

%macro zscore(input, neutral, timevar, signal1, signal2, signal3);

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
z=mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
run;

%mend zscore;

/* -------------------  One Way Sprd------------------------------------ */

%macro sprd(input, n1, n2, ret, neutral, timevar, weighting, Ngrp, rhs);
/*
%let input=zscore;
%let n1=4;
%let n2=50;
%let ret=ret_us;
%let neutral=country;
%let timevar=portyear;
%let weighting=ew;
%let Ngrp=3;
%let rhs=z;
*/
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

proc means data=rank noprint;
var &rhs &ret;
by &neutral &timevar r;
weight &weighting;
output out=port mean=&rhs.bar &ret.bar;
run;

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


%macro zeffect(input, ret, sort, weighting, output, outstat);
/*
%let input=zscore;
%let ret=ret_us;
%let sort=country;
%let weighting1=ew;
%let output=outp;
*/
%sprd(&input, 4, 50, &ret, &sort, portyear, &weighting, 3, z);
%sprd(&input, 51, 100000, &ret, &sort, portyear, &weighting, 5, z);

data sprd; set sprd3 sprd5;
proc sort; by &sort portyear;
run;

proc sort data=&input; by &sort portyear;
run;

option nonotes;
proc reg data=&input noprint outest=coef edf;
model &ret=z;
by &sort portyear;
weight &weighting;
run;
option notes;
data coef; set coef;
slope=z;
keep &sort portyear slope;
run;

data &output; merge sprd coef;
by &sort portyear;
proc sort; by &sort;
run;

%NWavg(&output, &sort, 0, &outstat);

data &outstat; set &outstat;
proc sort; by &sort parameter;
run;

ods tagsets.tablesonlylatex file="&outstat..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&outstat; run; quit;
ods tagsets.tablesonlylatex close;

%mend zeffect;



/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

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


x md "C:\TEMP\displace\20181129";
x cd "C:\TEMP\displace\20181129";


%macro zscoretest(denominator);

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%zscore(tem, country, portyear, signal1, signal2, signal3);

%zeffect(zscore, ret_us, country, ew, &denominator._country_ew_outp, &denominator._country_ew);
/*%zeffect(zscore, ret_us, country, lagmv_us, &denominator._country_ew_outp, &denominator._country_vw);
%zeffect(zscore, ret_us, region, ew, &denominator._region_ew_outp, &denominator._region_ew);
%zeffect(zscore, ret_us, region, lagmv_us, &denominator._region_vw_outp,  &denominator._region_vw);
%zeffect(zscore, ret_us, world, ew, &denominator._world_ew_outp, &denominator._world_ew);
%zeffect(zscore, ret_us, world, lagmv_us, &denominator._world_vw_outp, &denominator._world_vw);
*/
%mend zscoretest;

%zscoretest(MC);
%zscoretest(TA);
%zscoretest(be4);
%zscoretest(SL);
