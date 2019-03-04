
libname newnew "C:\TEMP\newnew_DSWS";
libname disp "C:\TEMP\displace";

data old; set disp.agret0;
keep code country mthyr portyear year ret ret_us flag;
flag=1;
run;

data new; set newnew.agret0;
keep code country mthyr portyear year ret ret_us flag;
flag=2;
run;


data old_newnew; set old new;
proc sort; by code mthyr;
run;

data only_in_old; set old_newnew;
by code mthyr;
if first.mthyr and last.mthyr;
if flag=1;
run;

data junk; set only_in_old;
if country in ("AU","CN","CH", "FN", "FR","BD","GR","HK","IN","IS","IT", 
"JP","KO","MY","SG","SD", "SW","TA","TK","UK", "US");
keep code;
proc sort nodup; by code;
run;



data junk2; set newnew.acct;
keep dscd;
proc sort nodup; by dscd;
run;


data junk3; set newnew.agret0;
keep code;
proc sort nodup; by code;
run;

