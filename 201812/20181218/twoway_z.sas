
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


%macro zadjust(input, neutral, timevar);

data &input; set &input;
z = mean(zRD, -zEMP);
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
zEMP = -zEMP;
run;

%mend;


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1, 1);

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


%macro twowaytest(denominator);

dm 'log;clear;'
x md "C:\TEMP\displace\20181218\&denominator";
x cd "C:\TEMP\displace\20181218\&denominator";

data tem; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%zscore(tem, world, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, world, portyear, signal1, signal2, signal3, RD);
%zadjust(zscore, world, portyear);

%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, equal, world, world, portyear, world_ew);
data sum_diff3_ew; set sum_diff3;
if rank_var1=100 & rank_var2~=99;
proc means; var col1;
output out=avg100_ew mean=ew_bar std=ew_sigma;
run;
data avg100_ew; set avg100_ew;
tvalue = ew_bar/ew_sigma*sqrt(_freq_/5);
run;
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, lagmv_us, world, world, portyear, world_vw);
data sum_diff3_vw; set sum_diff3;
if rank_var1=100 & rank_var2~=99;
proc means; var col1;
output out=avg100_vw mean=vw_bar std=vw_sigma;
run;
data avg100_vw; set avg100_vw;
tvalue = vw_bar/vw_sigma*sqrt(_freq_/5);
run;
ods tagsets.tablesonlylatex file="world_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_ew; run; quit;
ods tagsets.tablesonlylatex file="avg100_ew.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=avg100_ew; run; quit;
ods tagsets.tablesonlylatex file="world_vw.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_vw; run; quit;
ods tagsets.tablesonlylatex file="avg100_vw.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=avg100_vw; run; quit;
ods tagsets.tablesonlylatex close;

%mend twowaytest;


%twowaytest(MC);
%twowaytest(TA);
%twowaytest(be4);
%twowaytest(SL);
