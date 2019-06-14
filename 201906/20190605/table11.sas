
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";
libname bk "V:\data_for_kai\pvgo_pe_bk";


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
run;


data agret1; set agret0;
if country='US' then ret_us=ret;
if RD>0 and MC>0;
if ret>-1 and ret<5;
if ret_us>-1 and ret_us<5; 
if ret_us~=.;
*rhs=RD/MC;
run;

proc sort data=agret1; by code mthyr;
data agret1; set agret1;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
proc sort; by portyear;
run;


proc univariate data=agret1 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10 p99=p_us_99;
run;

data agret1; merge agret1 price;
by portyear;
if p_us_updated>=p_us_10;
*if p_us_updated<p_us_99;
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


%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=lagmv_us, type=winsor, pctl=1 99);

%winsor(dsetin=agret1, dsetout=agret, byvar=country portyear, vars=RD MC, type=winsor, pctl=2.5 97.5);


%macro onewaytest();

/* scale within a country */
proc sort data=agret;
by country mthyr;
run;
proc means data=agret noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret(in=a) meanmv(in=b);
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
rhs=RD/MC;
drop _type_ _freq_;
run;


%rhseffect(agret, ret_us, country, ew, ew, sprdcoef, 1, outstat);
data ew_slope; set coef; run;
data ew_sprd; set sprd; run;
%rhseffect(agret, ret_us, country, lagmv_us, lagmv_us, sprdcoef, 1, outstat);
data vw_slope; set coef; run;
data vw_sprd; set sprd; run;

%mend onewaytest;

%onewaytest();



/*********** PVGO & PE spread************/
%macro pvgo_pe(high, low);

data pvgo_old; set bk.old_pvgo_bk;
pvgo_old=dec&high-dec&low;
keep country portyear pvgo_old;
run;

data pvgo_new; set bk.new_pvgo_bk;
pvgo_new=dec&high-dec&low;
keep country portyear pvgo_new;
run;

data pe_old; set bk.old_pe_bk;
pe_old=dec&high-dec&low;
keep country portyear pe_old;
run;

data pe_new; set bk.new_pe_bk;
pe_new=dec&high-dec&low;
keep country portyear pe_new;
run;

data pvgo_pe; merge pvgo_old pvgo_new pe_old pe_new;
by country portyear;
*pvgo2=coalesce(pvgo_old, pvgo_new);
pvgo2=pvgo_new;
pe=coalesce(pe_old, pe_new);
*if pvgo2<&low3 or pvgo2>&high3 then pvgo2=.;
*if pe<&low4 or pe>&high4 then pe=.;
*if pe<&low2 or pe>&high2 then pe=.;
if pe<5 or pe>75 then pe=.;
keep country portyear pvgo2 pe;
run;

%mend pvgo_pe;



%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data testdata; set &lhsdata;
mthyr=portyear;
*if mthyr<201707;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgo_pe(in=b);
by country portyear;
if a and b;
globe=1;
*pe=pe/100;
*if -1<&lhs<1;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	pvgo2-avg(pvgo2) as pvgo2, pe-avg(pe) as pe 
from testdata2
group by mthyr
;
quit;


%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;



/*********** rhstest ew/vw_sprd/slope ************/
%macro rhstest(rhs, wstype, wsby, id);

%twoDtest(ew_sprd, retsprd, &rhs, &wstype, &wsby, tout1);
%twoDtest(vw_sprd, retsprd, &rhs, &wstype, &wsby, tout2);
%twoDtest(ew_slope, slope, &rhs, &wstype, &wsby, tout3);
%twoDtest(vw_slope, slope, &rhs, &wstype, &wsby, tout4);

data output&id; set tout:;
id=&id;
type="&wstype";
by="&wsby";
run;

%mend rhstest;


%pvgo_pe(75, 25);
%rhstest(pvgo2, delete, globe, 1);
%rhstest(pe, delete, globe, 2);
%rhstest(pvgo2 pe, delete, globe, 3);


data final;
retain id range type by lhs; set output:;
proc sort; by id lhs;
run;


proc means data=testdata3; run;
