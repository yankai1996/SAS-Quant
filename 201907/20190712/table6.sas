 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.4
 *   CREATOR:   External File Interface
 *   DATE:      12JUL18
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
    data _null_;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    %let _EFIREC_ = 0;     /* clear export record count macro variable */
    file 'C:\TEMP\displace\20190712\model2_vw.csv' delimiter=',' DSD DROPOVER lrecl=32767;
    if _n_ = 1 then        /* write column names or labels */
     do;
       put
          "country"
       ','
          "_NAME_"
       ','
          "a"
       ','
          "b"
       ','
          "c"
       ;
     end;
   set  MODEL2_VW   end=EFIEOD;
       format country $20. ;
       format _NAME_ $8. ;
       format a best12. ;
       format b best12. ;
       format c best12. ;
     do;
       EFIOUT + 1;
       put country $ @;
       put _NAME_ $ @;
       put a @;
       put b @;
       put c ;
       ;
     end;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    if EFIEOD then call symputx('_EFIREC_',EFIOUT);
    run;


libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";



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


libname pwd "C:\TEMP\displace\20190712";

data testdata; set agret3;
portyear = mthyr;
ew=1;
if lagmv_us~=.;
run;
%sprd(testdata, 30, 100000, ret_us, globe, lagmv_us, 10);
data pwd.bm_vw_g; set sprd10; run;
%sprd(testdata, 30, 100000, ret_us, globe, ew, 10);
data pwd.bm_ew_g; set sprd10; run;

%sprd(testdata, 30, 100000, ret_us, country, lagmv_us, 10);
data pwd.bm_vw_cn; set sprd10; run;
%sprd(testdata, 30, 100000, ret_us, country, ew, 10);
data pwd.bm_ew_cn; set sprd10; run;



proc sort data=testdata; by portyear;
proc means data=testdata noprint; by portyear;
var ret_us; output out=ewret mean=ewret;
run;
proc means data=testdata noprint; by portyear;
var ret_us; weight lagmv_us; output out=vwret mean=vwret;
run;

data mktret; merge ewret vwret;
by portyear;
drop _type_ _freq_;
run;

proc sql;
create table mktret as 
select a.*, b.rf, a.ewret-b.rf/100 as ewrf, a.vwret-b.rf/100 as vwrf
from mktret as a left join pwd.hkk as b
on a.portyear=b.mthyr;
quit;

data pwd.mktret; set mktret; run;





%macro regtest(weight, model, neutral, output);

%if &neutral=country %then %do;
proc sql;
	create table regdata as
	select a.portyear, a.country, a.retsprd as bm, b.retsprd as rdsprd, c.&weight.rf
	from pwd.bm_&weight._cn as a
	left join pwd.cn_&weight._sprd as b on a.portyear=b.portyear and a.country=b.country
	left join pwd.mktret as c on a.portyear=c.portyear;
quit;
%end; %else %do;
proc sql;
	create table regdata as
	select a.portyear, a.retsprd as bm, b.retsprd as rdsprd, c.&weight.rf
	from pwd.bm_&weight._g as a
	left join pwd.g_&weight._sprd as b on a.portyear=b.portyear
	left join pwd.mktret as c on a.portyear=c.portyear;
quit;
%end;

data regdata; set regdata;
if rdsprd~=.;
globe="world";
proc sort; by &neutral;
run;


proc model data=regdata;
by &neutral;
parms a b c; exogenous bm;
%if &model=1 %then %do;
instruments (bm, 1 rdsprd);
bm=a+b*rdsprd;
%end; %else %do;
instruments (bm, 1 rdsprd &weight.rf);
bm=a+b*rdsprd + c*&weight.rf;
%end;
fit bm / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=&output;
quit;


proc transpose data=&output out=&output;
by &neutral;
var Estimate tValue;
id Parameter;
run;


%mend regtest;

%regtest(ew, 1, country, model1_ew_cn);
%regtest(vw, 1, country, model1_vw_cn);
%regtest(ew, 1, globe, model1_ew_g);
%regtest(vw, 1, globe, model1_vw_g);
%regtest(ew, 2, country, model2_ew_cn);
%regtest(vw, 2, country, model2_vw_cn);
%regtest(ew, 2, globe, model2_ew_g);
%regtest(vw, 2, globe, model2_vw_g);


%macro outreg(output);

data &output; set &output._:;
if country="" then country="world";
drop globe _label_;
run;

proc export data=&output
	outfile="C:\TEMP\displace\20190712\&output..csv"
	dbms=csv
	replace;
run;

%mend outreg;

%outreg(model1_ew);
%outreg(model1_vw);
%outreg(model2_ew);
%outreg(model2_vw);

