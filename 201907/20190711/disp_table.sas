
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


data agret0; set nnnds.agret0; 
keep keep country code mthyr portyear ret ret_us RD MC p_us_updated COGS EMP;
run;
proc sql;
	create table agret0 as
	select b.country as country, a.*
	from agret0 as a
	left join db.ctycode as b on a.country=b.cty;
quit;
data agret0; set agret0;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
proc sort; by code portyear;
run;


proc sql;
	create table acct as
	select distinct code, portyear, COGS, EMP
	from agret0;

	create table acct as
	select a.*, b.COGS as lagCOGS, b.EMP as lagEMP
	from acct as a left join acct as b
	on a.code=b.code and a.portyear=b.portyear+1;
quit;


data agret0; merge agret0 acct;
by code portyear;
rhs=abs(EMP-lagEMP)/lagCOGS;
proc sort; by country;
proc means noprint; by country;
var rhs;
output out=country median=median std=std;
run;

proc means noprint data=agret0;
var rhs;
output out=all median=median std=std;
run;

data xUS; set agret0;
if country="US" then delete;
proc means noprint;
var rhs;
output out=xUS median=median std=std;
run;

data all; set all;
country="All";
run;
data xUS; set xUS;
country="xUS";
run;
data table1; set country xUS all; 
run;



/*** Table 2 ***/

proc sort data=agret0 out=agret1; by code mthyr; run;
data agret1; set agret1;
by code;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10; 
if ret_us~=.;
if RD>0 & MC>0;
rhs2=rhs;
rhs=RD/MC;
proc sort; by portyear;
run;


proc univariate data=agret1 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret1; merge agret1 price;
by portyear;
if p_us_updated>=p_us_10;
proc sort; by code portyear;
run;


data mvdec; set nnnDS.mvdec;
portyear = year+1;
lagmv_us = mv_us;
keep code portyear lagmv_us;
proc sort; by code portyear;
run;

data agret1; merge agret1(in=a) mvdec(in=b);
by code portyear;
if a & b;
run;

%winsor(dsetin=agret1, dsetout=agret1, byvar=portyear country, vars=lagmv_us RD MC, type=winsor, pctl=1 99);



proc sort data=agret1; by mthyr;
proc univariate data=agret1 noprint;
by mthyr;
var rhs2;
output out=prt pctlpts=33 67 pctlpre=pctl;
run;
data agret1; merge agret1 prt;
by mthyr;
run;


data agret2; set agret1;
if rhs2>=pctl67 and rhs2~=.;
run;

/* scale within a country */
proc sort data=agret2;
by country mthyr;
run;
proc means data=agret2 noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret2(in=a) meanmv(in=b);
by country mthyr;
if a and b;
ew = 1;
mvport = mvbar/lagmv_us;
if rhs~=.;
if rhs>0;
portyear_old = portyear;
portyear = mthyr;
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>15;
world="world";
run;




%let pwd = "C:\TEMP\displace\20190710";
*x md &pwd;
x cd &pwd;
libname pwd &pwd;

%mth_port_analysis_short();




%macro transpose(input, output);

proc transpose data=&input out=&output;
var estimate tvalue;
by rank;
run;
data &output; set &output;
if _name_="Estimate" then col1=col1*100;
&output=col1;
drop _LABEL_ col:;
run;

%mend transpose;

%transpose(final51, global_ew);
%transpose(final52, global_vw);
%transpose(final211, country_neutral_ew);
%transpose(final213, country_neutral_xUS_ew);
%transpose(final221, country_neutral_vw);
%transpose(final223, country_neutral_xUS_vw);


data table2; merge global_: country_:;
by rank _name_;
run;

data pwd.table2; set table2; run;

proc export data= table2
	outfile= "C:\TEMP\displace\20190710\table2.csv"
    dbms=csv replace;
run;




/*** Table 3 ***/


%twowaysprd(tem, 50, 10000000, 5, 5, lagmv_us, rhs, ret_us, equal, world, world, portyear, world_ew);

data sum_diff4; set sum_diff3;
if rank_var2=99 and rank_var1<5;
run;
proc model data=sum_diff4;
*by _name_ rank_var1 rank_var2;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=pwd.param_ew;
quit;



%twowaysprd(tem, 50, 10000000, 5, 5, lagmv_us, rhs, ret_us, lagmv_us, world, world, portyear, world_vw);

data sum_diff4; set sum_diff3;
if rank_var2=99 and rank_var1<5;
run;
proc model data=sum_diff4;
*by _name_ rank_var1 rank_var2;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=pwd.param_vw;
quit;



%macro outtable3(input, output);

data &output; set &input;
by rank_var1;
if first.rank_var1 then do;
	_0=_0*100;
	_1=_1*100;
	_2=_2*100;
	_3=_3*100;
	_4=_4*100;
	_99=input(_99, 8.)*100;
end;
drop world;
run;

data pwd.&output; set &output; run;

proc export data=&output
	outfile= "C:\TEMP\displace\20190710\&output..csv"
    dbms=csv replace;
run;

%mend outtable3;

%outtable3(world_ew, table3_ew);
%outtable3(world_vw, table3_vw);
