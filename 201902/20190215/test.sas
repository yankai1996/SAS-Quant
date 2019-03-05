
data junk_agret; set agret0;
flag=1;
keep code portyear flag;
proc sort nodup; by code portyear;
run;

data junk1; merge junk_agret(in=a) mvdec(in=b);
by code portyear;
if a and b;
run;


libname newnew "C:\TEMP\newnew_DSWS";

data junk_agret; set newnew.agret0;
flag=1;
keep code portyear flag;
proc sort nodup; by code portyear;
run;

data mvdec2; set newnew.mvdec; run;

data junk2; merge junk_agret(in=a) mvdec(in=b);
by code portyear;
if a and b;
run;


data mvdec_all; set mvdec mvdec2;
keep code portyear;
proc sort nodup; by code portyear;
run;

data junk_all; set junk1 junk2;
keep code portyear mv;
proc sort nodup; by code portyear;
run;


