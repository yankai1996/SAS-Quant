
libname comp "C:\TEMP\Compustat&CRSP merged";
libname disp "C:\TEMP\displace";

data agret0; set comp.agret0; 
keep code country mthyr year portyear ret ret_us mc rd emp cog sga p_us_updated p_us_10 nyse;
ret_us = ret;
rd = xrd;
cog = cogs;
sga = xsga;
run;

data mvdec; set comp.mvdec; run;
data region; set disp.region; run;


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
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma2 sigma3;
run;
option label;

%mend zRD;


%macro zEMP(input, neutral, timevar, signal, abs);

data zscore; set &input;
%if &abs>0 %then %do;
&signal = abs(&signal);
%end;
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
zEMP = (r-mu)/sigma;
drop r mu sigma;
run;

%mend zEMP;


%macro zn(input, neutral, timevar);

data &input; set &input;
z = zRD+zEMP;
drop n;
run;

proc means data=&input noprint;
by &neutral &timevar;
var z;
output out=zn n=n;
run;
data &input; merge &input zn;
by &neutral &timevar;
drop _type_ _freq_;
if z~=.;
run;

%mend zn;

/*
data agret0; set agret0;
if mthyr<=201006;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
run;
*/

/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

*%mergeRegion(agret1, agret1);

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
if portyear=199505 and ret_us > 5 then delete;
if country='RH' then delete;
*if mthyr<=201712;
run;

*%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=EMP1 EMP2 EMP3, type=winsor, pctl=1 99);


*%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190219\US-one-way-decile-RDMC-198207";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
if mthyr>198206;
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
*if signal1~=. and EMP2~=.;
if signal1~=.;
run;

%zRD(test, country, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, country, portyear, EMP2, 1);
%zn(zscore, country, portyear);
%onewayeffect(zscore, ret_us, country, ew, country_ew, z);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, z);
data pwd.vw_sprd; set sprd; run;

/*
data zscore; set zscore;
z = zRD;
run;
*/

data znyse; set zscore;
if nyse=1;
run;

proc univariate data=znyse noprint;
var z;
by portyear;
output out=breakpts pctlpts  = 10 20 30 40 50 60 70 80 90
	pctlpre = pctl;
run;

proc sort data=zscore; by portyear; run;
data zbreak; merge zscore breakpts;
by portyear;
run;

data topbot; set zbreak;
if (z<pctl10 or z >= pctl90) and z~=.;
r = 1;
if z >= pctl90 then r=10;
keep code portyear country ew lagmv_us ret_us z r;
proc sort; by portyear r;
run;


proc means data=topbot noprint;
var z;
by portyear r;
output out=number n=n;
run;

proc transpose data=number out=number;
by portyear;
var n;
id r;
run;

data pwd.number; set number; run;
data pwd.breakpoints; set breakpts; run;



%macro breaktest(weighting, output);

proc means data=topbot noprint;
var z ret_us;
by portyear r;
weight &weighting;
output out=port mean=zbar retbar;
run;



data bot; set port; if r=1;
bot1=zbar;
bot2=retbar;
keep portyear bot1 bot2;
run;

data top; set port;if r=10;
top1=zbar;
top2=retbar;
keep portyear top1 top2;
run;

data sprd; retain country; merge bot top;
by portyear;
rhssprd = top1-bot1;
retsprd = top2-bot2;
stdsprd = retsprd/rhssprd;
country="US";
keep country portyear rhssprd retsprd stdsprd;
run;


proc sort data=zscore; by country portyear;
run;

option nonotes;
proc reg data=zscore noprint outest=coef edf;
model ret_us=z;
by country portyear;
weight &weighting;
run;
option notes;
data coef; set coef;
slope=z;
keep country portyear slope;
run;

data sprdcoef; merge sprd coef;
by country portyear;
proc sort; by country;
run;

%NWavg(sprdcoef, country, 0, &output);

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

data pwd.&output._sprd; set sprd; run;

%mend breaktest;

%breaktest(ew, US_ew);
%breaktest(lagmv_us, US_vw);




/*
%onewayeffect(zscore, ret_us, country, ew, country_ew, z);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, z);
data pwd.vw_sprd; set sprd; run;

%zRD(test, region, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, region, portyear, EMP2, 1);
%zn(zscore, region, portyear);
%onewayeffect(zscore, ret_us, region, ew, region_ew, z);
%onewayeffect(zscore, ret_us, region, lagmv_us, region_vw, z);

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, EMP2, 1);
%zn(zscore, world, portyear);
%onewayeffect(zscore, ret_us, world, ew, world_ew, z);
data pwd.world_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, z);
data pwd.world_vw_sprd; set sprd; run;
%firmcty(rank, long, 10);
%firmcty(rank, short, 1);


%mend onewaytest;
*/
