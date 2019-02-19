
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

data BR; set tem;
if country='BR';
run;

data BR2; set BR;
lagmv_us = lagmv_us/1000;
run;

data noBR; set tem;
if country~='BR';
run;

data noBRnoUS; set tem;
if country~='BR';
if country~='US';
run;


%macro getMean(input, signal);

proc means data=&input noprint;
var &signal;
output out=&input.mean;
run;

data &input.mean; set &input.mean;
&input = &signal;
keep _stat_ &input;
run;

proc sort data =  &input.mean; by _stat_; 
run;

%mend getMean;

%getMean(BR, lagmv_us);
%getMean(noBR, lagmv_us);

data mean; merge BRmean noBRmean;
by _stat_;
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

data &output(rename=(col1=&input _name_=_stat_)); set &output;
drop _label_;
run;
%mend pctls;


%pctls(BR, lagmv_us, 1);
%pctls(noBR, lagmv_us, 2);
%pctls(noBRnoUS, lagmv_us, 3);


data pctls; merge pctls1 pctls2 pctls3;
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
	put(BR, BEST12.) as BR,
	put(noBR, BEST12.) as noBR,
	put(noBRnoUS, BEST12.) as noBRnoUS
from stat;
quit;

x cd "C:\TEMP\displace\20190108";
%let output=distribution;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;


data agret1; set agret0;
bm4 = be4/mc;
proc sort data=agret1;
by country;
run;

proc means data=agret1;
var bm4;
by country;
run;

proc sort data=tem;
by country;
proc univariate data=tem;
var bm4;
by country;
run; 
