
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";


data agret0_us; set disp.agret0;
if country="US" and mthyr<=201306;
cog_us = cog;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;

data agret0_xus; set disp.agret0;
if country~="US" and mthyr<=201206;
keep code ret ret_us mthyr year portyear country RD MC MC_us EMP COG SGA p_us_updated p_us_10;
run;

data agret1_us; set export.agret1_us;
if mthyr>201306;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;

data agret1_xus; set export.agret1_xus;
if mthyr>201206;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;


data agret0; set agret0_us agret0_xus agret1_us agret1_xus;
run;

data mvdec; set disp.mvdec export.mvdec_new;
proc sort nodup; by code portyear;
run;

data region; set disp.region; run;




data junk; set disp.agret0;
if country~="US" and mthyr<=201206;
if cog~=. and rd~=.;
rate = mc_us/mc;
if rate=. or rate=0 then rate=rd_us/rd;
if rate=. or rate=0 then rate=ta_us/ta;
if rate=. or rate=0 then rate=ta_us_updated/ta_updated;
if rate=. or rate=0 then rate=sl_us/sl;
if rate=0 then rate=.;
if rate=.;
run;

data rate; set disp.agret0;
if country~="US" and mthyr<=201206;
if cog~=. and rd~=.;
rate = mc_us/mc;
if rate=. or rate=0 then rate=rd_us/rd;
if rate=. or rate=0 then rate=ta_us/ta;
if rate=. or rate=0 then rate=ta_us_updated/ta_updated;
if rate=. or rate=0 then rate=sl_us/sl;
if rate=0 then rate=.;
if rate~=.;
keep code mthyr country rate;
proc sort nodup; by mthyr country rate;
run;

data rate; set rate;
rate=round(rate, 0.000001);
drop code;
proc sort nodup; by mthyr country rate;
run;

