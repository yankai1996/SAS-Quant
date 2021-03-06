proc delete data=work._all_; run;

/* if use newnewnew */
data final; set nnnds.agret0;
data mvdec_final; set nnnds.mvdec;


proc sql;
	create table final as
	select b.country as country, a.*, a.cogs as cog
	from final as a
	left join db.ctycode as b on a.country=b.cty;
quit;

/* now start */
data agret0; set final;
*rdme3 = rd/mc;
if country='US' then ret_us=ret;
*if ret>-1 and ret<10;
if ret_us>-1 and ret_us<100;
*if rd>0;
*if cog>0;
*if emp>0;
*if sga>0;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");
*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK");
*if country in ("BD");
if tax=. then tax=0;
be1 = se-pref+tax;
be2 = ce+tax;
be3 = ta-tl-pref+tax;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
bm = be4/mc;
rhs = bm;
if mc>0;
if be4>0;
keep ret ret_us mthyr code country portyear ta rhs ce mc sales salesus rd rdc roe roa emp cog sga p_us_updated be: bm;
run;

/*proc sort; by code portyear; run; */

/*
proc sql;
	create table agret0 as
	select a.*, b.cogs as cog2, b.ni, b.nius, a.cog-b.cogs as diff, b.nius/b.ni as fx, a.cog*b.nius/b.ni as cog_us, a.sga*b.nius/b.ni as sga_us, coalesce(b.cogs,a.cog) as cog, 
coalesce(b.emp,a.emp) as emp, b.ta as ta, b.ta*b.nius/b.ni as ta_us
	from agret0 as a
	left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;
*/

proc sort; by code portyear;
run;

data agret1; merge agret0(in=a) mvdec_final(in=b);
by code portyear;
if a and b;
lagmv_us = mv_us;
run;



/*
proc sql;
	create table agret2 as
	select a.*, a.cog as cog, b.cog_us as lagcog_us, b.emp as lagemp, b.sga_us as lagsga_us, b.cog as lagcog, b.sga as lagsga, b.rd as lagrd, c.rd as lag2rd, d.rd as lag3rd, e.rd as lag4rd,
	(a.rd + 0.8*lagrd + 0.6*lag2rd + 0.4*lag3rd + 0.2*lag4rd)/3/a.mc as rhs2, (a.rd + 0.8*lagrd + 0.6*lag2rd)/2.4/a.mc as rhs3, abs(a.emp-lagemp)/lagcog_us as rhsemp
	from agret1 as a
	left join agret1 as b on a.code=b.code and a.mthyr=b.mthyr+100
	left join agret1 as c on a.code=c.code and a.mthyr=c.mthyr+200
	left join agret1 as d on a.code=d.code and a.mthyr=d.mthyr+300
	left join agret1 as e on a.code=e.code and a.mthyr=e.mthyr+400;
quit;
*/

proc sort; by code mthyr;
data agret2; set agret1;
by code mthyr;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
*if country="JP" then rhsemp = rhsemp/100;
*if country="US" then rhsemp =  rhsemp*100;
run;

%winsor(dsetin=agret2, dsetout=agret2, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);
/*%winsor(dsetin=agret2, dsetout=agret2, byvar=portyear, vars=lagmv_us, type=winsor, pctl=1 99);*/


data agret3; set agret2;
*if country="US";
*if country in ("BD","CN","HK", "IN", "KO", "MY", "UK", "US"); * top 33%;
*if country in ("AU","FR","JP"); * bottom 33%;
*if country in ("US","JP"); 
*if country in ("BD","CN","HK", "IN", "KO", "MY", "UK", "US","AU","FR","JP"); 
*if rd>0;
*if mc>0;
*if lagemp>0; 
if bm>=0.01;
if bm<=1000;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
*if lagcog_us>0;
*if salesus>0;
globe = 1;
n = 100;
run;
proc means; run;


proc sort data=agret3; by portyear;
proc univariate data=agret3 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret3; merge agret3 price;
by portyear;
if p_us_updated>=p_us_10;
run;




data testdata; set agret3;
portyear = mthyr;
ew=1;
if lagmv_us~=.;
run;
%sprd(testdata, 51, 100000, ret_us, globe, lagmv_us, 10);
data bm_vw_g; set sprd10; run;
%sprd(testdata, 51, 100000, ret_us, globe, ew, 10);
data bm_ew_g; set sprd10; run;

%sprd(testdata, 51, 100000, ret_us, country, lagmv_us, 10);
data bm_vw_cn; set sprd10; run;
%sprd(testdata, 51, 100000, ret_us, country, ew, 10);
data bm_ew_cn; set sprd10; run;







proc sql;
	create table mean_ret_bm as
	select portyear, r, sum(ret_us*lagmv_us)/sum(lagmv_us) as bmret
	from rank
	group by r, portyear;
quit;
proc sql;
	create table bmsum as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
data bm_sprd_g; set sprd10; run;
proc means data=mean_ret_bm; by r; run;


/*
proc sql;
	create table regdata as
	select a.retsprd as bm, b.retsprd as rd, a.portyear as mthyr
	from sprd10_bm as a
	left join sprd10_rhs98 as b on a.portyear=b.portyear;
quit;


proc model data=regdata;
parms a b c d; exogenous bm rd;
instruments (bm, 1 rd) (rd, 1 bm);
bm=a+b*rd;
rd=c+d*bm;
fit bm rd/ gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
*/

%macro regtest(i);
%do i = 91 %to 98;
proc sql;
	create table regdata as
	select a.retsprd as bm, b.retsprd as rdsprd, c.ewret-d.t90ret as ewrf, a.portyear as mthyr
	from sprd10_bm as a
	left join sprd_rhs&i as b on a.portyear=b.portyear
	left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt;
quit;
proc model data=regdata;
parms a b c; exogenous bm;
instruments (bm, 1 rdsprd ewrf);
bm=a+b*rdsprd + c*ewrf;
fit bm / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
data myhml; set hml:;
%mend;
%regtest(i);
proc sort data=myhml; by parameter; run;



%macro regtest(i);
%do i = 91 %to 98;
proc sql;
	create table regdata as
	select a.retsprd as bm, b.retsprd as rdsprd, c.ewret-d.t90ret as ewrf, a.portyear as mthyr
	from sprd10_bm as a
	left join sprd_rhs&i as b on a.portyear=b.portyear
	left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt;
quit;
proc model data=regdata;
parms a c; exogenous bm;
instruments (bm, 1 ewrf);
bm=a+ c*ewrf;
fit bm / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
data myhml; set hml:;
%mend;
%regtest(i);
proc sort data=myhml; by parameter; run;

%macro regtest(i);
%do i = 91 %to 98;
proc sql;
	create table regdata as
	select a.retsprd as bm, b.retsprd as rdsprd, c.ewret-d.t90ret as ewrf, a.portyear as mthyr
	from sprd10_bm as a
	left join sprd_rhs&i as b on a.portyear=b.portyear
	left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt;
quit;
proc model data=regdata;
parms a b; exogenous bm;
instruments (bm, 1 rdsprd);
bm=a+ b*rdsprd;
fit bm / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
data myhml; set hml:;
%mend;
%regtest(i);
proc sort data=myhml; by parameter; run;























































%macro regtest(i);
%do i = 91 %to 98;
%do j = 1 %to 10;
proc sql;
	create table regdata as
	select a.bmret-d.t90ret as bm, b.retsprd as rdsprd, c.ewret-d.t90ret as ewrf, a.portyear as mthyr
	from mean_ret_bm as a
	left join sprd_rhs&i as b on a.portyear=b.portyear
	left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt
	where r=&j;
quit;
proc model data=regdata;
parms a b c; exogenous bm;
instruments (bm, 1 rdsprd ewrf);
bm=a+b*rdsprd + c*ewrf;
fit bm / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param&i&j;
quit;
data param&i&j; set param&i&j; 
model = &i&j;
%end;
%end;
data myparam; set param:;
%mend;
%regtest(i);
proc sort data=myparam; by parameter; run;


proc means data=mean_ret_bm; by r; run;
%let i=91;
%let j=1;









/*country by country
------------------------------*/


data agret3; set agret2;
*if country="US";
*if rd>0;
*if mc>0;
*if lagemp>0; 
*if rhs>0;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
*if lagcog_us>0;
*if salesus>0;
*if bm>=0.001;
*if bm<=1000;
n=100;
run;
proc means; run;


proc sort data=agret3; by country portyear;
proc univariate data=agret3 noprint;
by country portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret3; merge agret3 price;
by country portyear;
if p_us_updated>=p_us_10;
run;




data testdata; set agret3;
portyear = mthyr;
if lagmv_us~=.;
run;
%sprd(testdata,51, 100000, ret_us, country, lagmv_us, 10);
/*proc sql;
	create table mean_ret_bm as
	select portyear, country, r, sum(ret_us*lagmv_us)/sum(lagmv_us) as bmret
	from rank
	group by r, portyear, country;
quit;*/
proc sql;
	create table bmsum as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, country
	from sprd10
	group by country;
quit;
data sprd10_bm; set sprd10; run;
proc means data=sprd10_bm; by country; run;



%macro regtest(i);
%do i = 1 %to 8;
proc sql;
	create table regdata as
	select a.retsprd as bm, b.retsprd as rdsprd, a.portyear as mthyr, a.country as country
	from sprd10_bm as a
	left join sprd_rhs&i as b on a.country=b.country and a.portyear=b.portyear;
quit;

proc model data=regdata;
parms a b; exogenous bm;
instruments (bm, 1 rdsprd);
bm=a+b*rdsprd;
fit bm / gmm kernel=(bart, %eval(1), 0);
by country;
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
data myhml; set hml:;
%mend;
%regtest(i);
proc sort data=myhml; by parameter country; run;
data useful; set myhml;
if tValue<=1.65;
if Parameter="a";
run;
