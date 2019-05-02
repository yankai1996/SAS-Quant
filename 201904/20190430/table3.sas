
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";

data agret0; set nnnDS.agret0; 
keep country code mthyr portyear ret ret_us RD MC p_us_updated;
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
if mthyr<201807;;
proc sort; by code mthyr;
run;

data agret1; set agret0;
by code;
lagret_us = lag(ret_us);
if first.code then lagret_us=.;
if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10; 
if ret_us~=.;
if RD>0 & MC>0;
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


/* scale within a country */
proc sort data=agret1;
by country mthyr;
run;
proc means data=agret1 noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret1(in=a) meanmv(in=b);
by country mthyr;
if a and b;
ew = 1;
mvport = mvbar/lagmv_us;
if rhs~=.;
if rhs>0;
portyear_old = portyear;
portyear = mthyr;
/* if myroe>-10 and myroe<10;  */
/* if portyear_old>1985; */
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>15;
world="world";
run;


%let pwd = "C:\TEMP\displace\20190430";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


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
	outfile= "C:\TEMP\displace\20190430\&output..csv"
    dbms=csv replace;
run;

%mend outtable3;

%outtable2(world_ew, table3_ew);
%outtable2(world_vw, table3_vw);



