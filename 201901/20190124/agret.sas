
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";


data agret0_us; set disp.agret0;
if country="US" and mthyr<=201306;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
run;

data agret0_xus; set disp.agret0;
if country~="US" and mthyr<=201206;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
run;

data agret1_us; set export.agret1_us;
if mthyr>201306;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
run;

data agret1_xus; set export.agret1_xus;
if mthyr>201206;
keep code ret ret_us mthyr year portyear country RD MC EMP COG COG_US SGA p_us_updated p_us_10;
run;


data agret0; set agret0_us agret0_xus agret1_us agret1_xus;
proc sort; by code mthyr;
run;

data mvdec; set disp.mvdec export.mvdec_new;
proc sort nodup; by code portyear;
run;

data region; set disp.region; run;



