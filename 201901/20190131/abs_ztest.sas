
libname new "C:\TEMP\names_after_2009";
libname disp "C:\TEMP\displace\";
libname dsws "C:\TEMP\new DSWS";

data agret0_dsws; set dsws.agret0; 
keep code country mthyr portyear ret ret_us year RD EMP MC TA SGA COG p_us_updated;
if portyear > 2009;
run;
%abbr_country(agret0_dsws);

data agret0_new; set new.agret0_in_old_dsws;
EMP = numemployee;
COG = COGS;
MC = TA/TAUS*MVUS;
SGA = .; 
keep code country mthyr portyear ret ret_us year RD EMP MC TA SGA COG p_us_updated;
run;

data agret0_old; set disp.agret0; 
keep code country mthyr portyear ret ret_us year RD EMP MC TA SGA COG p_us_updated;
if portyear=2009;
run;

data agret0; set agret0_dsws agret0_old agret0_new;
proc sort; by portyear country;
run;

proc univariate data=agret0 noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;
data agret0; merge agret0 price;
by portyear country;
proc sort; by code mthyr;
run;


data mvdec_dsws; set dsws.mvdec; run;
data mvdec_new; set new.mvdec_in_old_dsws; run;
data mvdec; set mvdec_dsws mvdec_new;
if portyear >= 2009;
proc sort; by code portyear;
run;

data junk; set mvdec_dsws;
by code portyear;
if not (first.portyear & last.portyear);
run;

data region; set disp.region;
run;


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
if portyear=199505 and ret_us > 5 then delete;
if country='RH' then delete;
*if mthyr<=201712;
run;

*%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=EMP1 EMP2 EMP3, type=winsor, pctl=1 99);

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


%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190131\one-way-decile-201007";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", 
"IS", "IT", "JP", "KO","SD", "SW", "TA", "UK", "US");
if country~="US";
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
if signal1~=. and EMP2~=.;
run;

%zRD(test, country, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, country, portyear, EMP2, 1);
%zn(zscore, country, portyear);
%onewayeffect(zscore, ret_us, country, ew, country_ew, z);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, z);

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


%macro saveTS(name);

data port2trans; set port2;
rank_var = portnum2 + 1;
drop portnum2 rank_var1 rank_var2 _type_ _freq_;
proc sort; by portyear;
run;

proc transpose data=port2trans out=port2trans;
by world portyear; var rank_var retbar num;
run;

data pwd.&name; set port2trans;
%do i=1 %to 5;
	%do j=1 %to 5;
		rank&i&j = col%eval((&i-1)*5 + &j);
	%end;
%end;
drop col:;
if _name_ = "rank_var" then delete;
run;

%mend;


%macro twowaytest(EMPi);

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190121\two-way";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
*if country~="US";
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
run;

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, &EMPi, 1);
%zn(zscore, world, portyear);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, equal, world, world, portyear, world_ew);
%saveTS(world_ew);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, lagmv_us, world, world, portyear, world_vw);
%saveTS(world_vw);
ods tagsets.tablesonlylatex file="world_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_ew; run; quit;
ods tagsets.tablesonlylatex file="world_vw.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_vw; run; quit;
ods tagsets.tablesonlylatex close;

%mend twowaytest;

%twowaytest(EMP2);
