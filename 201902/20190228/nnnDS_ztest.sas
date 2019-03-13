
libname db "V:\data_for_kai";
libname nnnDS 'V:\data_for_kai\WSDS20190215';

data mvdec; set nnnDS.mvdec; run;


/* sprd country level */

data final; set nnnDS.agret0;
COG_US = COGS*NIUS/NI;
SGA_US = SGA*NIUS/NI;
keep code country mthyr portyear ret ret_us RD EMP MC COG_US SGA_US p_us_updated;
proc sort; by portyear;
run;
%abbr_country(final);

data agret0; set final;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("BD", "CN", "FR", "IT", "JP", "UK", "US");
*if country in ("BD", "BG", "CN", "FR", "IT", "JP", "NL", "SD", "SW","UK", "US");
*if country in ("AU", "BD", "CN", "FN", "FR", "HK", "IS", 
"IT", "JP", "KO", "SD", "SG", "SW", "TA", "UK", "US");
proc sort; by portyear country;
run;

proc univariate data=agret0 noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret0; merge agret0 price;
by portyear country;
proc sort; by code portyear;
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


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

*%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1, cog_us, sga_us);

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
if lagcog_us>0;
if RD>0;
if MC>0;
run;

%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);

%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190228\top33";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
world = "world";
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
*if signal1~=. and EMP2~=.;
*if signal1~=.;
*if EMP2~=.;
run;


%zEMP(test, country, portyear, EMP2, 1);

proc sort data=zscore; by country mthyr;
proc univariate data=zscore noprint;
by country mthyr;
var zEMP;
*output out=prt q1=q1 q3=q3;
output out=prt pctlpts=33 67 pctlpre=p;
run;
data agret3; merge zscore prt;
by country mthyr;
if zEMP>=p67;
run;

%zRD(agret3, country, portyear, signal1, signal2, signal3, RD);



%zRD(test, country, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, country, portyear, EMP2, 1);
%zn(zscore, country, portyear);
%onewayeffect(zscore, ret_us, country, ew, country_ew, z);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, z);
data pwd.country_vw_sprd; set sprd; run;

%mend onewaytest;


data zscore; set zscore;
z=zRD;
run;


%macro twowaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190225\replaceUS-twoway-developed";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
world = "world";
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
if signal1~=. and EMP2~=.;
run;

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, EMP2, 0);
%zn(zscore, world, portyear);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, equal, world, world, portyear, world_ew);
%saveTS(world_ew);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, lagmv_us, world, world, portyear, world_vw);
%saveTS(world_vw);
ods tagsets.tablesonlylatex file="world_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_ew; run; quit;
ods tagsets.tablesonlylatex file="world_vw.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_vw; run; quit;
ods tagsets.tablesonlylatex close;

%mend twowaytest;


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




%macro abbr_country(input);

data &input; set &input;
if country="AUSTRALIA" then country="AU";
else if country="GERMANY" then country="BD";
else if country="CHINA" then country="CH";
else if country="CANADA" then country="CN";
else if country="FINLAND" then country="FN";
else if country="FRANCE" then country="FR";
else if country="GREECE" then country="GR";
else if country="HONG KONG" then country="HK";
else if country="SOUTH KOREA" then country="KO";
else if country="ISRAEL" then country="IS";
else if country="INDIA" then country="IN";
else if country="ITALY" then country="IT";
else if country="JAPAN" then country="JP";
else if country="MALAYSIA" then country="MY";
else if country="SWEDEN" then country="SD";
else if country="SINGAPORE" then country="SG";
else if country="SWITZERLAND" then country="SW";
else if country="TAIWAN" then country="TA";
else if country="TURKEY" then country="TK";
else if country="UNITED KINGDOM" then country="UK";
else if country="UNITED STATES" then country="US";
run;

%mend abbr_country;


%macro saveTS(name);

data port2trans; set port2;
rank_var = portnum2 + 1;
drop portnum2 rank_var1 rank_var2 _type_ _freq_;
proc sort; by portyear;
run;

proc transpose data=port2trans out=port2trans;
by world portyear; var rank_var retbar num;
run;

data pwd.&name._ts; set port2trans;
%do i=1 %to 5;
	%do j=1 %to 5;
		rank&i&j = col%eval((&i-1)*5 + &j);
	%end;
%end;
drop col:;
if _name_ = "rank_var" then delete;
run;

%mend;

