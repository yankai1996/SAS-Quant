
libname db "V:\data_for_kai";
libname nnnDS 'V:\data_for_kai\WSDS20190215';
libname us 'V:\data_for_kai\Compustat&CRSP merged';


data agret0_xus; set db.a4;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK");
run;
proc sql;
	create table agret0_xus as
	select a.*, b.cogs as cog2, b.ni, b.nius, a.cog-b.cogs as diff, a.cog*b.nius/b.ni as cog_us, a.sga*b.nius/b.ni as sga_us, coalesce(b.cogs,a.cog) as cog, coalesce(b.emp,a.emp) as emp
	from agret0_xus as a
	left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;
data agret0_xus; set agret0_xus;
keep code country mthyr portyear ret ret_us MC RD EMP COG_US SGA_US p_us_updated ;
run;

proc sql;
create table agret0_us as
select put(code, 6.) as code, country, mthyr, fyear+1 as portyear,
	ret, ret as ret_us, MC, EMP, xrd as RD, cogs as cog_us, xsga as sga_us,
	p_us_updated
from us.agret0
;
quit;


data mvdec_us; set us.mvdec; run;

proc sql;
create table mvdec_xus as
select * from db.mvdec_all
where code not in (select distinct code from mvdec_us)
;
quit;

data mvdec; set mvdec_us mvdec_xus; run;


data final; set agret0; 
proc sort; by portyear;
run;



data agret0; set final;
*if country~="US";
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
keep code country  mthyr portyear year ret ret_us MC RD EMP COG_US SGA_US p_us_updated p_us_10;
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
*if country in ("BD", "CN", "FR", "IT", "JP", "UK", "US");
if lagcog_us>0;
if RD>0;
if MC>0;
run;

%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);


