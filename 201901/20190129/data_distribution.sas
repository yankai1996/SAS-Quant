
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";
libname dsws "C:\TEMP\new DSWS\";

data agret0; set disp.agret0;
*keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
*if 1981 <= portyear <= 2009;
if portyear > 2009;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", 
"IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
keep code portyear country RD MC EMP COG SGA;
proc sort nodup; by country;
run;

proc means data=agret0;
by country;
var portyear RD MC EMP COG SGA;
output out=acct_old;
run;


data agret1; set dsws.agret0;
if 1981 <= portyear <= 2009;
keep code portyear country RD MC EMP COG SGA;
proc sort nodup; by country;
run;

proc means data=agret1;
by country;
var portyear RD MC EMP COG SGA;
output out=acct_new;
run;


data agret2; set dsws.acct;
portyear = year+1;
country = GEOGN;
*if 1981 <= portyear <= 2009;
if portyear > 2009;
keep code portyear country RD MC EMP COGS SGA;
proc sort nodup; by country;
run;

proc means data=agret2;
by country;
var portyear RD MC EMP COGS SGA;
output out=acct_new;
run;


data dsws.acct_new; set acct_new; run;
data dsws.acct_old; set acct_old; run;
