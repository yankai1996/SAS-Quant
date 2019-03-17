
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


data logret; retain code country; set nnnDS.retm;
code=dscd;
country=geogn;
if ri~=.;
keep code country date ri;
proc sort; by code date;
run;
data logret; set logret;
by code date;
year=year(date);
ret=log(ri/lag(ri));
ret_us=ret;
if first.code then ret=.;
proc sort; by code year country;
run;

proc means data=logret noprint;
var ret ret_us;
by code year country;
output out=aret sum=ret ret_us n=n1 n2;
run;

data retannum; set aret;
calret1y=exp(ret)-1;
calret1y_us=exp(ret_us)-1;
if n1>=11;
if year>=1981;
if calret1y<3;
if calret1y>-1;
keep code country year calret1y calret1y_us n1 n2;
proc sort; by code year;
run;

data retannum; merge retannum(in=a) nnnDS.mvdec(in=b);
by code year;
if a and b;
proc sort; by country year;
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
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
/* proje = eroe*(dli-dl);*/
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

data ag20; merge ag20(in=a) meanretew(in=b) meanretvw(in=c) medianret(in=d);
by country year;
if a;
proc sort; by code year;
run;
proc sort data=retannum; by code year;
data ag20; merge ag20(in=a) retannum;
by code year;
if a;
aip1 = proje/ewmktret;
pvgo1 = (mc3 - aip1) / mc3;
aip2 = proje/vwmktret;
pvgo2 = (mc3 - aip2) / mc3;
aip3 = proje/mdmktret;
pvgo3 = (mc3 - aip3) / mc3;
PE = p_updated/EPS;
drop _type_ _freq_;
run;

data nnnDS.ag20; set ag20; run;



data ag21; set nnnDS.ag20;
*if pvgo2<10;
*if pvgo2>-5;
portyear=year+1;
keep country portyear pvgo1 pvgo2 pvgo3 PE;
run;
proc sql;
	create table ag21 as
	select b.country as country, a.*
	from ag21 as a
	left join db.ctycode as b on a.country=b.cty;
quit;

%winsor(dsetin=ag21, dsetout=ag22, byvar=country portyear, vars=pvgo1 pvgo2 pvgo3, type=delete, pctl=20 80);

data ag22; set ag22;
if country="" then delete;
proc sort; by country portyear;
run;


proc means data=ag22 noprint; 
var pvgo1 pvgo2 pvgo3 PE;
by country portyear;
output out=gobar20 std=pvgobar1 pvgobar2 pvgobar3 pebar;
run;


libname twoDsprd "C:\TEMP\sprd\REG2DSE";
data twoDsprd.gobar20; set gobar20; run;


