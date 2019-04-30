
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";

data agret0; set nnnDS.agret0; 
keep country code portyear mthyr ret ret_us RD MC;
run;
proc sql;
	create table agret0 as
	select b.country as country_short, a.*
	from agret0 as a
	left join db.ctycode as b on a.country=b.cty;
quit;
data agret0; set agret0;
if country_short in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
country=Propcase(country);
if country_short="UK" then country="U.K.";
if country_short="US" then country="U.S.";
if mthyr<201807;
if ret>-1 and ret<=10;
run;


proc sql;
create table agret0 as
select * from agret0
group by code, portyear
having count(mthyr)>=6;
quit;



/* ==================================== */
/*--- TABLE 1: RD median and std dev ---*/
/* ==================================== */

/* Start and End Date*/

proc sort; by country;
proc means noprint; by country;
var mthyr;
output out=date;
run;

data date; set date;
if _stat_ in ("MIN", "MAX");
proc transpose data=date out=date;
by country;
var mthyr;
id _stat_;
run;

data date; retain country min max; set date;
keep country min max;
run;


/* Then merge with MvDec*/

proc sort data=agret0; by code portyear; run;
data agret1; merge agret0(in=a) nnnDS.mvdec(in=b);
by code portyear;
if a & b;
rhs=RD/MC;
keep code country portyear mv_us rhs;
proc sort nodup; by code portyear;
run;



/* annual summaries of No obs*/

proc sort data=agret1; by country;
proc means data=agret1 noprint; by country;
var portyear; output out=firmyear_obs n=n1;
run;
data firmyear_obs; set firmyear_obs;
keep country n1;
run;


/* annual summaries of No firms*/
proc sort data=agret1; by country portyear; run;
proc means noprint; by country portyear;
var portyear; output out=tem3 n=n1;
run;
proc means data=tem3 noprint; by country;
var n1; output out=firm_year mean=n2;
run;
data firm_year; set firm_year;
keep country n2;
run;


/* annual (Dec) total market value in USD */
proc means data=agret1 noprint; by country portyear;
var mv_us; output out=mv_us sum=mv_us;
run;
proc means data=mv_us noprint; by country;
var mv_us; output out=mv_us mean=mv_us;
run;
data mv_us; set mv_us;
keep country mv_us;
run;





data agret2; set agret1;
if rhs~=. & rhs>0; 
run;
%winsor(dsetin=agret2, dsetout=agret3, byvar=country, vars=rhs, type=winsor, pctl=1 99);
proc sort data=agret3; by country;
run;
proc means data=agret3 noprint; by country;
var rhs; output out=tem8 mean=moyen std=sigma n=n1;
run;
data tem8; set tem8;
keep country moyen sigma;
run;

%winsor(dsetin=agret2, dsetout=agret4, byvar=portyear, vars=rhs, type=winsor, pctl=1 99);
proc means data=agret4 noprint;
var rhs; output out=tem81 mean=moyen std=sigma n=n1;
run;
data tem81; set tem81;
country="All";
keep country moyen sigma;
run;

data agret5; set agret4;
if country~="U.S.";
proc means data=agret5 noprint;
var rhs; output out=tem82 mean=moyen std=sigma n=n1;
run;
data tem82; set tem82;
country="All excluding U.S.";
keep country moyen sigma;
run;
data tem8; set tem8 tem81 tem82; 
proc sort; by country;
run;


/* output excel */

data table1; merge date firmyear_obs firm_year mv_us tem8;
by country;
run;

proc export data= table1
	outfile= "C:\TEMP\displace\20190429\table1.csv"
    dbms=csv replace;
run;
