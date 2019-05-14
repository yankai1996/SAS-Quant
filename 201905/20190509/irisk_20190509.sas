
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";
libname us "V:\data_for_kai\Compustat&CRSP merged";

libname daily "T:\SASData3";

data all_lc; set daily.all_lc;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
*if price_lc~=. & ri_lc~=. & tdvol~=.;
proc sort; by dscd;
run;
data all_lc; set all_lc;
by dscd;
portyear=year(date)+1;
if month(date)<7 then portyear=portyear-1;
ret=ri_lc/lag(ri_lc)-1;
if first.dscd then ret=.;
run;

data us; retain code; set daily.us;
portyear=year(date)+1;
if month(date)<7 then portyear=portyear-1;
code=permno;
ret=retx;
tdvol=vol;
price=abs(PRC);
keep code date portyear ret tdvol price;
proc sort; by code;
run;


data mvdec; set nnnDS.mvdec; 
proc sort; by code portyear;
run;

data mvdec_us; set us.mvdec;
proc sort; by code portyear;
run;


proc import out=vwmktret_us
	file="C:\TEMP\displace\20190509\F-F_Research_Data_Factors_daily.CSV"
	dbms=csv replace;
getnames=yes;
run;
data vwmktret_us; set vwmktret_us;
if 19800700<datenum<20180700;
vwmktret=mkt_rf/100;
DATE = Input( Put( DATENUM, 8.), Yymmdd8.);
format date Date9.;
keep date vwmktret;
proc sort; by date;
run;


/*************** IRISK xUS ******************/

data test_xus; set all_lc;
code=dscd;
keep code portyear country date ret;
if ret~=.;
proc sort; by code portyear;
run;

data test_xus; merge test_xus(in=a) mvdec(in=b);
by code portyear;
if a & b;
if mv~=.;
proc sort; by country date;
run;

proc means data=test_xus noprint; by country date;
var ret;
weight mv; 
output out=vwmktret_xus mean=vwmktret;
run;

data test_xus; merge test_xus vwmktret_xus;
by country date;
keep code country portyear ret vwmktret;
proc sort; by code portyear;
run;

proc reg data=test_xus noprint;
model ret=vwmktret;
by code portyear country;
output out=residual_xus r=residual;
run;

proc means data=residual_xus noprint;
by code portyear country;
var residual;
output out=irisk_xus_company std=irisk;
run;

data daily.irisk_xus_company; set irisk_xus_company; 
label irisk=" ";
keep code country portyear irisk;
run;



data irisk2; merge irisk_xus_company(in=a) mvdec(in=b);
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

data daily.irisk_xus; set irisk2;
label irisk=" ";
keep country portyear irisk;
run;


/**************** IRISK US ************************/

data test_us; set us;
country="US";
keep code portyear country date ret;
if ret~=.;
if portyear<=2018;
proc sort; by date;
run;

data test_us; merge test_us vwmktret_us;
by date;
keep code country portyear ret vwmktret;
proc sort; by code portyear;
run;

proc reg data=test_us noprint;
model ret=vwmktret;
by code portyear;
output out=residual_us r=residual;
run;

proc means data=residual_us noprint;
by code portyear country;
var residual;
output out=irisk_us_company std=irisk;
run;

data daily.irisk_us_company; set irisk_us_company; 
label irisk=" ";
keep code country portyear irisk;
run;


data irisk_us; merge irisk_us_company(in=a) mvdec_us(in=b);
by code portyear;
if a & b;
if mv~=.;
keep code country portyear irisk mv;
proc sort; by country portyear;
run;

proc means data=irisk_us noprint;
by country portyear;
var irisk;
weight mv;
output out=irisk_us mean=irisk;
run;

data daily.irisk_us; set irisk_us;
label irisk=" ";
keep country portyear irisk;
run;



data olddata; set daily.ctychar_20160918;
country=upcase(COUNTRY_);
keep country portyear r2 IVOL DVOL;
run;
proc sql;
	create table olddata as
	select b.country as country, a.*
	from olddata as a
	left join db.ctycode as b on a.country=b.cty;
quit;
data olddata; set olddata;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK");
run;

data olddata2; set daily.ctychar_20160918;
country=upcase(COUNTRY_);
keep country portyear r2 IVOL DVOL;
if country in ("UK", "US");
run; 

data olddata; set olddata olddata2;
proc sort; by country portyear;
run;



data irisk; set daily.irisk_xus daily.irisk_us;
irisk_new=irisk;
keep country portyear irisk_new;
run;
data irisk; merge irisk olddata;
by country portyear;
irisk_old=r2;
irisk=coalesce(irisk_new, irisk_old);
keep country portyear irisk:;
run;
data daily.irisk; set irisk; run;


/*************** DVOL xUS ******************/

data dvold_xus; set all_lc;
dvold=tdvol*price_lc;
if dvold~=.;
code=dscd;
month=month(date);
keep code country dvold portyear date month;
proc sort; by code portyear month;
run;


proc means data=dvold_xus noprint;
var dvold;
by code portyear month country;
output out=dvolm_xus sum=dvolm;
run;

proc means data=dvolm_xus noprint;
var dvolm;
by code portyear country;
output out=dvoly_xus sum=dvoly;
run;

data dvoly_xus; set dvoly_xus;
if _freq_=12;
drop _type_ _freq_;
run;

data dvoly_xus; merge dvoly_xus(in=a) mvdec(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
run;

proc means data=dvoly_xus noprint; by country portyear;
var dvoly;
weight mv; 
output out=dvol_xus mean=dvol;
run;

proc means data=dvoly_xus noprint; by country portyear;
var mv;
output out=MC_xus sum=MC_sum;
run;

data dvol_xus; merge dvol_xus MC_xus;
by country portyear;
dvol=dvol/MC_sum;
keep country portyear dvol;
run;


/*************** DVOL US ******************/

data dvold_us; set us;
dvold=tdvol*price/1000;
if dvold~=.;
month=month(date);
keep code country dvold portyear date month;
proc sort; by code portyear month;
run;

proc means data=dvold_us noprint;
var dvold;
by code portyear month;
output out=dvolm_us sum=dvolm;
run;

proc means data=dvolm_us noprint;
var dvolm;
by code portyear;
output out=dvoly_us sum=dvoly;
run;

data dvoly_us; set dvoly_us;
if _freq_=12;
drop _type_ _freq_;
run;

data dvoly_us; merge dvoly_us(in=a) mvdec_us(in=b);
by code portyear;
if a & b;
proc sort; by portyear;
run;

proc means data=dvoly_us noprint; by portyear;
var dvoly;
weight mv; 
output out=dvol_us mean=dvol;
run;

proc means data=dvoly_us noprint; by portyear;
var mv;
output out=MC_us sum=MC_sum;
run;

data dvol_us; merge dvol_us MC_us;
by portyear;
dvol=dvol/MC_sum;
country="US";
keep country portyear dvol;
run;



data dvol; set dvol_xus dvol_us; run; 

data dvol; merge olddata(rename=(dvol=dvol_old)) dvol(rename=(dvol=dvol_new));
by country portyear;
dvol=coalesce(dvol_new, dvol_old);
keep country portyear dvol:;
run;

data daily.dvol; set dvol; run;


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


/*************** PVOL xUS ******************/

data be4_xus; set nnnDS.agret0;
pf=pref;
dit=tax;
cm=ce;
eq=se;
keep code year pf dit eq cm ta tl MC portyear;
proc sort nodup; by code portyear;
run;

data be4_xus; set be4_xus;
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


data ivol_xus; merge daily.irisk_xus_company(in=a) be4_xus(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
proc rank group=3 out=rank;
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

data pbsprd_xus; merge bot top;
by country portyear;
pbsprd = log(top2/bot2);
keep country portyear pbsprd;
run;

/*data daily.pbsprd_xus; set pbsprd_xus; run;
*/



/*************** PVOL US ******************/

data be4_us; set us.agret0;
pf=pstk;
dit=txditc;
cm=ceq;
eq=seq;
ta=at;
tl=lt;
keep code year pf dit eq cm ta tl MC portyear;
proc sort nodup; by code portyear;
run;

data be4_us; set be4_us;
if pf=. then pf=0;
if dit=. then dit=0;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = coalesce(be1, be2, be3);
if be4~=. & MC~=.;
keep country code portyear be4 MC;
run;


data ivol_us; merge daily.irisk_us_company(in=a) be4_us(in=b);
by code portyear;
if a & b;
proc sort; by country portyear;
proc rank group=3 out=rank;
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

data pbsprd_us; merge bot top;
by country portyear;
pbsprd = log(top2/bot2);
keep country portyear pbsprd;
run;



data pbsprd; set pbsprd_xus pbsprd_us; 
pbsprd_new=pbsprd;
keep country portyear pbsprd_new;
run;

proc import out=pbsprd_old
	file="T:\SASData3\nipoivol_20160608.csv"
	dbms=csv replace;
getnames=yes;
run;
data pbsprd_old; set pbsprd_old;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
pbsprd_old=pbsprd;
keep country portyear pbsprd_old;
run;

data pbsprd; merge pbsprd_old pbsprd;
by country portyear;
pbsprd=coalesce(pbsprd_new, pbsprd_old);
run;



proc import out=ctychar_20160918
	file="T:\SASData3\ctychar_20160918.csv"
	dbms=csv replace;
getnames=yes;
run;
