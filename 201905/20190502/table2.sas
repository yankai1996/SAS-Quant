
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
run;



%let pwd = "C:\TEMP\displace\20190430";
x md &pwd;
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


data table2; merge global: country:;
by rank _name_;
run;

data pwd.table2; set table2; run;

proc export data= table2
	outfile= "C:\TEMP\displace\20190430\table2.csv"
    dbms=csv replace;
run;
