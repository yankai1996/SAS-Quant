
data junk1; set tmp1.country_ew_slope;
proc sort; by country portyear;
run;

data junk2; set pwd.country_ew_slope;
slope2=slope;
drop slope;
proc sort; by country portyear;
run;


data junksub; set sub;
portyear=mthyr;
keep country portyear n;
proc sort nodup; by country portyear;
run;

data junk; merge junk1 junk2 junksub;
by country portyear;
run;
