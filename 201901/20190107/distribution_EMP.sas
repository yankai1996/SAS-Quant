
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

data test; set tem;
EMP1 = abs(EMP1);
EMP2 = abs(EMP2);
EMP3 = abs(EMP3);
EMPmean = mean(EMP1, EMP2, EMP3);
run;

proc means data=test noprint;
var EMP1 EMP2 EMP3 EMPmean;
output out=mean;
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


%pctls(test, EMP1, 1);
%pctls(test, EMP2, 2);
%pctls(test, EMP3, 3);
%pctls(test, EMPmean, 4);

data pctls; merge pctls1 pctls2 pctls3 pctls4;
by _stat_;
run;

data mean; set mean;
drop _type_ _freq_;
data stat; set mean pctls;
run;

proc sql;
create table distribution as 
select
	_stat_, 
	put(EMP1, BEST12.) as lagEMP,
	put(EMP2, BEST12.) as COG,
	put(EMP3, BEST12.) as SGA,
	put(EMPmean, BEST12.) as mean
from stat;
quit;

x cd "C:\TEMP\displace\20190107";
%let output=distribution;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

