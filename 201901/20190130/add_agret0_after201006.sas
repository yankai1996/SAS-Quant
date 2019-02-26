
libname dsws "C:\TEMP\new DSWS";
libname disp "C:\TEMP\displace\";
libname old_dsws "C:\TEMP\old DSWS";


data agret0_new; set dsws.agret0; 
if portyear >= 2009;
run;
data agret0_old; set disp.agret0; 
keep code country mthyr portyear ret ret_us year RD EMP MC TA SGA COG p_us_updated p_us_10;
if portyear >= 2009;
run;


proc sql;
create table new_missing_names as
select distinct code, country from agret0_old
where code not in (select distinct code from agret0_new)
;
quit;
proc sort data=new_missing_names; by code; run;


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


data wsacct2009; retain code; set old_dsws.wsacct2018;
portyear=year+1;
if portyear > 2009;
code = dscd;
drop dscd;
run;


data mthret2009; set old_dsws.mthret;
portyear=year(date);
if month(date)<=6 then portyear=portyear-1;
if portyear >= 2009;
run;


proc sql;
create table in_old_mthret0 as
select * from mthret2009
where dscd in (select code from new_missing_names)
;
quit;


data in_old_mthret; retain code; set in_old_mthret0;
code=dscd;
if mthyr>201006;
ret = mthret;
ret_us = ret;
if (ret=0 & lag(ret)=0) & (code = lag(code)) then delete;
if (1+ret)*(1+lag(ret))<1.5 and (ret>3 or lag(ret)>3) then delete; 
keep code mthyr portyear ret ret_us;
proc sort; by code;
run;

data in_old_mthret; retain code country;
merge in_old_mthret(in=a) new_missing_names(in=b);
by code;
if a & b;
proc sort; by code portyear;
run;



data price; retain code; set in_old_mthret0;
if month(date)=6;
p_us_updated = price;
portyear = year(date);
code = dscd;
keep code p_us_updated portyear;
proc sort; by code portyear;
run;



data agret0_in_old_dsws; 
merge in_old_mthret(in=a) wsacct2009(in=b) price;
by code portyear;
if a & b;
run;


data names_in_old_dsws; set agret0_in_old_dsws;
keep code country;
proc sort nodup; by code;
run;


data names_in_new_dsws; set dsws.agret0;
keep code country;
if portyear>2009;
proc sort nodup; by code;
run;
%abbr_country(names_in_new_dsws);


data names_after_2009; set names_in_old_dsws names_in_new_dsws;
proc sort; by code;
run;


libname new_old "C:\TEMP\names_after_2009";

data new_old.names_after_2009; set names_after_2009; run;
data new_old.agret0_in_old_dsws; set agret0_in_old_dsws; run;
data new_old.names_in_old_dsws; set names_in_old_dsws; run;
data new_old.new_missing_names; set new_missing_names; run;



data mvdec2009; set dsws.mvdec;
if portyear>2009;
run;


proc sql;
create table missing_mvdec as
select * from names_in_old_dsws
where code not in (select distinct code from mvdec2009)
;
quit;


proc sql;
create table mvdec_in_old as
select * from mthret2009
where dscd in (select code from missing_mvdec)
;
quit;


data mvdec_in_old; retain code year portyear;
set mvdec_in_old;
if month(date) = 12;
code=dscd;
year=year(date);
portyear=year+1;
mv_us = mv;
keep code year portyear mv mv_us;
run;

data new_old.mvdec_in_old_dsws; set mvdec_in_old; run;


