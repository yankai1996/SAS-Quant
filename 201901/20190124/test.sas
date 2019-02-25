
libname crsp "C:\TEMP\crsp";
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";



data unmerged; set crsp.unmerged;
if shrcd~=10 & shrcd~=11 then delete;
nyse=0;
if exchcd=1 then nyse=1;
run;

proc sql; 
create table names as 
select distinct permno as code from unmerged;
quit;



proc sql;
create table actg as
select * from crsp.actg_201901
where LPERMNO in (select code from names)
;
create table crsp as
select * from crsp.crsp_201901
where LPERMNO in (select code from names)
;
quit;


data actg; set actg;
portyear = fyear+1;
code = LPERMNO;
proc sort; by LPERMNO portyear;
run;

proc sort data=crsp; by LPERMNO datadate; run;
data crsp; set crsp;
by LPERMNO datadate;
code = LPERMNO;
annee = year(datadate);
mois = month(datadate);
portyear = annee;
if mois<=6 then portyear = annee-1;
ret = TRT1M;
*if ret=0 & lag(ret)=0 then delete;
*if (1+ret)*(1+lag(ret))<1.5 and ret>3 or lag(ret)>3 then delete; 
run;



data mvdec; set crsp;
keep code annee mois CSHOQ PRCCM;
mv = CSHOQ*PRCCM;
proc sort; by code annee mois;
run;


data mvdec1; set mvdec;
if mois=12;
run;


data mvdec2; set unmerged;
annee = year(date);
mois = month(date);
code = PERMNO;
keep code annee mois PRC SHROUT;
proc sort; by code annee mois;
run;


data mvdec_merged;
retain code annee mois;
merge mvdec(in=a) mvdec2(in=b);
by code annee mois;
if a;
run;

data junk; set mvdec_merged2;
if mois=12;
run;

data junk2; set junk;
if (CSHOQ=. & SHROUT=.) or (PRCCM=. & PRC=.);
run;

data junk3; set junk;
*if CSHOQ*1000 ~= SHROUT;
if round(CSHOQ, 1) ~= round(SHROUT/1000, 1);
if CSHOQ~=. & SHROUT~=.;
run;

data junk4; set junk;
if round(PRCCM, 0.0001) ~= round(abs(PRC),0.0001);
if PRCCM~=. & PRC~=.;
run;

data junk34; set junk3 junk4;
proc sort nodup; by code annee mois;
run;

data junk5; set mvdec_merged;
if code=10772;
run;




data mvdec_merged1; set mvdec_merged;
if mois~=12 and CSHOQ=. then delete;
lagCSHOQ = lag(CSHOQ);
run;

data mvdec_merged2; set mvdec_merged1;
if mois=12 & CSHOQ=. & code=lag(code) & annee=lag(annee) then CSHOQ=lagCSHOQ;
run;



data mvdec_merged1; set mvdec_merged;
if mois~=12 and PRCCM=. then delete;
lagPRCCM = lag(PRCCM);
lagcode = lag(code);
lagannee = lag(annee);
if mois=12;
drop CSHOQ PRC;
run;

data juuuunk; set mvdec_merged1;
if PRCCM=.;
run;

data mvdec_merged2; set mvdec_merged1;
if PRCCM=. & code=lagcode & annee=lagannee then PRCCM=lagPRCCM;
run;


data mvdec_201901;
retain code year mv mv_us;
set mvdec_merged2;
mv = PRCCM*SHROUT;
mv_us = mv;
format mv mv_us 18.4;
year = annee;
portyear = year+1;
keep code year portyear mv mv_us;
if mv~=.;
run;

/*
data crsp.mvdec_201901; set mvdec_201901;
run;
*/


data pmois; set crsp;
if mois=6;
portyear = annee;
p_us_updated = PRCCM;
keep code portyear p_us_updated;
proc sort; by portyear;
run;

proc univariate data=pmois noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data pmois; merge pmois price;
by portyear;
proc sort; by code portyear;
run;


data crsp1; retain code mthyr portyear; set crsp;
ret = TRT1M/100;
ret_us = ret;
mthyr = annee*100+mois;
keep code mthyr portyear ret ret_us p_us_updated;
if ret=0 & lag(ret)=0 & code=lag(code) then delete;
if (1+ret)*(1+lag(ret))<1.5 and (ret>3 or lag(ret)>3) and code=lag(code) then delete;
if ret~=.;
proc sort; by code portyear; 
run;

data crsp2; merge crsp1(in=a) pmois(in=b);
by code portyear;
if a;
run;


data actg1; retain code portyear; set actg;
RD = XRD;
COG = COGS;
MC = MKVALT;
SGA = XSGA;
keep code portyear RD MC EMP COG SGA;
proc sort; by code portyear;
run;

data agret201901;
retain code mthyr year portyear RD EMP MC COG;
merge crsp2(in=a) actg1(in=b);
by code portyear;
if a & b;
year = floor(mthyr/100);
proc sort; by code mthyr;
run;

data nyse; set unmerged;
code = permno;
mthyr = year(date)*100+month(date);
keep code mthyr nyse;
proc sort nodup; by code mthyr;
run;


data agret_201901; merge agret201901(in=a) nyse(in=b);
by code mthyr;
if a;
if nyse~=.;
drop p_us_10;
proc sort data=agret_201901; by portyear;
run;

proc univariate data=agret_201901 noprint;
by portyear;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret_20190124; 
retain code mthyr portyear RD MC EMP COG ret ret_us p_us_updated p_us_10;
merge agret_201901 price;
by portyear;
proc sort; by code portyear;
run;


data SGA; set actg1;
keep code portyear SGA;
proc sort; by code portyear;
run;

proc sort data=agret_20190124;
by code portyear;
run;

data agret_20190124;
retain code mthyr portyear RD MC EMP COG SGA ret ret_us p_us_updated p_us_10;
merge agret_20190124(in=a) sga(in=b);
by code portyear;
if a;
run;

data junk; set agret_20190124;
if code = 65218;
drop ret ret_us mthyr;
proc sort nodup; by portyear;
run;

data junk2; set crsp.actg_201901;
if lpermno = 65218;
proc sort; by fyear;
run;
/*
data crsp.agret_20190124; set agret_20190124; 
run;

data crsp.agret_201901; set agret0; 
drop country SGA;
run;

data crsp.mvdec_201901; set mvdec; 
run;
*/
data junk; set crsp.actg_201901;
proc sort; by fyear lpermno;
run;

data junk2; set crsp.unmerged;
if permno=10051;
run;

data junk3; set crsp.crsp_201901;
if lpermno=10051;
proc sort; by datadate;
run;

data junk3; set unmerged;
keep permno date nyse;
proc sort nodup; by permno date;
run;
data junk3; set junk3;
if nyse~=lag(nyse) and permno=lag(permno);
run;




data mvdec; set crsp.mvdec_201901; 
run;


data agret201901; set crsp.agret_201901; 
run;


data agret_20190124; set crsp.agret_20190124;
proc sort; by code portyear;
run;

data mvdec_20190124; set crsp.mvdec_201901;
keep code portyear mv;
proc sort; by code portyear;
run;

data agret_20190124; merge agret_20190124(in=a) mvdec_20190124(in=b);
by code portyear;
if a;
MC = MV/1000;
drop MV;
run;


