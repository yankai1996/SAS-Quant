
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
portyear=year(date)+1;
if month(date)<7 then portyear=portyear-1;
ret=ri_lc/lag(ri_lc)-1;
if first.dscd then ret=.;
run;


data ag19; set nnnDS.agret0;
keep code country portyear;
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


data code_country; set ag19;
keep code country;
proc sort nodup; by code;
run;

data mvdec; merge nnnDS.mvdec(in=a) code_country(in=b);
by code;
if a & b;
keep code country portyear mv;
run;


/*************** IRISK ******************/

data test; set all_lc;
code=dscd;
keep code portyear country date ret;
if ret~=.;
proc sort; by code portyear;
run;

data test; merge test(in=a) mvdec(in=b);
by code portyear;
if a & b;
if mv~=.;
proc sort; by country date;
run;


proc means data=test noprint; by country date;
var ret;
weight mv; 
output out=vwmktret mean=vwmktret;
run;


data test; merge test vwmktret;
by country date;
if ret~=. & vwmktret~=.;
keep code country portyear ret vwmktret;
proc sort; by code portyear;
run;

proc reg data=test noprint;
model ret=vwmktret;
by code portyear country;
output out=residual r=residual;
run;

proc means data=residual noprint;
by code portyear country;
var residual;
output out=irisk std=irisk;
run;

data daily.irisk_company; set irisk; 
label irisk=" ";
keep code country portyear irisk;
run;


data irisk2; merge irisk(in=a) mvdec(in=b);
by code portyear;
if a & b;
if mv~=.;
keep code country portyear irisk mv;
proc sort; by country portyear;
run;

proc means data=irisk2 noprint;
by country portyear;
var irisk;
weight mv;
output out=irisk2 mean=irisk;
run;

data irisk3; set daily.ctychar_20160918;
country=upcase(COUNTRY_);
keep country portyear r2;
run;
proc sql;
	create table irisk3 as
	select b.country as country, a.*
	from irisk3 as a
	left join db.ctycode as b on a.country=b.cty;
quit;
data irisk3; set irisk3;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;

data iriskUKUS; set daily.ctychar_20160918;
country=upcase(COUNTRY_);
keep country portyear r2;
if country in ("UK", "US");
run; 

data irisk3; set irisk3 iriskUKUS;
proc sort; by country portyear;
run;

data irisk4; merge irisk2 irisk3;
by country portyear;
irisk_new=irisk;
irisk_old=r2;
irisk=coalesce(irisk_new, irisk_old);
label irisk=" ";
run;

data daily.irisk_country; set irisk4;
keep country portyear irisk:;
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

data dvoly; merge dvoly(in=a) mvdec(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
run;

proc means data=dvoly noprint; by country portyear;
var dvoly;
weight mv; 
output out=dvol mean=dvol;
run;

data MC; set ag19;
proc sort; by country portyear;
proc means noprint; by country portyear;
var MC;
output out=MC sum=MC_sum;
run;


data MC; set mvdec;
proc sort; by country portyear;
proc means noprint; by country portyear;
var mv;
output out=MC sum=MC_sum;
run;

data dvol; merge dvol(in=a) MC(in=b);
by country portyear;
if a & b;
dvol=dvol/MC_sum;
keep country portyear dvol;
run;

data daily.dvol; set dvol;
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

data be4; set nnnDS.agret0;
pf=pref;
dit=tax;
cm=ce;
eq=se;
keep code year pf dit eq cm ta tl MC portyear;
proc sort nodup; by code year;
run;

data be4; set be4;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = coalesce(be1, be2, be3);
if be4~=. & MC~=.;
keep country code portyear be4 MC;
proc sort; by code portyear;
run;


data ivol; merge daily.irisk_company(in=a) be4(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
proc rank data=ivol group=3 out=rank;
var irisk; by country portyear; ranks r;
run;

proc sort; by code portyear;
data rank; set rank;
by code portyear;
r=r+1;
r1=lag(r);
r2=lag2(r);
r3=lag3(r);
r4=lag4(r);
r5=lag5(r);
r=coalesce(r,r1,r2,r3,r4,r5);
run;


proc sort; by portyear country r;
proc means data=rank noprint; by portyear country r;
var mc be4;
output out=rhs1 mean=sum_mc sum_be4;
run;

data rhs1; set rhs1;
pb=sum_MC/sum_be4;
keep country portyear r pb;
run;

data bot; set rhs1; if r in (1); bot1=rhs; bot2=pb; keep country portyear bot1 bot2; proc sort; by country portyear;
data top; set rhs1; if r in (3); top1=rhs; top2=pb; keep country portyear top1 top2; proc sort; by country portyear;

data pbsprd; merge bot top;
by country portyear;
pbsprd = log(top2/bot2);
keep country portyear pbsprd;
run;

data daily.pbsprd; set pbsprd; run;





