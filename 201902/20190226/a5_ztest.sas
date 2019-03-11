
libname db "V:\data_for_kai";

data mvdec; set db.mvdec_all; run;


data agret0; set db.A5;
keep code country mthyr portyear ret ret_us p_us_updated bm4;
*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("BD", "CN", "FR", "IT", "JP", "UK", "US");
*if country in ("BD", "BG", "CN", "FR", "IT", "JP", "NL", "SD", "SW","UK", "US");
if country in ("AU", "BD", "CN", "FN", "FR", "HK", "IS", 
"IT", "JP", "KO", "SD", "SG", "SW", "TA", "UK", "US");
proc sort; by portyear;
run;

proc univariate data=agret0 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret0; merge agret0 price;
by portyear;
proc sort; by code portyear;
run;



/* -------------------  Z Score ------------------------------------ */

%macro zBM(input, neutral, timevar, signal, abs);

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
z = (r-mu)/sigma;
drop r mu sigma;
run;

%mend zBM;


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

*%mergeRegion(agret1, agret1);

*%makeRD(agret1, agret1);

*%makeEMP(agret1, agret1, cog_us, sga_us);

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
if bm4~=.;
world="world";
run;

%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);

%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190226\bm-developed";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%zBM(tem, world, portyear, bm4, 0);
%onewayeffect(zscore, ret_us, world, ew, world_ew, z);
data pwd.world_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, z);
data pwd.world_vw_sprd; set sprd; run;
%firmcty(rank, long, 10);
%firmcty(rank, short, 1);

%mend onewaytest;


%macro firmcty(input, output, N);

data &output; set &input;
keep code country region world portyear r;
if r=&N;
proc sort; by portyear country;
run;

proc means data=&output noprint;
by portyear country;
var r;
output out=&output n=n;
run;

proc transpose data=&output out=&output;
by portyear;
var n;
id country;
run;

data &output; 
retain portyear _name_
AR AU
BD BG BN BR
CB CH CL CN CP CY CZ
DK
ES EY
FN FR
GR
HK HN
ID IN IR IS IT
JP
KN KO
LX
MO MX MY
NL NW NZ
OE 
PE PH PK PO PT
RH RS 
SA SD SG SW 
TA TH TK
UK US
VE
;
set &output;
run;

data pwd.&output; set &output; run;

%mend firmcty;

