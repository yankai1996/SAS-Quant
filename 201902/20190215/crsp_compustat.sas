
libname wrds "C:\TEMP\WRDS";

proc sql;
	create table CUSIP_LINK as 
	select distinct a.permno, gvkey, iid, date, prc, SHROUT, vol, ret
	from
		wrds.msf as a, 					/*CRSP Monthly stock file*/
		wrds.msenames 
		(
			where=(not missing(ncusip)	/*Historical CUSIP is not missing*/
			and shrcd in (10 11))		/*Common stocks of U.S. Companies*/
		) as b, 
		wrds.security
		(
			where=(not missing(cusip)	/*Current CUSIP is not missing*/
			and excntry='USA')			/*Stocks listed in U.S. Exchanges*/
		) as c
	where
		a.permno=b.permno
		and NAMEDT<=a.date<=NAMEENDT	/*Date range conditions*/
		and b.ncusip=substr(c.cusip,1,8);	/*Linking on the first 8 alpha-numerics of CUSIP*/
quit;

data wrds.CUSIP_LINK; set CUSIP_LINK; run;


data retm; 
retain code mthyr portyear;
set wrds.cusip_link;
code = permno;
annee = year(date);
mois = month(date);
mthyr = annee*100+mois;
portyear = annee;
if mois<=6 then portyear = annee-1;
keep code mthyr portyear ret ret_us country;
if ret=0 & lag(ret)=0 & code=lag(code) then delete;
if (1+ret)*(1+lag(ret))<1.5 and (ret>3 or lag(ret)>3) and code=lag(code) then delete;
if ret~=.;
if abs(ret)>=0;
ret_us = ret;
country = "US";
proc sort; by code portyear mthyr;
run;


data acct; retain code year portyear RD MC;
set wrds.actg_201901;
code = lpermno;
year = fyear;
portyear = year+1;
RD = XRD;
COG = COGS;
SGA = XSGA;
EMP = Emp;
datamthyr = year(datadate)*100+month(datadate);
keep code year portyear RD MKVALT EMP COG SGA datamthyr;
proc sort; by code datamthyr;
run;

/*
data junk; set wrds.actg_201901;
if month(datadate)~=12 and MKVALT~=.;
keep lpermno datadate fyear MKVALT;
run;

data junk2; set wrds.cusip_link;
if permno=54594;
mcdec = SHROUT * abs(prc)/1000;
keep permno date mcdec;
run;
*/

data mc; set wrds.cusip_link;
code = permno;
datamthyr = year(date)*100+month(date);
MCmth = SHROUT * abs(prc)/1000;
keep code datamthyr MCmth;
proc sort; by code datamthyr;
run;


data acct0; merge acct(in=a) mc(in=b);
by code datamthyr;
if a;
MC = coalesce(MKVALT, MCmth);
drop MKVALT MCmth datamthyr;
proc sort; by code portyear;
run;


data price; set wrds.cusip_link;
if month(date) = 6;
code = permno;
portyear = year(date);
p_us_updated = abs(prc);
keep code portyear p_us_updated;
proc sort; by code portyear;
run;


data agret; merge retm(in=a) acct0(in=b) price(in=c);
by code portyear;
if a & b & c;
proc sort; by portyear;
run;


proc univariate data=agret noprint;
by portyear;
var p_us_updated;
output out=p_us_updated p10=p_us_10;
run;

data agret0; merge agret p_us_updated;
by portyear;
proc sort; by code portyear;
run;


data mvdec; set wrds.cusip_link;
if month(date)=12;
code = permno;
year = year(date);
portyear = year+1;
mv = SHROUT * abs(prc)/1000;
mv_us = mv;
if mv~=. and mv~=0;
keep code year portyear mv mv_us;
run;



data wrds.agret0; set agret0; run;
data wrds.mvdec; set mvdec; run;



data nyse; set wrds.msenames;
if shrcd=10 or shrcd=11;
nyse=0;
if EXCHCD = 1 then nyse=1;
code = permno;
keep code nyse NAMEENDT;
proc sort nodup; by code nyse;
run;

/*
data junk; set nyse;
by code nyse;
lagnyse=lag(nyse);
if first.code then lagnyse=.;
if nyse~=lagnyse and lagnyse~=.;
run;
*/




data junk; set wrds.msf;
keep permno date ret dlret;
run;


data agret0; set wrds.agret0; run;

data agret0; merge agret0(in=a) nyse;
by code;
if a;
run;
