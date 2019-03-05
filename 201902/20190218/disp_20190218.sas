
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

%macro NWtest(output, lags, outstat);
proc model data=&output;
parms retsprdbar; exogenous retsprd;
instruments / intonly;
retsprd = retsprdbar;
fit retsprd / gmm kernel=(bart, %eval(1+&lags), 0);
ods output parameterestimates=&outstat;
quit;
%mend;




libname DB 'V:\data_for_kai';
libname nDS 'V:\data_for_kai\new DSWS\merged';
libname nnDS 'V:\data_for_kai\newnew_DSWS\merged';
libname export 'V:\data_for_kai\new data';
libname nnnDS 'V:\data_for_kai\WSDS20190215';


libname DB 'D:\users\tmpuser\Dropbox\data_for_kai';
libname nDS 'D:\users\tmpuser\Dropbox\data_for_kai\new DSWS\merged';
libname nnDS 'D:\users\tmpuser\Dropbox\data_for_kai\newnew_DSWS\merged';
libname export 'D:\users\tmpuser\Dropbox\data_for_kai\new data';
libname nnnDS 'D:\users\tmpuser\Dropbox\data_for_kai\WSDS20190215';


data agret0; set db.agret0;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated;
if (country="US" and mthyr<201307) or (country~="US" and mthyr<201207);
run;

data agret1_us; set export.agret1_us; run;
data agret1_xus; set export.agret1_xus; run;


data old; set agret0 agret1_us agret1_xus; 
flag=1;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated flag;
run;
proc sort; by code mthyr;
data old; set old;
by code mthyr;
if code=lag(code) & mthyr=lag(mthyr) then delete;
run;



data new; set nds.agret0_new_dsws; 
COG = COGS;
flag=2;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated flag;
run;




/* yet another way to expand ``old'' then combine in one step */
proc sql;
	create table A4 as
	select coalesce(a.code,b.code) as code,
coalesce(a.country,b.country) as country,
coalesce(a.mthyr,b.mthyr) as mthyr,
coalesce(a.portyear,b.portyear) as portyear,
coalesce(a.year,b.year) as year,
coalesce(a.ret,b.ret) as ret,
coalesce(a.ret_us,b.ret_us) as ret_us,
coalesce(a.MC,b.MC) as MC,
coalesce(a.RD,b.RD) as RD,
coalesce(a.EMP,b.EMP) as EMP,
coalesce(a.COG,b.COG) as COG,
coalesce(a.SGA,b.SGA) as SGA,
coalesce(a.p_us_updated,b.p_us_updated) as p_us_updated,
coalesce(a.flag,b.flag) as flag
	from old as a
	full join new as b on a.code=b.code and a.mthyr=b.mthyr;
quit;


proc sql;
	create table mvdec_old as
	select coalesce(a.code,b.code) as code,
coalesce(a.portyear,b.portyear) as portyear,
coalesce(a.year,b.year) as year,
coalesce(a.mv,b.mv) as mv,
coalesce(a.mv_us,b.mv_us) as mv_us
	from db.mvdec as a
	full join export.mvdec_new as b on a.code=b.code and a.portyear=b.portyear;
quit;

proc sql;
	create table mvdec_all as
	select coalesce(a.code,b.code) as code,
coalesce(a.portyear,b.portyear) as portyear,
coalesce(a.year,b.year) as year,
coalesce(a.mv,b.mv) as mv,
coalesce(a.mv_us,b.mv_us) as mv_us
	from mvdec_old as a
	full join nds.mvdec_new_dsws as b on a.code=b.code and a.portyear=b.portyear;
quit;




%macro zscore(input, neutral, timevar, signal, output);
proc sort data=&input;
by &neutral &timevar;
run;

proc rank data=&input out=rank;
var &signal;
by &neutral &timevar;
ranks r1;
run;

proc sql;
  create table &output as
  select *, (r1-avg(r1))/std(r1) as z&signal
  from rank
  group by &neutral, &timevar;
quit;
%mend;


/* if use old */
data final; set db.A4;
data mvdec_final; set db.mvdec_all;

/* if use newnew */
data final; set nnds.agret0_newnew;
data mvdec_final; set nnds.mvdec_newnew;




proc sort data=final; by portyear;
proc univariate data=final noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret0; merge final price;
by portyear;
drop flag;
proc sort; by code portyear;
run;
data agret0; set agret0;
rdme3 = rd/mc;
if country='US' then ret_us=ret;
rhs = rdme3;
if p_us_updated>=p_us_10;
/*if ret>-1 and ret<10;*/
if ret_us>-1;
/*and ret_us<100;*/
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
/*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");*/
keep ret ret_us mthyr code country portyear ta rhs cm mc sl rd rdc roe roa emp cog sga;
run;
proc sql;
	create table agret0 as
	select a.*, b.cogs as cog2, b.ni, b.nius,a.cog-b.cogs as diff, a.cog*b.nius/b.ni as cog_us, a.sga*b.nius/b.ni as sga_us, coalesce(b.cogs,a.cog) as cog, coalesce(b.emp,a.emp) as emp
	from agret0 as a
	left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;
/*
data junk; set agret0;
if diff~=0 & diff~=.;
run;
proc means; run;
*/

proc sort data=agret0; by code portyear;
run;

data agret1; merge agret0(in=a) mvdec_final(in=b);
by code portyear;
if a and b;
lagmv_us = mv_us;
run;

proc sql;
	create table agret2 as
	select a.*, a.cog as cog, b.cog_us as lagcog_us, b.emp as lagemp, b.sga_us as lagsga_us, b.cog as lagcog, b.sga as lagsga
	from agret1 as a
	left join agret1 as b on a.code=b.code and a.mthyr=b.mthyr+100;
quit;
data agret2; set agret2;
rhs2 = abs(emp-lagemp)/lagcog_us;
run;
proc sort; by code mthyr;
data agret2; set agret2;
by code mthyr;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
run;

/* %winsor(dsetin=agret2, dsetout=agret2, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);*/
/*%winsor(dsetin=agret2, dsetout=agret2, byvar=portyear, vars=lagmv_us, type=winsor, pctl=1 99);*/

data agret3; set agret2;
/*if country~="US";*/
if rhs>0;
/* if rhs2~=.;*/
globe = 1;
n = 100;
run;
%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret5);

data agret6; set agret5;
rhs = zrhs + zrhs2;
portyear = mthyr;
run;

%sprd(agret6, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);
 
/* compare old with only RD */

data agret7; set agret5;
rhs = zrhs;
portyear = mthyr;
run;
%sprd(agret7, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);
/* should be the same as */
%sprd(agret5, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);


proc means data=agret5; run;
/* compare old with newnew */

proc sql;
 create table not_in_new as
 select * from agret6_old as a
 where code not in (select code from agret6_new)
 order by code;
quit; /* 21,291 obs*/
proc means; run;
proc sql;
 create table not_in_old as
 select * from agret6_new as a
 where code not in (select code from agret6_old)
 order by code;
quit; /* 24,424 obs */


proc sql;
create table junk as
select a.portyear as portyear, a.retsprd as x_o, b.retsprd as x_n, x_o-x_n as diff
from sprd10_old as a
left join sprd10_new as b on a.portyear=b.portyear;
quit;











