
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


data mom; set nnnDS.agret0;;
year=floor(mthyr/100);
month=mthyr-year*100;
if 1<=month<=5;
logret=log(1+ret);
keep code year month logret;
proc sort; by code year month;
run;
proc means noprint; by code year;
var logret;
output out=mom sum=logmom;
run;
data mom; set mom;
if _freq_=5;
MOM=exp(logmom)-1;
portyear=year;
keep code portyear mom;
proc sort; by code portyear;
run;


data agret0; set nnnDS.agret0;
proc sort; by code portyear;
run;

data agret0; merge agret0(in=a) mom(in=b);
by code portyear;
if a;
run;


data ag; set nnnDS.agret0;
keep code year ta;
proc sort nodup; by code year;
run;
data ag; set ag;
by code year;
AG=TA/lag(TA)-1;
if first.code then AG=.;
run;
