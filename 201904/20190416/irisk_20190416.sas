
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";

libname daily "T:\SASData3";

data all_lc; set daily.all_lc;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
if price_lc~=. & ri_lc~=. & tdvol~=.;
proc sort; by dscd;
run;
data all_lc; set all_lc;
by dscd;
portyear=year(date);
if month(date)<7 then portyear=portyear-1;
ret=ri_lc/lag(ri_lc)-1;
if first.dscd then ret=.;
proc sort; by country date;
run;


/*************** IRISK ******************/

proc means data=all_lc noprint; by country date;
var ret;
weight tdvol; 
output out=vwmktret mean=vwmktret;
run;


data test; merge all_lc vwmktret;
by country date;
if ret~=. & vwmktret~=.;
keep dscd portyear ret vwmktret;
proc sort; by dscd portyear;
run;

proc reg data=test noprint;
model ret=vwmktret;
by dscd portyear;
output out=residual r=residual;
run;

proc means data=residual noprint;
by dscd portyear;
var residual;
output out=irisk std=irisk;
run;


data daily.irisk; retain code; set irisk; 
code=dscd;
label irisk=" ";
keep code portyear irisk;
run;




/*************** DVOL ******************/

data ag19; set nnnDS.agret0;
portyear=year+1;
keep code country portyear mc;
proc sort nodup; by code portyear;
run;
proc sql;
	create table ag19 as
	select b.country as country, a.*
	from ag19 as a
	left join db.ctycode as b on a.country=b.cty;
quit;
data ag19; set ag19;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
proc sort; by code portyear;
run;

data dvold; set all_lc;
dvold=tdvol*price_lc;
code=dscd;
keep code dvold portyear date;
proc sort; by code portyear;
run;
data dvold; set dvold;
month=month(date);
proc sort; by code portyear month;
run;


proc means data=dvold noprint;
var dvold;
by code portyear month;
output out=dvolm sum=dvolm;
run;

proc means data=dvolm noprint;
var dvolm;
by code portyear;
output out=dvoly sum=dvoly;
run;

data dvoly; set dvoly;
if _freq_=12;
drop _type_ _freq_;
run;

data dvoly; merge dvoly(in=a) ag19(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
run;

proc means data=dvoly noprint; by country portyear;
var dvoly;
weight mc; 
output out=dvol mean=dvol;
run;

data daily.dvol; set dvol;
drop _type_ _freq_;
run; 



/*************** SHORT ******************/

proc import out=short
	file="Y:\Desktop\short.xlsx" 
	dbms=excel replace;
sheet="sheet1";
getnames=yes;
run;
data daily.short; set short;
keep country portyear short;
run;
