
/*------------------------------------------------------------------------------- */
/* -------------------  One Way Sorting --------------------------------------------
/* rank firms into tercile/quintile/deciles based on rhs;
/* compute rhsspread, retspread, and stdspread

input: can be either local currency or USD data
n1: size of a cross section
n2: size of a cross section
	if the number of firms is between 30 and 50, form terciles
	if the number of firms is between 50 and 100, form quintiles
	if the number of firms is between 100 and 10000, form deciles
ret: return can be either local currency or USD
sort: indicates it is neutral by what, country? region? or world?
weighting1:	for Spread calculations, either equal or value
weighting2:	for Slope calculations, either equal or relative market value to the cross section
ngroup: generally each group will have at least 10 firms
-------------------------------------------------------------------------------- */

%macro sprd(input, n1, n2, ret, sort, weighting1, ngroup);
data sub; set &input;
if &n1<=n<&n2;

proc sort; by &sort portyear;
proc rank data=sub group=&ngroup out=rank;
var rhs; by &sort portyear; ranks r;

data rank; set rank; r=r+1;
run;
proc sort; by portyear &sort r;

proc means data=rank noprint; by portyear &sort r;
var rhs &ret; weight &weighting1;
output out=rhs1 mean=rhs ret;
run;

data bot; set rhs1; if r in (1); bot1=rhs; bot2=ret; keep &sort portyear bot1 bot2; proc sort; by &sort portyear;
data top; set rhs1; if r in (&ngroup); top1=rhs; top2=ret; keep &sort portyear top1 top2; proc sort; by &sort portyear;

data sprd&ngroup; merge bot top;
by &sort portyear;
rhssprd = top1-bot1;
retsprd = top2-bot2;
stdsprd = retsprd/rhssprd;
keep &sort portyear rhssprd retsprd stdsprd;
run;
%mend;

/*------------------------------------------------------------------------------- */
/* Country summary stats; need to adjust the standard erros (neweywest)
therefore have to do a GMM (SAS sucks), but nests the regular summary stats
use only 1 lrhs in kernel=(bart, %eval(lrhss+1), 0);

output: should be some times series of zero cost strategy
sort: indicates it is neutral by what, country? region? or world?
outstat: output the statistics
/*------------------------------------------------------------------------------- */

%macro NWavg(output, sort, lags, outstat);
proc model data=&output;
by &sort;
parms rhssprdbar retsprdbar slopebar; exogenous rhssprd retsprd slope;
instruments / intonly;
rhssprd = rhssprdbar;
retsprd = retsprdbar;
stdsprd = stdsprdbar;
slope = slopebar;
/* fit rhssprd retsprd stdsprd slope / gmm kernel=(bart, %eval(2), 0); */
fit retsprd slope / gmm kernel=(bart, %eval(1+&lags), 0);
ods output parameterestimates=param0;
quit;

data &outstat; set param0;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.3);
prob=put(probt,7.3);
stder=put(stderr, 7.3);
T=compress('('||tvalue||')');
drop EstType est StdErr probt DF T _type_;  /*may keep these information */
run;

proc sort data=&outstat;
by parameter;
run;
%mend;

/*------------------------------------------------------------------------------- */
/* Calculate the rhs effects	taking the above two already defined

input: can be either local currency or USD data
ret: return can be either local currency or USD
sort: indicates it is neutral by what, country? region? or world?
weighting1:	for Spread calculations, either equal or value
weighting2:	for Slope calculations, either equal or relative market value to the cross section
output: should be some times series of zero cost strategy
outstat: output the statistics
/*------------------------------------------------------------------------------- */

%macro rhseffect(input, ret, sort, weighting1, weighting2, output, lags, outstat);

/*%sprd(&input, 10, 50, &ret, &sort, &weighting1, 3);
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
data sprd; set sprd3 sprd5;
/*
%sprd(&input, 10, 100000, &ret, &sort, &weighting1, 1);
data sprd; set sprd1;
*/

/*%sprd(&input, 1, 30, &ret, &sort, &weighting1, 3);
%sprd(&input, 30, 100000, &ret, &sort, &weighting1, 5);

%sprd(&input, 4, 49, &ret, &sort, &weighting1, 3);
*/
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
*%sprd(&input, 51, 100000, &ret, &sort, &weighting1, 10);
/*data sprd; set sprd3 sprd5;
/*data sprd; set sprd10; */
data sprd; set sprd5;


proc sort; by &sort portyear;
run;

/* rhs predictive regression slope */

proc sort data=&input; by &sort portyear;
run;
proc reg data=&input noprint outest=coef edf;
model &ret=rhs;
by &sort portyear;
weight &weighting2;
run;
data coef; set coef;
slope=rhs;
keep &sort portyear slope;
run;

/* all measures of rhs effect
/* combines the sort based and slope
/* now the portfolio year is from t to t+12
/* in reality is from t+6 to t+18 */

data &output; merge sprd coef;
by &sort portyear;
/* if (slope ne . and retsprd ne . and rhssprd ne .); */
expostyear = portyear + 1;
proc sort; by &sort;
run;

/* Country summary stats */
%NWavg(&output, &sort, &lags, &outstat);
%mend;

x 'cd D:\Dropbox\data_for_kai';
%include 'winsor.sas';

libname DB 'D:\Dropbox\data_for_kai';
libname nDS 'D:\Dropbox\data_for_kai\new DSWS\merged';
libname nnDS 'D:\Dropbox\data_for_kai\newnew_DSWS\merged';
libname export 'D:\Dropbox\data_for_kai\new data';
libname nnnDS 'D:\Dropbox\data_for_kai\WSDS20190215';
libname us 'D:\Dropbox\data_for_kai\Compustat&CRSP merged';




x 'cd D:\users\tmpuser\Dropbox\data_for_kai';
%include 'winsor.sas';

libname DB 'D:\users\tmpuser\Dropbox\data_for_kai';
libname nDS 'D:\users\tmpuser\Dropbox\data_for_kai\new DSWS\merged';
libname nnDS 'D:\users\tmpuser\Dropbox\data_for_kai\newnew_DSWS\merged';
libname export 'D:\users\tmpuser\Dropbox\data_for_kai\new data';
libname nnnDS 'D:\users\tmpuser\Dropbox\data_for_kai\WSDS20190215';
libname us 'D:\users\tmpuser\Dropbox\data_for_kai\Compustat&CRSP merged';


/* if use old */
data final; set db.A4;
data mvdec_final; set db.mvdec_all;

/* if use newnew */
data final; set nnds.agret0_newnew;
data mvdec_final; set nnds.mvdec_newnew;

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
rdme3 = rd/mc;
if country='US' then ret_us=ret;
rhs = rdme3;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<100;
if rd>0;
*if cog>0;
if mc>0;
*if emp>0;
*if sga>0;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");
*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK");
*if country in ("BD");
keep ret ret_us mthyr code country portyear ta rhs cm mc sales salesus rd rdc roe roa emp cog sga p_us_updated;
run;


proc sort; by code portyear;
run;

data agret1; merge agret0(in=a) mvdec_final(in=b);
by code portyear;
if a and b;
lagmv_us = mv_us;
run;



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
if rhs>0;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
*if lagcog_us>0;
*if salesus>0;
globe = 1;
run;



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

%let nobs=50;
/*********************************************************************/
/* scale within a country */
proc sort data=agret3;
by country mthyr;
run;
proc means data=agret3 noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret3(in=a) meanmv(in=b);
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
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>&nobs;
run;

%rhseffect(tem, ret_us, country, ew, ew, outpew, 5, out_us_ew);
data country_ew_sprd; set outpew;
keep country portyear retsprd;
run;
data country_ew_slope; set outpew;
keep country portyear slope;
run;

%rhseffect(tem, ret_us, country, lagmv_us, mvport, outpvw, 5, out_us_vw);
data country_vw_sprd; set outpvw;
keep country portyear retsprd;
run;
data country_vw_slope; set outpvw;
keep country portyear slope;
run;





proc sort data=sprd.country_vw_sprd;
by country portyear;
proc sort data=sprd.country_vw_slope;
by country portyear;
data country_vw_slope; merge sprd.country_vw_sprd(in=a) sprd.country_vw_slope(in=b);
by country portyear;
if a and b;
run;

proc sort data=sprd.country_ew_sprd;
by country portyear;
proc sort data=sprd.country_ew_slope;
by country portyear;
data country_ew_slope; merge sprd.country_ew_sprd(in=a) sprd.country_ew_slope(in=b);
by country portyear;
if a and b;
run;


proc univariate data=country_vw_slope; run;












































%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret4);
%zscore(agret4, globe, mthyr, rhs3,agret4);
%zscore(agret4, globe, mthyr, rhsemp,agret5);

proc sort data=agret5; by mthyr;
proc univariate data=agret5 noprint;
by mthyr;
var zrhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=33 67 pctlpre=p;
run;
data agret5; merge agret5 prt;
by mthyr;
run;


data agret6; set agret5;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
rhs5 = zrhs + zrhsemp;
rhs6 = zrhs2 + zrhsemp;
rhs7 = zrhs3 + zrhsemp;
rhs8 = mean(zrhs,zrhs2,zrhs3) + zrhsemp;
portyear = mthyr;
run;

%macro tests(i);
%do i = 1 %to 8;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
run;
%sprd(testdata,51, 100000, ret_us, globe, lagmv_us, 10);
proc sql;
	create table mean_ret as
	select portyear, r, sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw
	from rank
	group by r, portyear;
	create table ew_rhs&i as
	select mean(ret_vw) as ewret, portyear
	from mean_ret
	group by portyear;
quit;	
data sprd_rhs&i; set sprd10;
rd&i = retsprd;
proc sql;
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);


data agret6; set agret5;
rhs91 = .; 
rhs92 = .;
rhs93 = .; 
rhs94 = .;
rhs95 = .; 
rhs96 = .;
rhs97 = .; 
rhs98 = .;
if zrhsemp<=p33 then do
rhs91 = zrhs; 
rhs92 = zrhs2;
rhs93 = zrhs3; 
rhs94 = mean(zrhs,zrhs2,zrhs3); 
end;
if zrhsemp>=p67 then do
rhs95 = zrhs; 
rhs96 = zrhs2;
rhs97 = zrhs3; 
rhs98 = mean(zrhs,zrhs2,zrhs3); 
end;
portyear = mthyr;
run;


%macro tests(i);
%do i = 91 %to 98;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
if rhs~=.;
run;
%sprd(testdata,51, 100000, ret_us, globe, lagmv_us, 10);
proc sql;
	create table mean_ret as
	select portyear, r, sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw
	from rank
	group by r, portyear;
	create table ew_rhs&i as
	select mean(ret_vw) as ewret, portyear
	from mean_ret
	group by portyear;
quit;	
data sprd_rhs&i; set sprd10;
rd&i = retsprd;
proc sql;
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);





/*country by country
------------------------------*/


data agret3; set agret2;
*if country="US";
*if rd>0;
*if mc>0;
*if lagemp>0; 
if rhs>0;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
if lagcog_us>0;
*if salesus>0;
globe = 1;
n = 100;
run;

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


%zscore(agret3, country, mthyr, rhs, agret4);
%zscore(agret4, country, mthyr, rhs2,agret4);
%zscore(agret4, country, mthyr, rhs3,agret4);
%zscore(agret4, country, mthyr, rhsemp,agret5);

proc sort data=agret5; by country mthyr;
proc univariate data=agret5 noprint;
by country mthyr;
var zrhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=33 67 pctlpre=p;
run;
data agret5; merge agret5 prt;
by country mthyr;
run;


data agret6; set agret5;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
rhs5 = zrhs + zrhsemp;
rhs6 = zrhs2 + zrhsemp;
rhs7 = zrhs3 + zrhsemp;
rhs8 = mean(zrhs,zrhs2,zrhs3) + zrhsemp;
portyear = mthyr;
run;

%macro tests(i);
%do i = 1 %to 8;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
run;
%sprd(testdata,51, 100000, ret_us, country, lagmv_us, 10);
proc sql;
	create table mysum_&i as
	select (country) as country, mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10
	group by country;
quit;
data sprd_rhs&i; set sprd10;
rd&i = retsprd;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);



data agret6; set agret5;
rhs91 = .; 
rhs92 = .;
rhs93 = .; 
rhs94 = .;
rhs95 = .; 
rhs96 = .;
rhs97 = .; 
rhs98 = .;
if zrhsemp<=p33 then do
rhs91 = zrhs; 
rhs92 = zrhs2;
rhs93 = zrhs3; 
rhs94 = mean(zrhs,zrhs2,zrhs3); 
end;
if zrhsemp>=p67 then do
rhs95 = zrhs; 
rhs96 = zrhs2;
rhs97 = zrhs3; 
rhs98 = mean(zrhs,zrhs2,zrhs3); 
end;
portyear = mthyr;
run;

/*
proc means data=agret6; by country portyear;
var rhs97;
output out=namesob n=n;
run;
data tem; set agret6;
if country="UK";
if mthyr=199107;
if rhs97~=.;
run;
*/
%macro tests(i);
%do i = 91 %to 98;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
if rhs~=.;
run;
%sprd(testdata,51, 100000, ret_us, country, lagmv_us, 10);
proc sql;
	create table mysum_&i as
	select (country) as country, mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10
	group by country;
quit;
data sprd_rhs&i; set sprd10;
rd&i = retsprd;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);


proc sort data=outp; by country; run;

















/**** this also work ***/


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
rdme3 = rd/mc;
if country='US' then ret_us=ret;
rhs = rdme3;
*if ret>-1 and ret<10;
if ret_us>-1 and ret_us<100;
if rd>0;
*if cog>0;
if mc>0;
*if emp>0;
*if sga>0;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");
*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK");
*if country in ("BD");
keep ret ret_us mthyr code country portyear ta rhs cm mc sales salesus rd rdc roe roa emp cog sga p_us_updated;
run;

/*proc sort; by code portyear; run; */


proc sql;
	create table agret0 as
	select a.*, b.cogs as cog2, b.ni, b.nius, a.cog-b.cogs as diff, b.nius/b.ni as fx, a.cog*b.nius/b.ni as cog_us, a.sga*b.nius/b.ni as sga_us, coalesce(b.cogs,a.cog) as cog, 
coalesce(b.emp,a.emp) as emp, b.ta as ta, b.ta*b.nius/b.ni as ta_us
	from agret0 as a
	left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;


proc sort; by code portyear;
run;

data agret1; merge agret0(in=a) mvdec_final(in=b);
by code portyear;
if a and b;
lagmv_us = mv_us;
run;




proc sql;
	create table agret2 as
	select a.*, a.cog as cog, b.cog_us as lagcog_us, b.emp as lagemp, b.sga_us as lagsga_us, b.cog as lagcog, b.sga as lagsga, b.rd as lagrd, c.rd as lag2rd, d.rd as lag3rd, e.rd as lag4rd,
	(a.rd + 0.8*lagrd + 0.6*lag2rd + 0.4*lag3rd + 0.2*lag4rd)/3/a.mc as rhs2, (a.rd + 0.8*lagrd + 0.6*lag2rd)/2.4/a.mc as rhs3, abs(a.emp-lagemp)/lagcog_us as rhsemp, b.sales as lagsales,
	b.ta as lagta
	from agret1 as a
	left join agret1 as b on a.code=b.code and a.mthyr=b.mthyr+100
	left join agret1 as c on a.code=c.code and a.mthyr=c.mthyr+200
	left join agret1 as d on a.code=d.code and a.mthyr=d.mthyr+300
	left join agret1 as e on a.code=e.code and a.mthyr=e.mthyr+400;
quit;

proc sort; by code mthyr;
data agret2; set agret2;
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
if rhs>0;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
*if lagcog_us>0;
*if salesus>0;
globe = 1;
n = 100;
run;



%winsor(dsetin=agret3, dsetout=agret4, byvar=portyear country, vars=, type=winsor, pctl=1 99);
data testdata; set agret4;
*rhs1 = rhs;
rhs = rd/sales + abs(emp-lagemp)/lagcog_us;
if lagmv_us~=.;
if lagcog_us>0;
if lagemp>0;
if emp>0;
if sales>0;
if mc>0;
portyear = mthyr;
run;
%sprd(testdata,51, 100000, ret_us, globe, lagmv_us, 10);
proc sql;
	create table mysum as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
proc print; run;

proc means data=testdata; run;










proc sort data=agret3; by mthyr;
proc univariate data=agret3 noprint;
by mthyr;
var rhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=33 67 pctlpre=p;
run;
data agret3; merge agret3 prt;
by mthyr;
if rhsemp>=p67;
run;

%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret4);
%zscore(agret4, globe, mthyr, rhs3,agret4);
%zscore(agret4, globe, mthyr, rhsemp,agret5);

data agret6; set agret5;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
portyear = mthyr;
run;

%macro tests(i);
%do i = 1 %to 4;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
run;
%sprd(testdata,51, 100000, ret_us, globe, lagmv_us, 10);
proc sql;
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);
