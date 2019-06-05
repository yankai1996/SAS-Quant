
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

libname us 'D:\Dropbox\data_for_kai\Compustat&CRSP merged';


libname us 'D:\users\tmpuser\Dropbox\data_for_kai\Compustat&CRSP merged';

data final; set us.agret0; run;

data mvdec_final; set us.mvdec; run;

proc means data=us.comp; run;

/*
data junk; set final;
portyear2 = year(datadate)+1;
diff = portyear-portyear2;
if diff~=0;
run;
*/
data agret0; set final;
*portyear = year(datadate) + 1;
if 6000<=sic<=6999 then delete;
run;

proc sort data=agret0; by code portyear; run; 
/*
proc sql;
	create table agret1 as
	select a.*, b.mv_us as lagmv_us
	from agret0 as a
	left join mvdec_final as b on a.code= input(b.code,8.) and a.portyear=b.portyear;
quit;
*/

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
%zscore(agret4, globe, mthyr, rhsemp,agret5);

proc sort data=agret5; by mthyr;
proc univariate data=agret5 noprint;
by mthyr;
var zrhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=33 67 75 80 pctlpre=p;
* 75, 80 works with lagemp;
*75 not for lagcog;
run;
data agret5; merge agret5 prt;
by mthyr;
run;


data agret6; set agret5;
rhs1 = .;
rhs2 = .;
rhs3 = .;
rhs4 = .;
if zrhsemp>=p80 then do;
*if rhs>=0 then do;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
end;
rhs5 = zrhs + zrhsemp;
rhs6 = zrhs2 + zrhsemp;
rhs7 = zrhs3 + zrhsemp;
rhs8 = mean(zrhs,zrhs2, zrhs3) + zrhsemp;
portyear = mthyr;
run;
proc means; run;

%macro tests_nyse(i);
%do i = 1 %to 8;
data testdata; set agret6;
rhs = rhs&i;
if rhs~=.;
if lagmv_us~=.;
run;
%sprd_nyse(testdata);
data sprd_rhs&i; set HL_rhs;
rd&i = retsprd;
drop nobs;
data outp; set mysum:; run;
%end;
%mend;
%tests_nyse(i);



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
if zrhsemp>=p75 then do
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


%macro tests_nyse(i);
%do i = 91 %to 98;
data testdata; set agret6;
rhs = rhs&i;
if rhs~=.;
if lagmv_us~=.;
run;
%sprd_nyse(testdata);
data sprd_rhs&i; set HL_rhs;
rd&i = retsprd;
drop nobs;
data outp; set mysum:; run;
%end;
%mend;
%tests_nyse(i);

data sprds; merge sprd_rhs:;
by mthyr;
run;



/* use q5 */



%macro regtest(i);
%do i = 1 %to 98;
%if &i<=8 or &i>=91 %then %do;
proc sql;
	create table regdata as
	select a.retsprd as rdsprd, a.mthyr as mthyr, b.*
	from sprd_rhs&i as a
	left join q5 as b on a.mthyr=b.year*100+b.month
	/*left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt;*/
	where a.mthyr>=197607 and a.mthyr<=201812;
quit;
proc model data=regdata;
parms a b c d e f; exogenous mkt me ia roe eg;
instruments (rdsprd, 1 mkt me ia roe eg);
rdsprd=a+ b*mkt +c*me +d*ia + e*roe + f*eg;
fit rdsprd / gmm kernel=(bart, %eval(2), 0);
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
%end;
data myhml; set hml:;
%mend;
%regtest(i);
proc sort data=myhml; by parameter; run;
proc print; run; 





proc means data=nnnds.acct; run;
proc means data=nnnds.agret0; run;
proc means data=nnds.agret0_newnew; run;




/*  Two way spread */

%macro sprd_nyse2(input1,input2);
*** Rank on rhs using NYSE breakpoints;
proc univariate data=&input1 noprint;
   var rhs;
   by mthyr;
   where hexcd=1; 
   output out=BP_nyse1
          n=nfirms
          pctlpts=20 to 80 by 20
          pctlpre=P;
run;
proc univariate data=&input2 noprint;
   var rhs;
   by mthyr;
   where hexcd=1; 
   output out=BP_nyse2
          n=nfirms
          pctlpts=20 to 80 by 20
          pctlpre=P;
run;
proc sql;
	*** pick NYSE breakpoints;
	create table bk1 as
	select a.*, case when        a.rhs<b.P20 then 1
                    when b.P20<=a.rhs<b.P40 then 2
                    when b.P40<=a.rhs<b.P60 then 3
                    when b.P60<=a.rhs<b.P80 then 4
                    else 5 end as rank_rhs    					
    from &input1 as a, BP_nyse1 as b
	where a.mthyr=b.mthyr; 
	create table bk2 as
	select a.*, case when        a.rhs<b.P20 then 1
                    when b.P20<=a.rhs<b.P40 then 2
                    when b.P40<=a.rhs<b.P60 then 3
                    when b.P60<=a.rhs<b.P80 then 4
                    else 5 end as rank_rhs    					
    from &input2 as a, BP_nyse2 as b
	where a.mthyr=b.mthyr; 

    *** Portfolio returns;
	create table mean_ret1 as
	select rank_rhs, mthyr, count(*) as nobs, 
          sum(ret_us*lagmc_mth)/sum(lagmc_mth) as ret_vw
		  /* sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw */
	from bk1
	where mthyr>=197607
	group by rank_rhs, mthyr;
	create table mean_ret2 as
	select rank_rhs, mthyr, count(*) as nobs, 
		  sum(ret_us*lagmc_mth)/sum(lagmc_mth) as ret_vw
		  /* sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw */
   	from bk2
	where mthyr>=197607
	group by rank_rhs, mthyr;
	
	*** spread;
	create table HL_rhs as
	select a.mthyr, a.ret_vw-b.ret_vw as retsprd, mean(a.nobs,b.nobs) as nobs
	from mean_ret1 as a, mean_ret2 as b
	where a.rank_rhs=5 and b.rank_rhs=1 and a.mthyr=b.mthyr;

	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(510) as tstat, &i as model
	from HL_rhs;

	create table HL_rhs2 as
	select a.mthyr, a.ret_vw-b.ret_vw as retsprd, mean(a.nobs,b.nobs) as nobs
	from mean_ret1 as a, mean_ret1 as b
	where a.rank_rhs=5 and b.rank_rhs=1 and a.mthyr=b.mthyr;

	create table mysum2_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(510) as tstat, &i as model
	from HL_rhs2;
	
	create table HL_rhs3 as
	select a.mthyr, a.ret_vw-b.ret_vw as retsprd, mean(a.nobs,b.nobs) as nobs
	from mean_ret2 as a, mean_ret2 as b
	where a.rank_rhs=5 and b.rank_rhs=1 and a.mthyr=b.mthyr;

	create table mysum3_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(510) as tstat, &i as model
	from HL_rhs3;
	
	/*
	create table HL_rhs as
	select a.mthyr, (a.ret_vw-b.ret_vw-c.ret_vw+d.ret_vw)/2 as retsprd, mean(a.nobs,b.nobs) as nobs
	from mean_ret1 as a, mean_ret1 as b, mean_ret2 as c, mean_ret2 as d
	where a.rank_rhs=5 and b.rank_rhs=1 and c.rank_rhs=5 and d.rank_rhs=1 and a.mthyr=b.mthyr=c.mthyr=d.mthyr;
	
	
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe, mean(retsprd)/std(retsprd)*sqrt(510) as tstat, &i as model
	from HL_rhs;
	*/
quit;
%mend;


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
*rhsemp = (abs(emp-lagemp)+abs(lagemp-lag2emp)+abs(lag2emp-lag3emp))/&scaler;
*rhsemp = (abs(emp-lag3emp))/&scaler;
rhsemp = (abs(emp-lagemp))/lagemp + (abs(lagemp-lag2emp))/lag2emp + (abs(lag2emp-lag3emp))/lag3emp;
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
%zscore(agret4, globe, mthyr, rhsemp,agret5);

proc sort data=agret5; by mthyr;
proc univariate data=agret5 noprint;
by mthyr;
var zrhsemp;
*output out=prt q1=q1 q3=q3;
output out = prt pctlpts=20 33 50 67 75 80 pctlpre=p;
* 75, 80 works with lagemp;
*75 not for lagcog;
run;
data agret5; merge agret5 prt;
by mthyr;
run;


data agret7; set agret5;
rhs1 = .;
rhs2 = .;
rhs3 = .;
rhs4 = .;
if zrhsemp>=p80 then do;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
end;
portyear = mthyr;
run;
data agret8; set agret5;
rhs1 = .;
rhs2 = .;
rhs3 = .;
rhs4 = .;
if zrhsemp<p20 then do;
rhs1 = zrhs;
rhs2 = zrhs2;
rhs3 = zrhs3;
rhs4 = mean(zrhs,zrhs2,zrhs3);
end;
portyear = mthyr;
run;

option notes;
%macro tests_nyse_2(i);
%do i = 1 %to 4;
data testdata1; set agret7;
rhs = rhs&i;
if rhs~=.;
if lagmc_mth~=.;
run;
data testdata2; set agret8;
rhs = rhs&i;
if rhs~=.;
if lagmc_mth~=.;
run;
%sprd_nyse2(testdata1, testdata2);
data sprd_rhs_2&i; set HL_rhs;
rd&i = retsprd;
drop nobs;
data sprd_rhs_2_2&i; set HL_rhs2;
rd&i = retsprd;
drop nobs;
data sprd_rhs_2_3&i; set HL_rhs3;
rd&i = retsprd;
drop nobs;
data outp; set mysum_:; run;
data outp2; set mysum2_:; run;
data outp3; set mysum3_:; run;
%end;
%mend;
%tests_nyse_2(i);


/*
data agret7; set agret5;
rhs = zrhs + zrhsemp;
portyear = mthyr;
if rhs~=.;
if lagmv_us~=.;
run;

%sprd_nyse2(agret7,agret8);
*/




/* use q5 *
proc import out= work.q5
            datafile= "o:\projects\ipp\hmxz.xls"
            dbms=excel replace;
     range="hmxz";
     getnames=yes;
     mixed=no;
     scantext=yes;
     usedate=yes;
     scantime=yes;
run;
*/


%macro regtest_2(i,input);
%do i = 1 %to 4;
%if &i<=8 or &i>=91 %then %do;
proc sql;
	create table regdata as
	select a.retsprd as rdsprd, a.mthyr as mthyr, b.*
	from &input&i as a
	left join q5 as b on a.mthyr=b.year*100+b.month
	/*left join ew_rhs&i as c on a.portyear=c.portyear
	left join db.rf as d on a.portyear=d.caldt;*/
	where a.mthyr>=197607 and a.mthyr<=201812;
quit;
proc model data=regdata;
parms a b c d e f; exogenous mkt me ia roe eg;
instruments (rdsprd, 1 mkt me ia roe eg);
rdsprd=a+ b*mkt +c*me +d*ia + e*roe + f*eg;
fit rdsprd / gmm kernel=(bart, %eval(2), 0);
ods output parameterestimates=hml&i;
quit;
data hml&i; set hml&i; 
model = &i;
%end;
%end;
data myhml; set hml:;
%mend;
%regtest_2(i,sprd_rhs_2);
proc sort data=myhml; by parameter; run;
proc print; run; 
proc sql;
	create table outpdata as
	select a.model as model, a.bar as mean, a.sigma, a.tstat, a.sharpe, b.Estimate as alpha, b.tValue
	from outp as a
	left join myhml as b on a.model=b.model
	where b.parameter="a";
quit;


%regtest_2(i,sprd_rhs_2_2);
proc sort data=myhml; by parameter; run;
proc print; run;
proc sql;
	create table outpdata2 as
	select a.model as model, a.bar as mean, a.sigma, a.tstat, a.sharpe, b.Estimate as alpha, b.tValue
	from outp2 as a
	left join myhml as b on a.model=b.model
	where b.parameter="a";
quit;


%regtest_2(i,sprd_rhs_2_3);
proc sort data=myhml; by parameter; run;
proc print; run; 
proc sql;
	create table outpdata3 as
	select a.model as model, a.bar as mean, a.sigma, a.tstat, a.sharpe, b.Estimate as alpha, b.tValue
	from outp3 as a
	left join myhml as b on a.model=b.model
	where b.parameter="a";
quit;

data outpdat; set outpdata outpdata2 outpdata3; run;

Proc Export Data= outpdat
            /*Outfile= "o:\projects\displace\outp20190323.xls"*/
			/*Outfile= "o:\projects\displace\outp20190413_2way.xls"
			Outfile= "o:\projects\displace\outp20190413_2way_lin.xls"*/
			Outfile= "o:\projects\displace\outp20190428_2way.xls"
            Dbms=Excel replace;
     Sheet=dividethenplus;
Run;
























proc sort data=mean_ret1;
by mthyr;
proc transpose data=mean_ret1 out=wide1 prefix=ret;
    by mthyr;
    id rank_rhs;
    var ret_vw;
run;
data wide1; set wide1; if mthyr>=197607;
proc means; run;
proc sort data=mean_ret2;
by mthyr;
proc transpose data=mean_ret2 out=wide2 prefix=ret;
    by mthyr;
    id rank_rhs;
    var ret_vw;
run;
data wide2; set wide2; if mthyr>=197607;
proc means; run;

proc means data=hl_rhs3; run;


x 'cd D:\Dropbox\data_for_kai';
%include twowaysprd;

data junk; set agret5;
n1=0;
n2=100000;
n=1000;
country=1;
run;

%twowaysprd(junk, n1, n2, 5, 5, rhs, rhsemp, ret, lagmc_mth, country, country, mthyr, twoway);






























* average of 10 and 9 minus average of 2 and 1;
%macro sprd_nyse(input);
*** Rank on rhs using NYSE breakpoints;
proc univariate data=&input noprint;
   var rhs;
   by mthyr;
   where hexcd=1; 
   output out=BP_nyse
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;
proc sql;
	*** pick NYSE breakpoints;
	create table bk as
	select a.*, case when        a.rhs<b.P10 then 1
                    when b.P10<=a.rhs<b.P20 then 2
                    when b.P20<=a.rhs<b.P30 then 3
                    when b.P30<=a.rhs<b.P40 then 4
                    when b.P40<=a.rhs<b.P50 then 5
                    when b.P50<=a.rhs<b.P60 then 6
                    when b.P60<=a.rhs<b.P70 then 7
                    when b.P70<=a.rhs<b.P80 then 8
                    when b.P80<=a.rhs<b.P90 then 9
                    else 10 end as rank_rhs    					
    from &input as a, BP_nyse as b
	where a.mthyr=b.mthyr; 

    *** Portfolio returns;
	create table mean_ret as
	select rank_rhs, mthyr, count(*) as nobs, 
          sum(ret_us*lagmv_us)/sum(lagmv_us) as ret_vw
	from bk
	group by rank_rhs, mthyr;
	
	*** spread;
	create table HL_rhs as
	select a.mthyr, (a.ret_vw+b.ret_vw-c.ret_vw-d.ret_vw)/2 as retsprd, mean(a.nobs,b.nobs) as nobs
	from mean_ret as a, mean_ret as b, mean_ret as c, mean_ret as d
	where a.rank_rhs=10 and b.rank_rhs=9 and c.rank_rhs=1 and d.rank_rhs=2 and a.mthyr=b.mthyr=c.mthyr=d.mthyr;

	*** Sharpe ratio;
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from HL_rhs;
quit;
%mend;
