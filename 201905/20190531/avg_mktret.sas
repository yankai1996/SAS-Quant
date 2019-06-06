
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

/* --- try VW market return --------------*/
proc means data=retannum2 noprint; by country year;
var calret1y;
weight mv; 
output out=meanretvw mean=vwmktret;
run;

/*---- try median -----*/
proc univariate data=retannum2 noprint;
by country year;
var calret1y;
output out=medianret median=mdmktret;
run;



*libname pwd "Z:\Users\kaiyan\Desktop";
%macro savemktret(name, ret);

proc sql;
	create table &name as
	select b.country as country, a.*
	from &name as a
	left join db.ctycode as b on a.country=b.cty;
quit;

proc sort data=&name; by country year;
data pwd.&name; set &name;
by country year;
ret=&ret;
if ret<=-0.1 then ret=.;
ret2=ret;
if country~="";
keep country year ret ret2;
run;

%mend;

%savemktret(meanretew, ewmktret);
%savemktret(meanretvw, vwmktret);
%savemktret(medianret, mdmktret);


/********
...
Python
...
********/


%macro toWork(data, var);

proc import out=&data
	file="C:\TEMP\displace\20190531\&data..csv" 
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
