
libname newnew "C:\TEMP\newnew_DSWS";

proc sql;
create table country as
select distinct GEOGN from newnew.acct
;
quit;


data mthret0; set newnew.retm;
mthyr = year(date)*100 + month(date);
if RI~=.;
drop name;
proc sort; by dscd mthyr;
run;

data mthret; retain code country mthyr portyear;
set mthret0;
by dscd;
ret = ri/lag(ri)-1;
annee = year(date);
mois = month(date);
portyear = annee;
if mois<=6 then portyear = annee-1;
code = dscd;
country = GEOGN;
if first.dscd then ret=.;
if ret=0 & lag(ret)=0 then delete;
if (1+ret)*(1+lag(ret))<1.5 and (ret>3 or lag(ret)>3) then delete; 
ret_us = ret;
keep code country mthyr portyear ret ret_us;
run; 


data mvdec; set mthret0;
if month(date)=12;
code = dscd;
year = year(date);
portyear = year+1;
mv = mc;
mv_us = mcus;
keep code year portyear mv mv_us;
run;


data acct; retain code country year portyear; 
set newnew.acct;
code = dscd;
country = GEOGN;
COG = COGS;
portyear = year+1;
drop dscd geogn COGS;
*keep code country year portyear RD MC TA SL EMP COG SGA;
run;


data price; set newnew.price;
annee = year(date);
mois = month(date);
if mois=6;
mthyr = annee*100+mois;
code = dscd;
proc sort; by code mthyr;
run;

data price; retain code;
set price;
by dscd mthyr;
if last.mthyr;
portyear=annee;
p_us_updated = p;
keep code portyear p_us_updated;
proc sort; by code portyear;
run;


proc sort data=mthret; by code portyear;
run;
proc sort data=acct; by code portyear;
run;


data agret0; merge mthret(in=a) acct price;
by code portyear;
if a;
proc sort; by portyear country;
run;

proc univariate data=agret0 noprint;
by portyear country;
var p_us_updated;
output out=p_us_10 p10=p_us_10;
run;

data agret0; merge agret0 p_us_10;
by portyear country;
proc sort; by code portyear mthyr;
run;


%macro abbr_country(input);

data &input; set &input;
if country="AUSTRALIA" then country="AU";
else if country="GERMANY" then country="BD";
else if country="CHINA" then country="CH";
else if country="CANADA" then country="CN";
else if country="FINLAND" then country="FN";
else if country="FRANCE" then country="FR";
else if country="GREECE" then country="GR";
else if country="HONG KONG" then country="HK";
else if country="SOUTH KOREA" then country="KO";
else if country="ISRAEL" then country="IS";
else if country="INDIA" then country="IN";
else if country="ITALY" then country="IT";
else if country="JAPAN" then country="JP";
else if country="MALAYSIA" then country="MY";
else if country="SWEDEN" then country="SD";
else if country="SINGAPORE" then country="SG";
else if country="SWITZERLAND" then country="SW";
else if country="TAIWAN" then country="TA";
else if country="TURKEY" then country="TK";
else if country="UNITED KINGDOM" then country="UK";
else if country="UNITED STATES" then country="US";
run;

%mend abbr_country;

%abbr_country(agret0);

data newnew.agret0; set agret0; run;
data newnew.mvdec; set mvdec; run;


data agret0; set newnew.agret0; run;
data mvdec; set newnew.mvdec; run;


data names; set agret0;
keep code;
proc sort nodup; by code;
run;

