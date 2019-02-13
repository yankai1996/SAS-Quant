
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
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2;
run;
option label;

%mend zscore;


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

*%makeRD(agret1, agret1);

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


/************ test ********************/

dm 'log;clear;';
x md "C:\TEMP\displace\20181227\distribution";
x cd "C:\TEMP\displace\20181227\distribution";


%zscore(tem, world, portyear, EMP1, EMP2, EMP3, EMP);



%macro distribution(input, variable, title, bond=0);

%if %SYSFUNC(abs(&bond)) > 0 %then %do;
data distribution; set tem;
if &variable > -&bond and &variable <&bond;
run;
%let input = distribution;
%end;

title &title;
ods graphics on;
proc univariate data=&input noprint;
var &variable;
histogram &variable / odstitle = title;
inset n = 'Number of Obs' / position=ne;
*output out = distribution_&variable;
run;

%mend distribution;

%distribution(tem, EMP1, 'dEMP/EMP Distribution', bond=1);
%distribution(tem, EMP2, 'dEMP/EMP Distribution', bond=0.01);
%distribution(tem, EMP3, 'dEMP/SGA Distribution', bond=0.01);
%distribution(zscore, z1, 'z(dEMP/EMP) Distribution');
%distribution(zscore, z2, 'z(dEMP/COG) Distribution');
%distribution(zscore, z3, 'z(dEMP/SGA) Distribution');
%distribution(zscore, zEMP, 'zEMP Distribution');



proc means data = tem noprint;
var EMP1 EMP3;
output out=meanEMP;
run;


%macro pctls(input, x, i);

%let output = pctls&i;

proc univariate data=&input;
var &x;
output out=&output pctlpts  = 10 20 30 40 50 60 70 80 90
	pctlpre = pctl;
run; 
proc transpose data=&output out=&output;
run;

data &output(rename=(col1=&x _name_=_stat_)); set &output;
drop _label_;
run;
%mend pctls;


%pctls(tem, EMP1, 1);
%pctls(tem, EMP3, 3);

data pctls; merge pctls1 pctls3;
by _stat_;
run;

data meanemp; set meanemp;
drop _type_ _freq_;
data empstat; set meanemp pctls;
run;

x cd "C:\TEMP\displace\20181227";
%let output=empstat;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

