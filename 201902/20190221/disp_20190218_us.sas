
libname us 'D:\Dropbox\data_for_kai\Compustat&CRSP merged';
/* if use newnew */
data final; set us.agret0;
data mvdec_final; set us.mvdec;

data junk; set final;
diff = portyear-fyear;
if diff~=1;
run;

data final; set final;
portyear = fyear + 1;
run;

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
rdme3 = xrd/mc;
if country='US' then ret_us=ret;
rhs = rdme3;
if p_us_updated>=p_us_10;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10;
/*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
/*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");*/
cog = cogs;
cog_us = cogs;
rd = xrd;
sga = xsga;
sga_us = xsga;
keep ret ret_us mthyr code country portyear ta rhs cm mc sl rd rdc roe roa emp cog cog_us sga sga_us;
run;

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
	(a.rd + 0.8*lagrd + 0.6*lag2rd + 0.4*lag3rd + 0.2*lag4rd)/3/a.mc as rhs2, (a.rd + 0.8*lagrd + 0.6*lag2rd)/2.4/a.mc as rhs3, abs(a.emp-lagemp)/lagcog as rhsemp
	from agret1 as a
	left join agret1 as b on a.code=b.code and a.mthyr=b.mthyr+100
	left join agret1 as c on a.code=c.code and a.mthyr=c.mthyr+200
	left join agret1 as d on a.code=d.code and a.mthyr=d.mthyr+300
	left join agret1 as e on a.code=e.code and a.mthyr=e.mthyr+400;
quit;

proc sort data=agret2; by code mthyr;
data agret2; set agret2;
by code mthyr;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
run;

/*%winsor(dsetin=agret2, dsetout=agret2, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);
/*%winsor(dsetin=agret2, dsetout=agret2, byvar=portyear, vars=lagmv_us, type=winsor, pctl=1 99);*/

data agret3; set agret2;
/*if country~="US";
if rd>0;*/
if rhs>0;
if cog>0;
if rhsemp>=0;
globe = 1;
n = 100;
run;
%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret4);
%zscore(agret4, globe, mthyr, rhs3,agret4);
%zscore(agret4, globe, mthyr, rhsemp,agret5);

data agret6; set agret5;
rhs = mean(zrhs,zrhs2,zrhs3) + zrhsemp;
portyear = mthyr;
run;

%sprd(agret6, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);
 
/* compare old with only RD */

data agret7; set agret5;
rhs = zrhs;
portyear = mthyr;
run;


data agret7; set agret5;
rhs =  zrhs+zrhsemp;
portyear = mthyr;
run;
%sprd(agret7, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);
/* should be the same as */



data agret7; set agret5;
rhs = zrhsemp;
portyear = mthyr;
run;
%sprd(agret7, 51, 100000, ret_us, globe, lagmv_us, 10);
%NWtest(sprd10, 0, param0);








