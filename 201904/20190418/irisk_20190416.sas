
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
run;


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


/*************** IRISK ******************/

data test; set all_lc;
code=dscd;
keep code portyear date ret;
if ret~=.;
proc sort; by code portyear;
run;

data test; merge test(in=a) ag19(in=b);
by code portyear;
if a & b;
if MC~=.;
proc sort; by country date;
run;

data test; set test;
if MC~=.;
run;

proc means data=test noprint; by country date;
var ret;
weight MC; 
output out=vwmktret mean=vwmktret;
run;


data test; merge test vwmktret;
by country date;
if ret~=. & vwmktret~=.;
keep code portyear ret vwmktret;
proc sort; by code portyear;
run;

proc reg data=test noprint;
model ret=vwmktret;
by code portyear;
output out=residual r=residual;
run;

proc means data=residual noprint;
by code portyear;
var residual;
output out=irisk std=irisk;
run;


data daily.irisk; retain code; set irisk; 
label irisk=" ";
keep code portyear irisk;
run;


data irisk2; merge irisk(in=a) ag19(in=b);
by code portyear;
if a & b;
if MC~=.;
proc sort; by country portyear;
run;

proc means data=irisk2 noprint;
by country portyear;
var irisk;
weight MC;
output out=irisk2 mean=irisk;
run;

data daily.irisk_country; set irisk2;
keep country portyear irisk;
run;


/*************** DVOL ******************/

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

data MC; set ag19;
proc sort; by country portyear;
proc means noprint; by country portyear;
var MC;
output out=MC sum=MC_sum;
run;

data dvol; merge dvol(in=a) MC(in=b);
by country portyear;
if a & b;
keep country portyear dvol MC_sum;
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



/*************** NIPO ******************/

data ag; set nnnDS.agret0;
proc sort; by code portyear;
run;

data nipo; set ag;
count + 1;
by code portyear;
if first.code then count = 1;
if count=1;
keep code portyear country count;
proc sort; by country portyear;
run;

proc means data=nipo noprint; 
by country portyear;
var count; 
output out=nipoout sum=countsum;
run;

proc sql;
  create table snipo as
   select a.country, a.portyear, b.countsum, b.countsum/count(a.code) as snipo, count(a.code) as totalno
	from ag as a
	left join nipoout as b
	on a.country=b.country and a.portyear=b.portyear
	group by a.portyear, a.country;
quit;

data snipo; set snipo;
if snipo=. then snipo=0;
proc sort nodup; by portyear country;
run;

proc sql;
	create table snipo as
	select b.country as country, a.*
	from snipo as a
	left join db.ctycode as b on a.country=b.cty;
quit;

data daily.snipo; set snipo;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
proc sort; by country portyear;
run;



/*************** PVOL ******************/
