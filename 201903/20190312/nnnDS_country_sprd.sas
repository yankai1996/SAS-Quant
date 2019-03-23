
libname db "V:\data_for_kai";
libname nnnDS 'V:\data_for_kai\WSDS20190215';

data mvdec; set nnnDS.mvdec; run;


data final; set nnnDS.agret0;
COG_US = COGS*NIUS/NI;
SGA_US = SGA*NIUS/NI;
eq=se;
pf=pref;
dit=tax;
cm=ce;
if dit=. then dit=0;
be = eq-pf+dit;
keep code country mthyr portyear ret ret_us RD EMP MC COG_US SGA_US be p_us_updated;
proc sort; by portyear;
run;

proc sql;
	create table agret0 as
	select b.country as country, a.*
	from final as a
	left join db.ctycode as b on a.country=b.cty;
quit;

data agret0; set agret0;
if country="" then delete;
proc sort; by country portyear;
run;

proc univariate data=agret0 noprint;
by country portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret0; merge agret0 price;
by country portyear;
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


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

*%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

* %makeEMP(agret1, agret1, cog_us, sga_us);

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
if RD>0;
if MC>0;
run;

%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);

%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190312\RD-MC";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
run;


%zRD(test, country, portyear, signal1, signal2, signal3, RD);
%onewayeffect(zscore, ret_us, country, ew, country_ew, zRD);
data pwd.country_ew_slope; set coef; run;
data pwd.country_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, zRD);
data pwd.country_vw_slope; set coef; run;
data pwd.country_vw_sprd; set sprd; run;


%mend onewaytest;

