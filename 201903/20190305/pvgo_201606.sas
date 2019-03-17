
options noxwait;
x 'o:\projects';
libname roadeco "o:\projects\roadeco";

libname deco "o:\projects\retdeco";
x 'cd o:\projects\AG';
libname intag '201111';
libname mois '201111\monthly\02_exfin';
libname annee '201111\yearly\02_exfin';
libname ipp 'o:\projects\ipp';
libname jour 'o:\projects\AG\af79\200909\02_exfin';

libname innopoli "o:\projects\innopoli";


x 'cd o:\projects\ipp';
%include 'winsor.sas';



option notes;
/* 
proc sql;
  create table ag00 as
   select 
          case when a.year=2008 then coalesce(a.mc, b.mc) else a.mc end as mc, 
			case when a.year=2008 then coalesce(a.cm, b.cm) else a.cm end as cm, 
			case when a.year=2008 then coalesce(a.ta, b.ta) else a.ta end as ta,
			case when a.year=2008 then coalesce(a.tl, b.tl) else a.tl end as tl,
			case when a.year=2008 then coalesce(a.eq, b.eq) else a.eq end as eq,
			case when a.year=2008 then coalesce(a.pf, b.pf) else a.pf end as pf, a.*, b.opm, b.dda, b.cog, b.dit, b.sga, b.cl, d.ocf
          from annee.allannual as a
		  left join roadeco.annual2014 as b on a.code=b.dscd and a.year=b.year
		  /*left join ipp.ltlps as c on a.code=c.code and a.year=c.year*
		  left join ipp.ocf as d on a.code=d.code and a.year=d.year;
quit;


option notes;

proc import out=ipp.eps2016 datafile="o:\projects\ipp\eps.dta";  run;  proc sort; by dscd year; run;
*/
proc sql;
  create table ag00 as
   select a.*, a.dscd as code, b.country, c.eps
          from roadeco.annual2014 as a
		  left join annee.allannual as b on a.dscd=b.code and a.year=b.year
		  left join ipp.eps2016 as c on a.dscd=c.dscd and a.year=c.year;
		/*where a.year>=2005;	*/
quit;





/* extract annual return to assign PVGO5 */
data logret3; set ipp.logret3;
year = round(mthyr,100)/100;
run;
proc sort; by code year;
proc means data=logret3 noprint; var drhat rm;
by code year;
output out=aret sum=drhat rm n=n1 n2;
run;
data annret; set aret;
estret1y=exp(drhat)-1;
calmkt1y=exp(rm)-1;
if year>=2010;
/*if n1 ge 11;
if year le 2010; /* this is to exclude 2009 requiring returns between 1/2011-6/2011 (not available)*/
keep code year estret1y calmkt1y;
proc sort; by code year;
run;


data logret; set ipp.logret;
year = year(date);
drop portyear;
run;
proc sort; by year code country;
proc means data=logret noprint; var ret ret_us;
by year code country;
output out=aret sum=ret ret_us n=n1 n2;
run;
proc sort data=mois.mvdec; by country year;
run;
data retannum; set aret;
calret1y=exp(ret)-1;
calret1y_us=exp(ret_us)-1;
if n1 ge 11;
if year ge 1981;
if calret1y<3;
if calret1y>-1;
keep code country year calret1y calret1y_us n1 n2;
proc sort; by country year;
run;
option notes;
data retannum; merge retannum(in=a) mois.mvdec(in=b);
by country year;
if a and b;
run;
/* --- try EW market return --------------*/
proc means data=retannum noprint; by country year;
var calret1y;
output out=meanretew mean=ewmktret;
run;
proc means data=meanretew noprint; by country;
var ewmktret; output out=meanret2 mean=ret1ybarew;
run;
/* --- try VW market return --------------*/
proc means data=retannum noprint; by country year;
var calret1y;
weight mv; 
output out=meanretvw mean=vwmktret;
run;
proc means data=meanretvw noprint; by country;
var vwmktret; output out=meanret3 mean=ret1ybarvw;
run;
/*---- try median -----*/
proc univariate data=retannum noprint;
by country year;
var calret1y;
output out=medianret median=mdmktret;
run;
proc means data=medianret noprint; by country;
var mdmktret; output out=medianret2 mean=ret1ybarbar;
run;








/************************************/
/* get next June MV */
/* to generate PB */
proc sql;
  create table ag19 as
   select a.*, b.p_updated, b.month, b.p_us_updated
          from ag00 as a
		  left join mois.prmonthly as b on a.code=b.code and a.year=b.year-1 and b.month=6;
quit;

proc sort data=ag19; by code year;

data ag20; set ag19;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
/* mc2=p_updated*sh; */
mc2 = p_updated*csh;
if country="UK" then mc2=p_updated*csh/100;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
/*ndltl =  ltlps*sh - dl;
if ctyid=2 then ndltl = ltlps*sh*1000 - dl;
goroe = ocf/lag(dli - dl);
goroe = ocf/lag(ndltl);
if ndltl<0 then goroe=.; 
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;	end;
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
proje = eroe*ndltl;
myltl= ltlps*sh;
if ctyid=2 then ndltl = ltlps*sh*1000;
ndltl = be4; ; */
ndltl = ta - cl - dvp;
goroe = ocf/lag(ndltl);
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;	end;
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
/* proje = eroe*(dli-dl);*/
proje = eroe*ndltl; 
if proje<-1 then proje=.; 
n_maba =  coalesce(ta - cm + mc2, ta-cm);
maba = (n_maba) / ta ;
n_q = mc2 + pf + cl - ca + dl;
tobinq = (n_q) / ta;
n_dte = (dc + dl + pf); 
dte =  n_dte / mc2;
capex = ce / k;
lev = (dc + dl) / (dl + mc2); 
diff = mc2/mc;
if diff>100 then do
n_maba=.;
n_q=.;
end;
mc3 = mc2; 
if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;
mebe1 = mc3/be1;
mebe2 = mc3/be2;
mebe3 = mc3/be3;
mebe4 = mc3/be4;
portyear=year+1;
mc_us = mc;
run; 

proc sort data=ag20; by country portyear;
proc univariate data=ag20 noprint;
by country portyear;
var mebe1;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;


/*============================================================================*/
/*           get country level aggregate accounting								
/*============================================================================*/



%winsor(dsetin=ag20, dsetout=ag21, byvar=country portyear, vars=dte maba tobinq capex pb mebe1 mebe2 mebe3 mebe4 proje eroe, type=winsor, pctl=2.5 97.5);
proc sort data=ag21; by country portyear;
proc means data=ag21 noprint; var dte maba tobinq capex pb mebe1 mebe2 mebe3 mebe4 proje eroe;
by country portyear;
output out=gobar20 std=dtebar mababar tobinqbar capexbar pbbar mebebar1 mebebar2 mebebar3 mebebar4 projebar eroebar;
run;



data mktpb; set gobar20;
if country=. then delete;
run;
/* next June *
proc export data= work.gobar22
            outfile= "o:\projects\ipp\ctychar_20150318.dta"
            dbms=dta replace;
run;








/************************************/
/* get next June MV */
/* to generate PVGO */
proc sql;
  create table ag19 as
   select a.*, b.p_updated, b.month, b.p_us_updated
          from ag00 as a
		  left join mois.prmonthly as b on a.code=b.code and a.year=b.year-1 and b.month=6;
quit;

proc sort data=ag19; by code year;
data ag20; set ag19;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
mc2=p_updated*csh;
if country="UK" then mc2=p_updated*csh/100;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
ndltl = ta - cl - dvp;
goroe = ocf/lag(ndltl);
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;	end;
n_maba =  coalesce(ta - cm + mc2, ta-cm);
n_q = mc2 + pf + cl - ca + dl;
tobinq = (n_q) / ta;
n_dte = (dc + dl + pf); 
dte =  n_dte / mc2;
capex = ce / k;
lev = (dc + dl) / (dl + mc2); 
diff = mc2/mc;
if diff>100 then do
n_maba=.;
n_q=.;
end;
maba = (n_maba) / ta ;
if maba>100 then maba=.;
mc3 = mc2; 
/*if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;
*/
mebe1 = mc3/be1;
mebe2 = mc3/be2;
mebe3 = mc3/be3;
mebe4 = mc3/be4;
portyear=year+1;
mc_us = mc;
pe = pb / roe *(eq + lag(eq))/2/eq*100;
earn = roe *(be4 + lag(be4))/2/100;
pe = mc3/earn;
if first.code then pe=.; 
if first.code then earn=.; 
/* if roe<0 then pe=.; */
if ndltl<0 then ndltl=.;
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
eroe = coalesce(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe,(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe)/.9,(0.4*l1goroe + 0.3*l2goroe)/.7,l1goroe);
/* proje = eroe*(dli-dl);
*/
if eroe<0 || eroe>1 then eroe=.;
proje = eroe*ndltl; 
if proje<-1 then proje=.; 
if proje<0 then proje=.;
ear2 = ear*csh;
run; 
/*
proc means data=ag20; var ndltl pe;
run;


proc sort data=ag20; by country portyear;
proc univariate data=ag20 noprint;
by country portyear;
var mebe1;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;
*/


proc sort data=ag20; by country year;
proc sort data=meanretew; by country year;
proc sort data=meanretvw; by country year;
proc sort data=medianret; by country year;

data ag20; merge ag20(in=a) meanretew(in=b) meanretvw(in=c) medianret(in=d);
by country year;
if a;
run;
proc sort data=ag20; by code year;
proc sort data=retannum; by code year;
data ag20; merge ag20(in=a) annret retannum;
by code year;
if a;
run;

data ag20; set ag20;
aip1 = proje/ewmktret;
pvgo1 = (mc3 - aip1) / mc3;
aip2 = proje/vwmktret;
pvgo2 = (mc3 - aip2) / mc3;
aip3 = proje/mdmktret;
pvgo3 = (mc3 - aip3) / mc3;
aip4 = proje/estret1y;
pvgo4 = (mc3 - aip4) / mc3;
aip5 = proje/calmkt1y;
pvgo5 = (mc3 - aip5) / mc3;
/*if pvgo4>3 or pvgo4<0 then delete;
if pvgo2>1 or pvgo2<0 then delete;
if pvgo3>1 or pvgo3<0 then delete;
if pvgo4>1 or pvgo4<0 then delete;
if pvgo5>1 or pvgo5<0 then delete;*/
run;




proc sort data=ag20; by country portyear;
proc univariate data=ag20 noprint;
by country portyear;
var pvgo2;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;


/*============================================================================*/
/*           get country level aggregate accounting								
/*============================================================================*/

data ag21; set ag20;
if pvgo2<10;
if pvgo2>-5;
keep country portyear pvgo1 pvgo2 pvgo3 pvgo4 pvgo5;
run;

%winsor(dsetin=ag21, dsetout=ag22, byvar=country portyear, vars=maba pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 mebe1 mebe2 mebe3 mebe4 proje eroe, type=delete, pctl=20 80);


%winsor(dsetin=ag20, dsetout=ag22, byvar=country portyear, vars=maba pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 mebe1 mebe2 mebe3 mebe4 proje eroe, type=delete, pctl=20 80);

proc sort data=ag22; by country portyear;
proc means data=ag22 noprint; var maba tobinq capex pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 mebe1 mebe2 mebe3 mebe4 proje eroe;
by country portyear;
output out=gobar20 std=mababar tobinqbar capexbar pvgobar1 pvgobar2 pvgobar3 pvgobar4 pvgobar5 mebebar1 mebebar2 mebebar3 mebebar4 projebar eroebar pebar;
run;



data gobar21; set gobar20;
if country="" then delete;
run;
/* proc sort; by country portyear; */
proc export data= work.gobar21
            outfile= "o:\projects\ipp\ctychar_20160518.dta"
            dbms=dta replace;
run;








proc sql;
  create table gobar2out2 as
   select a.*, b.*
          from gobar2out as a
		  left join mktpb as b on a.country=b.country and a.portyear=b.portyear;
quit;
proc means; var mktpb: pvgo:;
run;
/*
proc export data= work.gobar2out2
            outfile= "o:\projects\ipp\ctychar_20150328.dta"
            dbms=dta replace;
run;
*/

data gobar2out2; set gobar2out2;
if portyear>2008;
proc export data= work.gobar2out2
            outfile= "o:\projects\ipp\ctychar_20160322.dta"
            dbms=dta replace;
run;
/*  then paste back 20150328 after 
use ctychar_20150328, clear
drop if portyear >2008 
append using ctychar_20160322
sort country portyear
save ctychar_20160322, replace
*/








/* find out the last day of daily return downloaded
%macro lastday(cty);
proc sql;
	create table jour.last_&cty as
    select code, max(date) as lastday format=yymmdd8.
	from jour.ini_d_&cty
	having date=lastday;
quit;
%mend;
/* better way  */
data jour.lastday;
%macro lastday(cty);
proc sql;
	create table temp as
    select max(date) as lastday format=yymmdd8.
	from jour.ini_d_&cty
	having date=lastday;
quit;
data temp; set temp;
cty = "&cty";
proc sort nodup; by lastday;
data jour.lastday; set jour.lastday temp;
run;
%mend;
%lastday(AR_exfin);
%lastday(BR_exfin);
%lastday(CL_exfin);
%lastday(CB_exfin);
%lastday(MX_exfin);
%lastday(PE_exfin);
%lastday(VE_exfin);
%lastday(KN_exfin);
%lastday(MO_exfin);
%lastday(SA_exfin);
%lastday(RH_exfin);
%lastday(EY_exfin);
%lastday(IS_exfin);
%lastday(CP_exfin);
%lastday(CZ_exfin);
%lastday(GR_exfin);
%lastday(HN_exfin);
%lastday(PO_exfin);
%lastday(PT_exfin);
%lastday(TK_exfin);
%lastday(BN_exfin);
%lastday(CH_exfin);
%lastday(IN_exfin);
%lastday(ID_exfin);
%lastday(MY_exfin);
%lastday(PK_exfin);
%lastday(PH_exfin);
%lastday(KO_exfin);
%lastday(CY_exfin);
%lastday(TA_exfin);
%lastday(TH_exfin);
%lastday(AU_exfin);
%lastday(NZ_exfin);
%lastday(CN_exfin);
%lastday(US_exfin);
%lastday(HK_exfin);
%lastday(JP_exfin);
%lastday(SG_exfin);
%lastday(OE_exfin);
%lastday(BG_exfin);
%lastday(DK_exfin);
%lastday(FN_exfin);
%lastday(FR_exfin);
%lastday(BD_exfin);
%lastday(IR_exfin);
%lastday(IT_exfin);
%lastday(LX_exfin);
%lastday(NL_exfin);
%lastday(NW_exfin);
%lastday(ES_exfin);
%lastday(SD_exfin);
%lastday(SW_exfin);
%lastday(UK_exfin);

proc sort nodup data=jour.lastday; by lastday; run;
    



/*================
sales regression
/*================*/

proc sort data=ag; by code year;
data ag; set ag;
by code year;
lagsl = lag(sl);
if first.code then lagsl=.;
if year ~= lag(year) + 1 then lagsl = .; /* in case of gap */
logsg = log(sl) - log(lagsl);
rdsl = rd/sl;
l1rdsl = lag(rdsl);
l2rdsl = lag(l1rdsl);
l3rdsl = lag(l2rdsl);
l4rdsl = lag(l3rdsl);
l5rdsl = lag(l4rdsl);
if first.code then do
	l1rdsl=.; l2rdsl=.; l3rdsl=.; l4rdsl=.; l5rdsl=.; end;
if year ~= lag(year) + 1 then do
	l1rdsl=.; l2rdsl=.; l3rdsl=.; l4rdsl=.; l5rdsl=.; end;
run;

proc sort data=ag; by country year;
proc reg data=ag noprint outest=coef1 edf;
model logsg=l1rdsl;
by country year;
run;
proc reg data=ag noprint outest=coef2 edf;
model logsg=l2rdsl;
by country year;
run;
proc reg data=ag noprint outest=coef3 edf;
model logsg=l3rdsl;
by country year;
run;
proc reg data=ag noprint outest=coef4 edf;
model logsg=l4rdsl;
by country year;
run;
proc reg data=ag noprint outest=coef5 edf;
model logsg=l5rdsl;
by country year;
run;
data coef1; set coef1; if _edf_ ge 11; run;
data coef2; set coef2; if _edf_ ge 11; run;
data coef3; set coef3; if _edf_ ge 11; run;
data coef4; set coef4; if _edf_ ge 11; run;
data coef5; set coef5; if _edf_ ge 11; run;
data coef; merge coef1-coef5;
by country year;
ability = (l1rdsl + l2rdsl + l3rdsl + l4rdsl + l5rdsl) / 5;
keep country year ability;
run;




data junk; set ag;
keep ltlps sh myltl dli country year code dl;
run;
proc sort data=junk;
by country;
proc corr data=junk; var myltl; with dli; by country; run;



