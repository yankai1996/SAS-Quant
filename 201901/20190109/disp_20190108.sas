

/* start from here */


options noxwait;
x 'H:\projects';
libname roadeco "H:\projects\roadeco";

libname deco "H:\projects\retdeco";
x 'cd H:\projects\AG';
libname intag '201111';
libname mois '201111\monthly\02_exfin';
libname annee '201111\yearly\02_exfin';
libname ipp 'H:\projects\ipp';
libname jour 'H:\projects\AG\af79\200909\02_exfin';

libname innopoli "H:\projects\innopoli";


x 'cd H:\projects\ipp';
%include 'winsor.sas';




option notes;


data oldnames; set annee.allannual;
keep code country;
proc sort nodup; by code;
run;

/* directly use USD returns downloaded Mar 2016 */
proc import out=retmonthly2016 datafile="H:\projects\ipp\ri_us.dta" replace; run; 
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




/* if use old data eq and pf */
proc sql;
  create table ag01 as
   select a.*, b.opm, b.dda, b.cog, b.dit, b.sga
          from annee.allannual as a
		  left join
          roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year
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


data ag; set ag01 ag011;
by code year;
/* if pf=. then pf=0;*/
if dit=. then dit=0;
be1 = eq-pf+dit;
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
portyear = year + 1;
/*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US"); */
run;



/* throw out 10% of size */


proc import out=ipp.prmonthly2016 datafile="H:\projects\ipp\p.dta";  run;  proc sort; by dscd mthyr; run;
data prmonthly2016; set ipp.prmonthly2016; 
by dscd mthyr;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
portyear = annee -1;
/* if mois<=6 then portyear = annee; */
code = dscd;
if mthyr>=201107;
if mois = 6;
p_us_updated = p;
keep code p_us_updated portyear;
run;
proc sql;
  create table prmonthly2 as
   select a.*, b.country
          from prmonthly2016 as a, oldnames as b
		  where a.code=b.code;
quit;



data prmonthly1; set mois.prmonthly;
if month=6;
portyear = year - 1;
/*portyear = year;*/
keep code p_us_updated portyear country;
run;

data prmonthly; set prmonthly1 prmonthly2; 
run;

proc sort; by portyear country;
run;
proc univariate data=prmonthly noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;

proc sort data=prmonthly; by portyear country;
run;

data prmonthly; merge prmonthly price;
by portyear country;

proc sort; by code portyear;
run;


data retannual; set ipp.retannual;
if ret1y_us~=.;
run;

data mvmois_old; set mois.allmonthly;
mv = mv_updated;
mv_us = mv_us_updated;
if country = 'US' then mv_us = mv_updated;
mthyr = year(date)*100 + month(date);
keep code mv_us mthyr;

proc import out=ipp.mvmois2016 datafile="H:\projects\ipp\mv_us.dta";  run;  proc sort; by dscd mthyr; run;
data mvmois2016; set ipp.mvmois2016; 
by dscd mthyr;
code = dscd;
mv_us = mv;
if mthyr>=201110;
keep code mv_us mthyr;
run;

data mvmois; set mvmois_old mvmois2016;
proc sort; by code mthyr;
run;

/*** use LAG !!! ***/
data mvmois; set mvmois;
by code mthyr;
lagmv_us = lag(mv_us);
if first.code then lagmv_us=.;
run;













data agret0; merge retmonthly5(in=a) ag(in=b) prmonthly ipp.juneret(in=d) ipp.momentum;
by code portyear;
if a and b;
if country='US' then ret_us=ret;
run;

libname db "D:\Dropbox\data_for_kai";
data db.agret0; set agret0;
data db.mvmois; set mvmois;
run;
data db.mvdec; set mois.mvdec;
portyear = year+1;
run;
