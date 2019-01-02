
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

data SGA; set tem;
if EMP3 ~= .;
keep EMP3;
data SGA; set SGA;
if EMP3 < 0 then neg = EMP3;
*else nonneg = EMP3;
if EMP3 > 0 then pos = EMP3;
*else nonpos = EMP3;
abs=abs(EMP3);
if abs then both=EMP3;
else abs=.;
run;

proc means data = SGA noprint;
*var EMP1 EMP3;
output out=meanSGA;
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


%pctls(SGA, EMP3, 0);
%pctls(SGA, pos, 1);
%pctls(SGA, neg, 2);
%pctls(SGA, both, 3);
%pctls(SGA, abs, 4);

data pctls; merge pctls0 pctls1 pctls2 pctls3 pctls4;
by _stat_;
run;

data meanSGA; set meanSGA;
drop _type_ _freq_;
data sgastat; set meanSGA pctls;
run;

proc sql;
create table want as 
select
	_stat_, 
	put(EMP3, BEST12.) as EMP3,
	put(pos, BEST12.) as pos,
	put(neg, BEST12.) as neg,
	put(both, BEST12.) as both,
	put(abs, BEST12.) as abs
from sgastat;
quit;

x cd "C:\TEMP\displace\20190102";
%let output=want;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

