

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


x 'cd D:\Dropbox\data_for_kai';
%include 'winsor.sas';

libname DB 'V:\data_for_kai';
libname nDS 'V:\data_for_kai\new DSWS\merged';
libname nnDS 'V:\data_for_kai\newnew_DSWS\merged';
libname export 'V:\data_for_kai\new data';
libname nnnDS 'V:\data_for_kai\WSDS20190215';
libname us 'V:\data_for_kai\Compustat&CRSP merged';




x 'cd D:\users\tmpuser\Dropbox\data_for_kai';
%include 'winsor.sas';

libname DB 'D:\users\tmpuser\Dropbox\data_for_kai';
libname nDS 'D:\users\tmpuser\Dropbox\data_for_kai\new DSWS\merged';
libname nnDS 'D:\users\tmpuser\Dropbox\data_for_kai\newnew_DSWS\merged';
libname export 'D:\users\tmpuser\Dropbox\data_for_kai\new data';
libname nnnDS 'D:\users\tmpuser\Dropbox\data_for_kai\WSDS20190215';
libname us 'D:\users\tmpuser\Dropbox\data_for_kai\Compustat&CRSP merged';



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



%let scaler = lagcog;

proc sql;
	create table agret2 as
	select a.*, a.cog as cog, b.cog_us as lagcog_us, b.emp as lagemp, b.sga_us as lagsga_us, b.cog as lagcog, b.sga as lagsga, b.salesus as lagsale_us, a.sales as lagsale,
	b.rd as lagrd, c.rd as lag2rd, d.rd as lag3rd, e.rd as lag4rd,
	(a.rd + 0.8*lagrd + 0.6*lag2rd + 0.4*lag3rd + 0.2*lag4rd)/3/a.mc as rhs2, (1.2*a.rd + 0.8*lagrd + 0.4*lag2rd)/2.4/a.mc as rhs3, abs(a.emp-lagemp)/&scaler as rhsemp
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
if rd>0;
if mc>0;
*if rhs>0;
/* if rhs2~=.;*/
*if lagsga_us>0;
*if rhsemp>=0;
*if lagcog_us>0;
*if salesus>0;

/*** filter ***/
if lagemp>0; 
if &scaler>0;
globe = 1;
n = 100;
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


%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret4);
%zscore(agret4, globe, mthyr, rhs3,agret4);
%zscore(agret4, globe, mthyr, rhsemp,agret5);

proc sort data=agret5; by mthyr;
proc univariate data=agret5 noprint;
by mthyr;
var zrhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=33 67 80 pctlpre=p;
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
	select mean(retsprd) as mean, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(426) as tstat, &i as model
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
*if zrhsemp<=p33 then do;
if zrhsemp>=p67 then do
rhs91 = zrhs; 
rhs92 = zrhs2;
rhs93 = zrhs3; 
rhs94 = mean(zrhs,zrhs2,zrhs3); 
end;
if zrhsemp>=p80 then do
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
	select mean(retsprd) as mean, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(426) as tstat, &i as model
	from sprd10;
quit;
%end;
data outp; set mysum:; run;
%mend;
%tests(i);




Proc Export Data= outp
            Outfile= "o:\projects\displace\outp20190323_intl.xls"
            Dbms=Excel replace;
     Sheet=benchmark;
Run;











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
