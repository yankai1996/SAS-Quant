
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";

data agret0; set disp.agret0;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
if mthyr <= 201006;
proc sort; by mthyr country;
run;

data rate2010; set export.rate2010;
proc sort; by mthyr country;
run;

data agret0; merge agret0(in=a) rate2010;
by mthyr country;
if a;
COG_US = COG;
if country~="US" then COG_US = round(COG*ratebar, 1);
run;


data mvdec; set disp.mvdec; run;
data region; set disp.region; run;
