
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

data test; set agret;
if n>&nobs;
drop n;
if RD>0;
if MC>0;
rhs=RD1/MC;
run;

%winsor(dsetin=test, dsetout=test, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);


proc sort data=test; by country mthyr;
proc means data=test noprint;
var rhs;
by country mthyr;
output out=number n=n;
run;

data test; merge test number;
by country mthyr;
run;


%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190325\RD-MC";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%rhseffect(test, ret_us, country, ew, ew, sprdcoef, 5, outstat);
data pwd.country_ew_slope; set coef; run;
data pwd.country_ew_sprd; set sprd; run;
%rhseffect(test, ret_us, country, lagmv_us, lagmv_us, sprdcoef, 5, outstat);
data pwd.country_vw_slope; set coef; run;
data pwd.country_vw_sprd; set sprd; run;


%mend onewaytest;


data junk2; set pwd.country_ew_slope;
run;
