
libname db "V:\data_for_kai";
libname nnnDS 'V:\data_for_kai\WSDS20190215';

data mvdec; set nnnDS.mvdec; run;


data final; set nnnDS.agret0;
keep code country mthyr portyear ret ret_us RD MC p_us_updated;
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
if p_us_updated>=p_us_10;
run;


%macro onewaytest(wsby, wstype);

data agret1; set agret0;
if country='US' then ret_us=ret;
if RD>0 and MC>0;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10; 
if ret_us~=.;
rhs=RD/MC;
run;

proc sort data=agret1; by code mthyr;
data agret1; set agret1;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
proc sort; by code portyear;
run;


data mvdec1; set mvdec;
portyear = year+1;
lagmv_us = mv_us;
keep code portyear lagmv_us;
proc sort data=mvdec1;
by code portyear;
run;

data agret1; merge agret1(in=a) mvdec1(in=b);
by code portyear;
if a and b;
run;


%winsor(dsetin=agret1, dsetout=agret1, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);
%winsor(dsetin=agret1, dsetout=agret1, byvar=&wsby, vars=rhs, type=&wstype, pctl=1 99);


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
*if ret_us~=.;
if n>15;
drop _type_ _freq_;
run;


%rhseffect(agret, ret_us, country, ew, ew, sprdcoef, 5, outstat);
data pwd.country_ew_slope; set coef; run;
data pwd.country_ew_sprd; set sprd; run;
%rhseffect(agret, ret_us, country, lagmv_us, lagmv_us, sprdcoef, 5, outstat);
data pwd.country_vw_slope; set coef; run;
data pwd.country_vw_sprd; set sprd; run;

%mend onewaytest;
