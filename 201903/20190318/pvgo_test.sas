
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


data retm; retain code country; set nnnDS.retm;
code=dscd;
country=geogn;
if ri~=.;
keep code country date ri;
proc sort; by code date;
run;
/*
data logret; set nnnDS.agret0;
keep code country mthyr ret ret_us;
proc sort; by code mthyr;
run;
*/
data retm; set retm;
by code date;
year=year(date);
ret=ri/lag(ri);
/*
if ret=0 & lag(ret)=0 then delete;
if (1+ret)*(1+lag(ret))<1.5 and ret>3 or lag(ret)>3 then delete; 
*/
if first.code then ret=.;
proc sort; by code year country;
run;

data logret; set retm;
ret=log(ret);
run;

proc means data=logret noprint;
var ret;
by code year country;
output out=aret sum=ret n=n;
run;

data retannum; set aret;
calret1y=exp(ret)-1;
if n>=11;
if year>=1981;
if calret1y<3;
if calret1y>-1;
keep code country year calret1y n;
proc sort; by code year;
run;

/*
data logret; retain code country; set nnnDS.retm;
code=dscd;
country=geogn;
*if ri~=.;
if month(date)=12;
keep code country date ri;
proc sort; by code date;
run;

data retannum; set logret;
by code date;
rety=ri/lag(ri)-1;
year=year(date);
*if n1>=11;
if first.code then rety=.;
if year~=lag(year)+1 then rety=.;
if year>=1981;
if rety<3;
if rety>-1;
rety_us=rety;
keep code country year rety rety_us n1 n2;
proc sort; by code year;
run;
*/

data retannum; merge retannum(in=a) nnnDS.mvdec(in=b);
by code year;
if a and b;
/*proc sort; by country year;*/
run;

%winsor(dsetin=retannum, dsetout=retannum2, byvar=portyear country, vars=mv, type=delete, pctl=5 95);

proc sort data=retannum2; by country year; run;

/* --- try EW market return --------------*/
proc means data=retannum2 noprint; by country year;
var calret1y;
output out=meanretew mean=ewmktret;
run;
proc means data=meanretew noprint; by country;
var ewmktret; output out=meanret2 mean=ret1ybarew;
run;

/* --- try VW market return --------------*/
proc means data=retannum2 noprint; by country year;
var calret1y;
weight mv; 
output out=meanretvw mean=vwmktret;
run;
proc means data=meanretvw noprint; by country;
var vwmktret; output out=meanret3 mean=ret1ybarvw;
run;

/*---- try median -----*/
proc univariate data=retannum2 noprint;
by country year;
var calret1y;
output out=medianret median=mdmktret;
run;
proc means data=medianret noprint; by country;
var mdmktret; output out=medianret2 mean=ret1ybarbar;
run;




data ag19; set nnnDS.agret0;
pf=pref;
dit=tax;
p_updated=p_us_updated*TA/TAUS;
cm=ce;
csh=SHOUT;
dvp=PREFDC;
ocf=cfo;
keep code country year pf dit p_us_updated 
p_updated csh cm ta dvp ocf cl EPS;
proc sort nodup; by code year;
run;


data ag20; set ag19;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
/* mc2=p_updated*sh; */
mc2 = p_updated*csh; 
*if country="UK" then mc2=p_updated*csh/100;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = coalesce(be1, be2, be3);

ndltl = ta - cl - dvp;
goroe = ocf/lag(ndltl);
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; 
end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;
end;
eroe = coalesce(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe,(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe)/.9,(0.4*l1goroe + 0.3*l2goroe)/.7,l1goroe);
if eroe<0 || eroe>1 then eroe=.;
proje = eroe*ndltl; 
if proje<-1 then proje=.; 
mc3 = mc2; 
if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;
proc sort; by country year;
run;

proc sort data=meanretew; by country year;
proc sort data=meanretvw; by country year;
proc sort data=medianret; by country year;
data ag20; merge ag20(in=a) meanretew(in=b) meanretvw(in=c) medianret(in=d);
by country year;
if a;
proc sort; by code year;
run;
proc sort data=retannum; by code year;
data ag21; merge ag20(in=a) retannum;
by code year;
if a;
/*
aip1 = proje/ewmktret;
pvgo1 = (mc3 - aip1) / mc3;
aip2 = proje/vwmktret;
pvgo2 = (mc3 - aip2) / mc3;
aip3 = proje/mdmktret;
pvgo3 = (mc3 - aip3) / mc3;*/
mktret=vwmktret;
if vwmktret<0 and ewmktret>0 then mktret=ewmktret;
else if vwmktret<0 and mdmktret>0 then mktret=mdmktret;
*if mktret>-0.5;
aip = proje/mktret;
pvgo = (mc3 - aip) / mc3;
PE = p_updated/EPS;
drop _type_ _freq_;
run;


data ag21; set ag21;
if pvgo<100;
if pvgo>-5;
if pvgo<-1 then pvgo=.;

/*if pvgo2>50 then pvgo2=.;
if RD<=0 then pvgo2=.;
if be1=. then pvgo2=.;
*/
if pe<=-250 then pe=.;
if pe>=250 then pe=.;
*if RD<=0 then pe=.;
*if be1=. then pe=.;

portyear=year+1;
*keep code country portyear pvgo1 pvgo2 pvgo3 PE;
run;
proc sql;
	create table ag21 as
	select b.country as country, a.*
	from ag21 as a
	left join db.ctycode as b on a.country=b.cty;
quit;

*%winsor(dsetin=ag21, dsetout=ag21, byvar=country portyear, vars=mv, type=delete, pctl=5 95);

%winsor(dsetin=ag21, dsetout=ag22, byvar=country portyear, vars=pvgo pe, type=delete, pctl=10 90);

data ag22; set ag22;
if country="" then delete;
*if mktret>=0;
proc sort; by country portyear;
run;


%macro pvgosprd(i);

proc univariate data=ag22 noprint;
by country portyear;
var pvgo PE;
output out=pvgosprd pctlpre=pvgo pe pctlpts=0 to 100 by &i;
run;

%let j = %eval(100-&i);

data pvgosprd&i; set pvgosprd;
/*pvgo1=pvgo1&j-pvgo1&i;
pvgo2=pvgo2&j-pvgo2&i;
pvgo3=pvgo3&j-pvgo3&i;*/
pvgo=pvgo&j-pvgo&i;
pe=pe&j-pe&i;
keep country portyear pvgo pe;
run;

%mend pvgosprd;

%pvgosprd(20);


data pvgosprd; set pvgosprd20; 
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;



proc univariate data=ag22; 
var ewmktret vwmktret mdmktret mktret pvgo;
run;

proc means data=ag22; 
var ewmktret vwmktret mdmktret mktret pvgo;
run;


data junk; set ag22;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
if mktret<0;
keep country code year mv mv_us ret ewmktret vwmktret mdmktret mktret pvgo;
proc sort; by code year;
run;

data junk2; set aret;
keep code year ret;
run;

data junk; merge junk(in=a) junk2(in=b);
by code year;
if a and b;
if ret>0 then positive=1;
keep country code year mv mv_us ret ewmktret vwmktret mdmktret positive;
proc sort; by country year descending mv;
run;



data junk2; set junk;
if country="US" and year=2002;
proc means;
run;



