
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";
/*
libname disp "C:\TEMP\displace";
libname export "C:\TEMP\export";

libname dsktp "Y:\Desktop\sas-python";

%macro toDesktop(data, var);

data dsktp.&data; set &data;
by country year;
ret=&var;
if &var<=0 then ret=.;
ret2=ret;
keep country year ret ret2;
run;

%mend toDesktop;

%toDesktop(meanretew, ewmktret);
%toDesktop(meanretvw, vwmktret);
%toDesktop(medianret, mdmktret);
*/

%macro toWork(data, var);

proc import out=work.&data
	file="V:\data_for_kai\20190320\&data..csv" 
	dbms=csv replace;
getnames=yes;
run;

data &data; set &data;
&var=ret2;
keep country year &var;
run;

%mend toWork;

%toWork(meanretew, ewmktret);
%toWork(meanretvw, vwmktret);
%toWork(medianret, mdmktret);




data ag19; set nnnDS.agret0;
pf=pref;
dit=tax;
p_updated=p_us_updated*TA/TAUS;
cm=ce;
csh=SHOUT;
dvp=PREFDC;
ocf=cfo;
keep code country year pf dit p_us_updated 
p_updated mc csh cm ta taus dvp ocf cl EPS NI NIBPREFD;
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
/*
if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;*/
run;


proc sql;
	create table ag20 as
	select b.country as country, a.*
	from ag20 as a
	left join db.ctycode as b on a.country=b.cty;
quit;


proc sort data=ag20; by country year;
proc sort data=meanretew; by country year;
proc sort data=meanretvw; by country year;
proc sort data=medianret; by country year;
data ag20; merge ag20(in=a) meanretew(in=b) meanretvw(in=c) medianret(in=d);
by country year;
if a;
proc sort; by code year;
/*proc sort data=retannum2; by code year;*/
run;


data ag21; set ag20;
by code year;

aip1 = proje/ewmktret;
pvgo1 = (mc3 - aip1) / mc3;
aip2 = proje/vwmktret;
pvgo2 = (mc3 - aip2) / mc3;
aip3 = proje/mdmktret;
pvgo3 = (mc3 - aip3) / mc3;
/*
mktret=vwmktret;
if vwmktret<=0 and ewmktret>0 then mktret=ewmktret;
else if vwmktret<=0 and mdmktret>0 then mktret=mdmktret;
*if mktret>-0.5;
aip = proje/mktret;
pvgo = (mc3 - aip) / mc3;*/
*PE = p_updated/EPS;
*PE=MC/csh/eps;
PE=MC/NI;
*PE=MC/NIBPREFD;
portyear=year+1;
drop _type_ _freq_;
run;

data ag21; set ag21;
if pvgo1<10;
if pvgo1>-5;

if pvgo2<10;
if pvgo2>-5;

if pvgo3<10;
if pvgo3>-5;

/*if pvgo2>50 then pvgo2=.;
if RD<=0 then pvgo2=.;
if be1=. then pvgo2=.;
*/
if pe<=-250 then pe=.;
if pe>=250 then pe=.;
*if RD<=0 then pe=.;
*if be1=. then pe=.;

*keep code country portyear pvgo1 pvgo2 pvgo3 PE;
run;

proc means data=pvgosprd; by country; var PE; run;

proc univariate data=pvgosprd; var PE; run;
