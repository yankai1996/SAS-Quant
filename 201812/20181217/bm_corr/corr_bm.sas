
/* -------------------  Z Score ------------------------------------ */

%macro zscore3(input, neutral, timevar, signal1, signal2, signal3, label);

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
options label;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z&label=mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
run;

%mend zscore;


%macro zcombine(input, neutral, timevar);

data &input; set &input;
z = mean(zRD, -zEMP);
run;

/*
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
*/
%mend;


%macro zscore4(input, neutral, timevar, signal1, signal2, signal3, signal4);

proc sort data=&input;
by &neutral &timevar;
run;

proc rank data=&input out=rank;
var &signal1 &signal2 &signal3 &signal4;
by &neutral &timevar;
ranks r1 r2 r3 r4;
run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r1 r2 r3 r4;
output out=rankmean mean=mu1 mu2 mu3 mu4 std=sigma1 sigma2 sigma3 sigma4;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;
options label;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z4=(r4-mu4)/sigma4;
zBM=mean(z1, z2, z3, z4);
drop r1 r2 r3 r4 mu1 mu2 mu3 mu4 sigma1 sigma2 sigma3 sigma4 z1 z2 z3 z4;
run;

%mend zscore;



%macro corrZ(input, neutral, z1, z2);

%let out=corr_&neutral;

proc corr data=&input out=&out;
var &z1;
with &z2;
by &neutral;
run;

data &out; set &out;
if _NAME_ ~= '';
corr = &z1;
keep &neutral corr;
run;

ods tagsets.tablesonlylatex file="&out..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&out; run; quit;
ods tagsets.tablesonlylatex close;

%mend corrZ;



/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1);

data agret1; set agret1;
bm = be1/mc;
bm2 = be2/mc;
bm3 = be3/mc;
bm4 = be4/mc;
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
drop n;
bm2 = be2/mc;
bm3 = be3/mc;
bm4 = be4/mc;
run;




%macro zscoretest(denominator);

dm 'log;clear;';
x md "C:\TEMP\displace\20181218\&denominator";
x cd "C:\TEMP\displace\20181218\&denominator";

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%zscore3(tem, country, portyear, EMP1, EMP2, EMP3, EMP);
%zscore3(zscore, country, portyear, signal1, signal2, signal3, RD);
%zcombine(zscore, country, portyear);
%zscore4(zscore, country, portyear, bm, bm2, bm3, bm4);
%corrZ(zscore, country, zBM, z);

%zscore3(tem, region, portyear, EMP1, EMP2, EMP3, EMP);
%zscore3(zscore, region, portyear, signal1, signal2, signal3, RD);
%zcombine(zscore, region, portyear);
%zscore4(zscore, region, portyear, bm, bm2, bm3, bm4);
%corrZ(zscore, region, zBM, z);

%zscore3(tem, world, portyear, EMP1, EMP2, EMP3, EMP);
%zscore3(zscore, world, portyear, signal1, signal2, signal3, RD);
%zcombine(zscore, world, portyear);
%zscore4(zscore, world, portyear, bm, bm2, bm3, bm4);
%corrZ(zscore, world, zBM, z);

%mend zscoretest;


%zscoretest(MC);
%zscoretest(TA);
%zscoretest(be4);
%zscoretest(SL);

