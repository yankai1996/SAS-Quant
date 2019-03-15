

libname db "V:\data_for_kai";
libname nnnDS 'V:\data_for_kai\WSDS20190215';

data mvdec; set nnnDS.mvdec; run;


/* sprd country level */
/*
data final; set nnnDS.agret0;
COG_US = COGS*NIUS/NI;
SGA_US = SGA*NIUS/NI;
keep code country mthyr portyear ret ret_us RD EMP MC COG_US SGA_US p_us_updated;
proc sort; by portyear;
run;
*/

data final; set nnnDS.agret0;
COG = COGS;
run;
%abbr_country(final);

data agret0; set final;;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if country in ("BD", "CN", "FR", "IT", "JP", "UK", "US");
*if country in ("BD", "BG", "CN", "FR", "IT", "JP", "NL", "SD", "SW","UK", "US");
*if country in ("AU", "BD", "CN", "FN", "FR", "HK", "IS", 
"IT", "JP", "KO", "SD", "SG", "SW", "TA", "UK", "US");
if RD>0;
if MC>0;
keep code country mthyr portyear ret ret_us RD EMP MC COG SGA p_us_updated;
proc sort; by portyear;
run;

proc sql;
	create table agret0 as
	select a.*, b.cogs as cog2, b.ni, b.nius, a.cog-b.cogs as diff, b.nius/b.ni as fx, a.cog*b.nius/b.ni as cog_us, a.sga*b.nius/b.ni as sga_us, coalesce(b.cogs,a.cog) as cog, 
coalesce(b.emp,a.emp) as emp, b.ta as ta, b.ta*b.nius/b.ni as ta_us
	from agret0 as a
	left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;



%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

*%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1, cog_us, sga_us);

%winsor(dsetin=agret1, dsetout=agret1, byvar=portyear country, vars=lagmv_us, type=winsor, pctl=1 99);


data agret2; set agret1;
*if lagcog_us>0;
world="world";
proc sort;by portyear;
run;


proc univariate data=agret2 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret3; merge agret2 price;
by portyear;
if p_us_updated>=p_us_10;
proc sort; by code portyear;
run;




dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190304\top33";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set agret3;
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
*if signal1~=. and EMP2~=.;
*if signal1~=.;
*if EMP2~=.;
run;

%zEMP(test, world, portyear, EMP2, 1);

proc sort data=zscore; by world mthyr;
proc univariate data=zscore noprint;
by world mthyr;
var zEMP;
*output out=prt q1=q1 q3=q3;
output out=prt pctlpts=33 67 pctlpre=p;
run;
data zscore; merge zscore prt;
by world mthyr;
if zEMP>=p67;
run;

%zRD(zscore, world, portyear, signal1, signal2, signal3, RD);


%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, zRD);
data pwd.world_vw_sprd; set sprd; run;



%zRD(agret3, globe, portyear, rhs, rhs2, rhs3, RD);
%onewayeffect(zscore, ret_us, globe, lagmv_us, world_vw, zRD);
%onewayeffect(zscore, ret_us, globe, lagmv_us, world_vw, z1);
%onewayeffect(zscore, ret_us, globe, lagmv_us, world_vw, z2);
%onewayeffect(zscore, ret_us, globe, lagmv_us, world_vw, z3);
