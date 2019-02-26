
libname dsws "C:\TEMP\new DSWS";
libname disp "C:\TEMP\displace\";


data agret0_new; set dsws.agret0; 
if mthyr <= 201006;
run;
data agret0_old; set disp.agret0; 
keep code country mthyr portyear ret ret_us year RD EMP MC TA SGA COG p_us_updated p_us_10;
if mthyr <= 201006;
run;


proc sql;
create table new_names as
select * from agret0_new
where code not in (select distinct code from agret0_old)
;
quit;



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


%abbr_country(new_names);


data agret0; set agret0_old new_names;
proc sort; by code mthyr;
run;



data mvdec_new; set dsws.mvdec; 
if portyear<=2009;
run;
data mvdec_old; set disp.mvdec; 
if portyear<=2009;
drop country;
run;

proc sql;
create table new_names2 as 
select * from mvdec_new
where code not in (select distinct code from mvdec_old)
;
quit;

data mvdec; set mvdec_old new_names2;
proc sort; by code portyear;
run;


data dsws.new_names; set new_names; run;
data dsws.new_mvdec_2009; set new_names2; run;



data acct; set dsws.acct;
code = dscd;
portyear = year+1;
if portyear<=2009;
drop geogn dscd year;
proc sort; by code portyear;
run;

data new_names; set new_names;
keep code country mthyr portyear year ret ret_us p_us_updated;
proc sort; by code portyear;
run;

data new_obs; merge new_names(in=a) acct(in=b);
by code portyear;
if a;
run;

data dsws.new_obs; set new_obs; run;

data dsws.new_names; set new_names;
keep code country;
proc sort nodup; by code;
run;
