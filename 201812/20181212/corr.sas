
/* -------------------  Z Score ------------------------------------ */

%macro zscore(input, neutral, timevar, signal1, signal2, signal3, label);

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
z&label=mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
run;

%mend zscore;


%macro corrZ(input, neutral);

%let out=corr_&neutral;

data corr; set &input;
zEMP = -zEMP;
keep &neutral zRD zEMP;
run;

/*
proc corr data=corr;
ods output PearsonCorr=&out;
var zRD;
with zEMP;
by &neutral;
run;

data &out(rename=(zRD=corr PzRD=p)); set &out;
drop variable NzRD;
run;
*/

proc corr data=corr out=&out;
var zRD;
with zEMP;
by &neutral;
run;

data &out; set &out;
if _NAME_ ~= '';
corr = zRD;
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


%macro zcorrtest(denominator);

*x md "C:\TEMP\displace\20181212\&denominator";
x cd "C:\TEMP\displace\20181212\&denominator";

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%zscore(tem, country, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, country, portyear, signal1, signal2, signal3, RD);
%corrZ(zscore, country);


%zscore(tem, region, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, region, portyear, signal1, signal2, signal3, RD);
%corrZ(zscore, region);

%zscore(tem, world, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, world, portyear, signal1, signal2, signal3, RD);
%corrZ(zscore, world);

dm 'log;clear;';
%mend zcorrtest;


%zcorrtest(MC);
%zcorrtest(TA);
%zcorrtest(be4);
%zcorrtest(SL);
