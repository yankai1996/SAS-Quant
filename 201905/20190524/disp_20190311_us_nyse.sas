
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
  select *, r1 as z&signal
  from rank
  group by &neutral, &timevar;
quit;
%mend;

*libname us 'D:\Dropbox\data_for_kai\Compustat&CRSP merged';
*libname us 'D:\users\tmpuser\Dropbox\data_for_kai\Compustat&CRSP merged';

libname us 'V:\data_for_kai\Compustat&CRSP merged';


data final; set us.agret0; run;

data mvdec_final; set us.mvdec; run;


data agret0; set final;
*portyear = year(datadate) + 1;
if 6000<=sic<=6999 then delete;
proc sort; by code portyear; 
run; 


proc sql;
	create table agret1 as
	select a.*, b.mv_us as lagmv_us
	from agret0 as a
	left join mvdec_final as b on a.code= b.code and a.portyear=b.portyear;
quit;


data agret1; set agret1;
rdme3 = xrd/lagmv_us;
if country='US' then ret_us=ret;
rhs = rdme3;
*if p_us_updated>=p_us_10;
*if ret>-1 and ret<100;
*if ret_us>-1 and ret_us<100;
/*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
/*if country in ("CN", "BD", "FR", "IT", "JP", "UK", "US");*/
cog = cogs;
cog_us = cogs;
rd = xrd;
sga = xsga;
sga_us = xsga;
be = coalesce(SEQ,CEQ+PSTK,AT-LT)+coalesce(sum(itcb,txdb),0)-coalesce(PSTKRV,PSTKL,PSTK);
bm = be/lagmv_us;
if be>=0;
keep ret ret_us mthyr code country portyear at rhs cm mc sale rd rdc roe roa emp cog cog_us sga sga_us hexcd lagmv_us bm be mc_mth;
run;
proc sort; by code mthyr;
data agret1; set agret1;
by code mthyr;
lagmc_mth = lag(mc_mth);
if first.code then lagmc_mth=.;
run;



%let scaler = empbar;

proc sql;
	create table agret2 as
	select a.*, b.emp as lagemp, b.cog as lagcog, b.sga as lagsga, b.rd as lagrd, c.rd as lag2rd, d.rd as lag3rd, e.rd as lag4rd, a.emp-lagemp as empg, b.sale as lagsale, b.at as lagat, b.be as lagbe,
	(a.rd + 0.8*lagrd + 0.6*lag2rd + 0.4*lag3rd + 0.2*lag4rd)/3/a.lagmv_us as rhs2, (1.2*a.rd + .8*lagrd +.4*lag2rd)/2.4/a.lagmv_us as rhs3, 
	(2*a.rd + 1.5*lagrd + 1*lag2rd + .5*lag3rd)/5/a.lagmv_us as rhs4, (a.rd + lagrd)/2/a.lagmv_us as rhs5, c.emp as lag2emp, d.emp as lag3emp, mean(lagemp,lag2emp,lag3emp) as empbar
	from agret1 as a
	left join agret1 as b on a.code=b.code and a.mthyr=b.mthyr+100
	left join agret1 as c on a.code=c.code and a.mthyr=c.mthyr+200
	left join agret1 as d on a.code=d.code and a.mthyr=d.mthyr+300
	left join agret1 as e on a.code=e.code and a.mthyr=e.mthyr+400;
quit;

data agret2; set agret2;
/*rhs2 = coalesce(rhs2,rhs4,rhs3,rhs5,rhs);
rhs3 = coalesce(rhs3,rhs5,rhs); */
rhs2 = coalesce(rhs2,rhs);
rhs3 = coalesce(rhs3,rhs);
rhsemp = (abs(emp-lagemp)+abs(lagemp-lag2emp)+abs(lag2emp-lag3emp))/&scaler;
*rhsemp = (abs(emp-lag3emp))/&scaler;
*rhsemp = (abs(emp-lagemp))/lagemp + (abs(lagemp-lag2emp))/lag2emp + (abs(lag2emp-lag3emp))/lag3emp;
*rhsemp = (abs(emp-lagemp))/emp + (abs(lagemp-lag2emp))/lagemp + (abs(lag2emp-lag3emp))/lag2emp; *does not work;
run;


/*
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
*if country~="US";
if rd>0;
if lagmv_us>0;
*if rhs>0;
*if lagsale>0;
*if lagcog>0;
*if lagsga>0;
*if rhsemp>=0;
if emp>0;
if lagemp>0;
if lag2emp>0;
if lag3emp>0;
if &scaler>0;
globe = 1;
n = 100;
run;



%zscore(agret3, globe, mthyr, rhs, agret4);
%zscore(agret4, globe, mthyr, rhs2,agret4);
%zscore(agret4, globe, mthyr, rhs3,agret4);
%zscore(agret4, globe, mthyr, rhsemp, agret5);


/*  Two way spread independent */

%macro sprd_nyse2(input, rhsrd, rhsemp);

data testdata; set &input;
keep code mthyr portyear country ret_us hexcd lagmc_mth lagmv_us &rhsrd &rhsemp;
proc sort; by mthyr;
run;

*** Rank on rhs using NYSE breakpoints;
proc univariate data=testdata noprint;
   var &rhsrd &rhsemp;
   by mthyr;
   where hexcd=1; 
   output out=BP_nyse
          n=n1 n2
          pctlpts=20 to 80 by 20
          pctlpre=rrd remp;
run;

proc sql;
	*** pick NYSE breakpoints;
	create table bk as
	select a.*, case when a.&rhsrd<b.rrd20 then 1
			when b.rrd20<=a.&rhsrd<b.rrd40 then 2
			when b.rrd40<=a.&rhsrd<b.rrd60 then 3
			when b.rrd60<=a.&rhsrd<b.rrd80 then 4
			else 5 end as rank_rd,
		case when a.&rhsemp<c.remp20 then 1
			when c.remp20<=a.&rhsemp<c.remp40 then 2
			when c.remp40<=a.&rhsemp<c.remp60 then 3
			when c.remp60<=a.&rhsemp<c.remp80 then 4
			else 5 end as rank_emp
	from testdata as a, BP_nyse as b, BP_nyse as c
	where a.mthyr=b.mthyr and a.mthyr=c.mthyr;

	*** Portfolio returns;
	create table mean_ret as
	select rank_rd, rank_emp, mthyr, count(*) as nobs, 
          sum(ret_us*lagmc_mth)/sum(lagmc_mth) as ret_vw
		  /* sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw */
	from bk
	where mthyr>=197607
	group by rank_rd, rank_emp, mthyr;
quit;


%mend;

%sprd_nyse2(agret5, zrhs, r1);



libname pwd "C:\TEMP\displace\20190524";
data pwd.mean_ret6; set mean_ret6; run;


data junk1; set mean_ret5;
if rank_rd=1 and rank_emp=1;
retL=ret_vw;
drop ret_vw;
proc sort; by mthyr;
run;
data junk2; set mean_ret5;
if rank_rd=5 and rank_emp=5;
retH=ret_vw;
drop ret_vw;
proc sort; by mthyr;
run;
data junk3; merge junk1 junk2;
by mthyr;
retpsrd=reth-retL;
proc means;
run;




/*  Two way spread sequential */

%macro sprd_nyse2(input, rhsrd, rhsemp);

data testdata; set &input;
keep code mthyr portyear country ret_us hexcd lagmc_mth lagmv_us &rhsrd &rhsemp;
proc sort; by mthyr;
run;

*** Rank on emp using NYSE breakpoints;
proc univariate data=testdata noprint;
   var &rhsemp;
   by mthyr;
   where hexcd=1; 
   output out=BP_nyse_emp
          n=n1
          pctlpts=20 to 80 by 20
          pctlpre=remp;
run;

proc sql;
	*** pick NYSE breakpoints;
	create table bk1 as
	select a.*, case when a.&rhsrd<b.remp20 then 1
			when b.remp20<=a.&rhsrd<b.remp40 then 2
			when b.remp40<=a.&rhsrd<b.remp60 then 3
			when b.remp60<=a.&rhsrd<b.remp80 then 4
			else 5 end as rank_emp
	from testdata as a, BP_nyse_emp as b
	where a.mthyr=b.mthyr;
quit;


*** Rank on rd using NYSE breakpoints;
proc sort data=bk1; by mthyr rank_emp;
proc univariate data=bk1 noprint;
   var &rhsrd;
   by mthyr rank_emp;
   where hexcd=1; 
   output out=BP_nyse_rd
          n=n2
          pctlpts=20 to 80 by 20
          pctlpre=rrd;
run;

proc sql;
	*** pick NYSE breakpoints;
	create table bk2 as
	select a.*, case when a.&rhsrd<b.rrd20 then 1
			when b.rrd20<=a.&rhsrd<b.rrd40 then 2
			when b.rrd40<=a.&rhsrd<b.rrd60 then 3
			when b.rrd60<=a.&rhsrd<b.rrd80 then 4
			else 5 end as rank_rd
	from bk1 as a, BP_nyse_rd as b
	where a.mthyr=b.mthyr and a.rank_emp=b.rank_emp;

	*** Portfolio returns;
	create table mean_ret as
	select rank_rd, rank_emp, mthyr, count(*) as nobs, 
          sum(ret_us*lagmc_mth)/sum(lagmc_mth) as ret_vw
		  /* sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw */
	from bk2
	where mthyr>=197607
	group by rank_rd, rank_emp, mthyr;
quit;


%mend;

%sprd_nyse2(agret5, zrhs, r1);

