

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


data oldnames; set annee.allannual;
keep code country;
proc sort nodup; by code;
run;

/* directly use USD returns downloaded Mar 2016 */
proc import out=retmonthly2016 datafile="O:\projects\ipp\ri_us.dta" replace; run; 
proc sql;
  create table retmonthly3 as
   select a.*, b.country
          from retmonthly2016 as a, oldnames as b
		  where a.dscd=b.code;
quit;

 
proc sort; by dscd mthyr;
data retmonthly4; set retmonthly3; 
by dscd mthyr;
ri_usd = ri;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
portyear = annee;
if mois<=6 then portyear = annee-1;
code = dscd;
ret = ri/lag(ri) - 1;
ret_us = ri_usd/lag(ri_usd) - 1; 
IF first.dscd THEN DO;
	ret = 0;
END;
if ret=0 & lag(ret)=0 then delete;
if mthyr>=201107;
if (1+ret)*(1+lag(ret))<1.5 and ret>3 or lag(ret)>3 then delete;
keep code ret ret_us portyear mthyr;
run;



data retmonthly2; set ipp.retmonthly2;
if mthyr<=201106;
keep code ret ret_us portyear mthyr;
run;
data retmonthly5; set retmonthly2 retmonthly4;


run;

proc sql;
	create table retmonthly5 as
	select a.*, b.country
	from retmonthly5 as a
	left join oldnames as b on a.code=b.code;
quit;
proc sort; by code portyear mthyr;
run;






/* if use 2008 new data */
proc sql;
  create table ag00 as
   select
          case when a.year=2008 then coalesce(a.mc, b.mc) else a.mc end as mc,
			case when a.year=2008 then coalesce(a.cm, b.cm) else a.cm end as cm,
			case when a.year=2008 then coalesce(a.ta, b.ta) else a.ta end as ta,
			case when a.year=2008 then coalesce(a.tl, b.tl) else a.tl end as tl,
			case when a.year=2008 then coalesce(a.eq, b.eq) else a.eq end as eq,
			case when a.year=2008 then coalesce(a.pf, b.pf) else a.pf end as pf, a.*, b.opm, b.dda, b.cog, b.dit, b.sga
          from annee.allannual as a
		  left join
          roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year;
quit;


/* if use old data eq and pf */
proc sql;
  create table ag01 as
   select a.*, b.opm, b.dda, b.cog, b.dit, b.sga
          from annee.allannual as a
		  left join
          roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year;
quit;
/* results in 20150417 */


/* if use both data */
proc sql;
  create table ag02 as
   select coalesce(a.mc, b.mc) as mc, coalesce(a.cm, b.cm) as cm, coalesce(a.ta, b.ta) as ta, coalesce(a.tl, b.tl) as tl, coalesce(a.eq, b.eq) as eq,
			coalesce(a.pf, b.pf) as pf, a.*, b.opm, b.dda, b.cog, b.dit, b.sga
          from annee.allannual as a
		  left join
          roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year;
quit;
/* results in 20150418, does not work well */









/* The difference between BE1 and BE4 is don't set pf=0 when pf=.
if so, BE1 will be same as BE4 */



/* if use old data eq and pf */
/* some sh are missing, need to back out */
proc sql;
  create table ag01 as
   select a.*, b.opm, b.dda, b.cog, b.dit, b.sga, a.mc/c.p_updated as sh2
          from annee.allannual as a
		  left join roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year
		  left join mois.prmonthly as c
		  on a.code=c.code and a.year=c.year and c.month=12
			where a.year<=2008;
quit;
proc sql;
  create table ag011 as
   select a.*, b.country, a.dscd as code
          from roadeco.annual2014 as a		
		  left join oldnames as b on a.dscd=b.code
		where a.year>=2009 and b.country~="";
quit;
proc sort; by code year;
run;


/* data ag; set ag00;
data ag; set ag02;
*/
data ag; set ag01 ag011;
by code year;
l1rd = lag(rd);
l2rd = lag(l1rd);
l3rd = lag(l2rd);
l4rd = lag(l3rd);
if first.code then do
	l1rd=.; l2rd=.; l3rd=.; l4rd=.; end;
if year ~= lag(year) + 1 then do
	l1rd=.; l2rd=.; l3rd=.; l4rd=.;	end;
rdc = rd + 0.8*l1rd + 0.6*l2rd + 0.4*l3rd + 0.2*l4rd;
if rd~=. & l1rd=. & l2rd=. & l3rd=. & l4rd=. then rdc = (rd)*3;
if rd~=. & l1rd~=. & l2rd=. & l3rd=. & l4rd=. then rdc = (rd + .8*l1rd)*3/1.8;
if rd~=. & l1rd~=. & l2rd~=. & l3rd=. & l4rd=. then rdc = (rd + .8*l1rd + .6*l2rd)*3/2.4;
if rd~=. & l1rd~=. & l2rd~=. & l3rd~=. & l4rd=. then rdc = (rd + 0.8*l1rd+0.6*l2rd+0.4*l3rd)*3/2.8;
rdc2 = (rd + l1rd + l2rd + l3rd + l4rd)/5;
if rd~=. & l1rd=. & l2rd=. & l3rd=. & l4rd=. then rdc2 = rd;
if rd~=. & l1rd~=. & l2rd=. & l3rd=. & l4rd=. then rdc2 = (rd + l1rd)/2;
if rd~=. & l1rd~=. & l2rd~=. & l3rd=. & l4rd=. then rdc2 = (rd + l1rd + l2rd)/3;
if rd~=. & l1rd~=. & l2rd~=. & l3rd~=. & l4rd=. then rdc2 = (rd + l1rd + l2rd + l3rd)/4;
if dit=. then dit=0;
rdc3 = rd;
be1 = eq-pf+dit;
be2 = ta-tl-pf+dit;
be3 = cm+dit;
portyear = year + 1;
/*rdme = rdc/mc;
rdme2 = rdc2/mc;
rdme3 = rdc3/mc;
rdbe = rdc/be;
rdbe2 = rdc2/be;
rdbe3 = rdc3/be;
rdta = rdc/ta;
rdta2 = rdc2/ta;
rdta3 = rdc3/ta;
sga =  sl*(1-opm/100)-cog-dda;
sgame = sga/mc;
if rd=. then sgame=.;
rdsga = rdc/(sl*(1-opm/100)-cog-dda);
rdsga2 = rdc2/(sl*(1-opm/100)-cog-dda);
rdsga3 = rdc3/(sl*(1-opm/100)-cog-dda);
exp =  sl*(1-opm/100);
rdexp = rdc/exp;
rdexp2 = rdc2/exp;
rdexp3 = rdc3/exp;
rdzero = .;
if rdme=. then rdzero=9999;
rdag = rdc/(ta-lagta);
rdag2 = rdc2/(ta-lagta);
rdag3 = rdc3/(ta-lagta);
rdce = rdc/ce;
rdce2 = rdc2/ce;
rdce3 = rdc3/ce;
rdlag1 = rd/lagme;
rdlag2 = rd/lagbe;
rdlag3 = rd/lagta;
rdbarbe5 = rdc2/lag5(be);
rdbarta5 = rdc2/lag5(ta);
rdbarta = (rd/lag(ta) + l1rd/lag2(ta) + l2rd/lag3(ta) + l3rd/lag4(ta) + l4rd/lag5(ta))/5;
if rd~=. & l1rd=. & l2rd=. & l3rd=. & l4rd=. then rdbarta = rd/lag(ta);
if rd~=. & l1rd~=. & l2rd=. & l3rd=. & l4rd=. then rdbarta = (rd/lag(ta) + l1rd/lag2(ta))/2;
if rd~=. & l1rd~=. & l2rd~=. & l3rd=. & l4rd=. then rdbarta = (rd/lag(ta) + l1rd/lag2(ta) + l2rd/lag3(ta))/3;
if rd~=. & l1rd~=. & l2rd~=. & l3rd~=. & l4rd=. then rdbarta = (rd/lag(ta) + l1rd/lag2(ta) + l2rd/lag3(ta) + l3rd/lag4(ta))/4;
rdbarbe = (rd/lag(be) + l1rd/lag2(be) + l2rd/lag3(be) + l3rd/lag4(be) + l4rd/lag5(be))/5;
if rd~=. & l1rd=. & l2rd=. & l3rd=. & l4rd=. then rdbarbe = rd/lag(be);
if rd~=. & l1rd~=. & l2rd=. & l3rd=. & l4rd=. then rdbarbe = (rd/lag(be) + l1rd/lag2(be))/2;
if rd~=. & l1rd~=. & l2rd~=. & l3rd=. & l4rd=. then rdbarbe = (rd/lag(be) + l1rd/lag2(be) + l2rd/lag3(be))/3;
if rd~=. & l1rd~=. & l2rd~=. & l3rd~=. & l4rd=. then rdbarbe = (rd/lag(be) + l1rd/lag2(be) + l2rd/lag3(be) + l3rd/lag4(be))/4;
*/
lagta = lag(ta);
if first.code then lagta=.;
if year ~= lag(year) + 1 then lagta = .; /* in case of gap */
myroa = roa*(ta+lagta)/2/ta/100;
lagcm = lag(cm);
if first.code then lagcm=.;
if year ~= lag(year) + 1 then lagcm = .; /* in case of gap */
myroe = roe*(cm+lagcm)/2/cm/100;
ag = ta/lagta - 1;
/* new */
sh = coalesce(sh,csh,sh2);
if rd=. & rdc=. & rdc=. then delete; 
if rd<=0 & rdc<=0 & rdc2<=0 then delete;
run;


/* monthly price */
data prmonthly1; set mois.prmonthly;
mthyr = year*100 + month(date);
portyear = year;
if month(date)<=6 then portyear = year-1;
keep code p_updated p_us_updated portyear country mthyr;
run;

proc import out=ipp.prmonthly2016 datafile="o:\projects\ipp\p.dta";  run;  proc sort; by dscd mthyr; run;
data prmonthly2016; set ipp.prmonthly2016; 
by dscd mthyr;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
portyear = annee -1;
/* if mois<=6 then portyear = annee; */
code = dscd;
if mthyr>=201107;
p_us_updated = p;
keep code p_us_updated portyear mthyr;
run;
proc sql;
  create table prmonthly2 as
   select a.*, b.country
          from prmonthly2016 as a, oldnames as b
		  where a.code=b.code;
quit;

data prmonthly; set prmonthly1 prmonthly2; 
run;
proc sort; by code portyear mthyr;
run; 




/* generate mometnum 
should be log return here */


proc sort data=retmonthly5; by code mthyr;
data momenret; set retmonthly5;
by code mthyr;
lagret = 0;
rev = lag(ret_us);
if first.permno then do
	rev = .;
end;
run;

%macro fairelag(rhs);
%do i = 0 %to 11;
%let j=%eval(&i+1);
data momenret; set momenret;
by code mthyr;
lag0&rhs = &rhs;
lag&j&rhs = lag(lag&i&rhs);
if first.code then lag&j&rhs = .;
lagret = lagret + lag&j&rhs;
run;
%end;
%mend;
%fairelag(ret_us);
/* turn log return to total return */
data momenret; set momenret;
momen_ret = exp(lagret - rev) - 1;
run;



/* generate firm level monthly stock return sample */

proc sort data=ag; by code portyear;
/* data agret0; merge ipp.retmonthly5(in=a) ag(in=b) ipp.momentum prmonthly; */
data agret0; merge momenret(in=a) ag(in=b) ipp.momentum prmonthly mois.mvjune;
by code portyear;
if a and b;
if country='US' then ret_us=ret;
/* if rhs ne .;
if ret_us ne .;	*/

if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10;
/* keep mno ret ret_us mthyr code country portyear ta ag be1 be2 be3 cm mc sl rd rdc rdc2 roe roa myroe myroa momenret_mth p_us_updated;
* if set pf and dit to zero when missing                          *
* this is the difference between 20141127 and 20141212 data       *
* in 20141127 the be are defined in sas already                   *
* now in 20141212 I define in stata                               *
* but if do not set to zero when missing                          *
* then I get identical results                                    *
*---------------------------------------------------------------- */
mno = (floor(mthyr/100)-1964)*12 + (mthyr-floor(mthyr/100)*100);
mc2=p_updated*sh;
if country="UK" then mc2=p_updated*sh/100;
keep mno ret ret_us mthyr code country portyear ta ag cm mc sl sh rd rdc rdc2 roe roa myroe myroa momenret p_updated p_us_updated eq tl pf dit momen_ret mv mv_us mc2;
run;


/* if do not do winsorization and truncation */
data agret1; set agret0; run;
proc sort; by code portyear;
run;

/* if do winsorization and truncation
%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=ret_us, type=winsor, pctl=1 99);
proc sort; by code portyear;
run;




data agret1; merge agret1(in=a) mois.mvjune(in=b);
by code portyear;
if a;
***if mv_us ne .; *
run; */

/* scale within a country */
proc sort data=agret1;
by country portyear;
run;
proc means data=agret1 noprint; by country portyear;
var mv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;




/* 	make sure at least 50 observation for each country year */
/* otherwise always some odd rankings to disturb taking average */
data meanmv; set meanmv;
/*if n>=0; */
run;


option notes;

data agret; merge agret1(in=a) meanmv(in=b);
by country portyear;
if a;
/* ew = 1; */
mvport = mv_us/mvsum;
/* mvport = mv/mvbar; */
drop _type_ _freq_;
run;

data tem; set agret;
/* if myroe>-10 and myroe<10;
if portyear>1985;
if ret_us~=.;  */
run;

/* merging with inudstry information */

proc sort data=tem;
by code;
run;
data tem1; merge db.siccode(in=a) db.indcode(in=b);
by code;
keep code indcode ftag3 ftag4 ftag5;
run;
data tem2; merge tem(in=a) tem1;
by code;
if a;
drop mvsum mvbar;
/* if mthyr>201206 then delete;  */
run;
proc sort; by country portyear;
run;


/*
proc import out= ipp.agdata
            datafile= "o:\projects\ipp\agdata.xls"
            dbms=xls replace;
     getnames=yes;
     datarow=2;
run;
proc sort; by country portyear;
run;



data tem3; merge tem2 ipp.agdata;
by country portyear;
drop ewsprd vwsprd ewslope vwslope mno Y Z;
if mthyr>201006 then delete;
run;
*/

proc export data= work.tem2
			outfile= "d:\data_for_kai\data_monthly20190501.csv"
            dbms=csv replace;
     /*range="rhs2"; */
run;

/*obtain volatility */
proc sort data=tem2; by code portyear;
proc means data=tem2 noprint; by code portyear;
var ret_us; output out=db.volout_20190501 std=vol n=n;
run;


















































/* only select those work in annual sample *
--------------------------------------------------
proc sql;
 create table tem3 as
 select *
 from tem2
 where code in (select code from ipp.table3aug) and portyear in (select portyear from ipp.table3aug)
and tem2.p_us_updated >1;
quit;
*/

/* also remove penny stocks */
data comp1; set tem2;
data comp2; set ipp.table3aug_20140402;
run;

proc sort data=comp1 nodup; by code portyear;
proc sort data=comp2 nodup; by code portyear;
run;
data tem3; merge comp1(in=a) comp2(in=b);
by code portyear;
/*if b;
if p_us_updated<=1 then delete; */
run;
data tem4; set tem3;
keep code portyear;
proc sort data=tem4 nodup; by code portyear;
run;

/* what's the difference between monthly and yearly ???*/
data comp2; set ipp.table3aug_20140402;
if p_us_updated<=1 then delete;
keep code portyear;
run;
proc sort data=comp2 nodup; by code portyear;
run;




PROC EXPORT DATA= WORK.tem3
            OUTFILE= "O:\projects\IPP\data_monthly.csv"
            DBMS=CSV REPLACE;
     /*RANGE="rhs2"; */
RUN;
