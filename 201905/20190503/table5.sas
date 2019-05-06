
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



data ag; set nnnDS.agret0;
keep code portyear ta;
proc sort nodup; by code portyear;
run;
data ag; set ag;
by code portyear;
AG=TA/lag(TA)-1;
if first.code then AG=.;
if AG~=.;
drop TA;
proc sort; by code portyear;
run;



data BM; set nnnDS.retm;
code=dscd;
mthyr=year(date)*100+month(date);
keep code mthyr MTB;
proc sort; by code mthyr;
run;
data BM; set BM;
by code mthyr;
BM=1/MTB;
lagBM=lag(BM);
if first.code then lagBM=.;
if lagBM~=.;
keep code mthyr lagBM;
proc sort; by code mthyr;
run;


data BMjune; set nnnDS.retm;
if month(date)=6;
code=dscd;
portyear=year(date);
BMjune=1/MTB;
if BMjune~=.;
keep code portyear BMjune;
proc sort; by code portyear;
run;



data MC; set nnnDS.retm;
code=dscd;
mthyr=year(date)*100+month(date);
keep code mthyr MC MCUS;
proc sort; by code mthyr;
run;
data MC; set MC;
by code mthyr;
lagMC=lag(MC);
lagMCUS=lag(MCUS);
if first.code then do;
	lagMC=.;
	lagMCUS=.;
end;
if lagMC~=.;
keep code mthyr lagMC lagMCUS;
proc sort; by code mthyr;
run;


data MCjune; set nnnDS.retm;
if month(date)=6;
code=dscd;
portyear=year(date);
MCjune=MC;
MCUSjune=MCUS;
if MC~=.;
keep code portyear MCjune MCUSjune;
proc sort; by code portyear;
run;



data agret0; set nnnDS.agret0;
proc sort; by code mthyr;
run;

data agret1; merge agret0(in=a) bm mc;
by code mthyr;
if a;
proc sort; by code portyear;
run;

data agret2; merge agret1(in=a) ag mom;
by code portyear;
if a;
ROE=NI/CE;
run;

proc export data=agret2
    outfile="C:\TEMP\displace\20190503\monthly_201905.csv"
	dbms=csv replace;
run;



proc means data=agret0 noprint; by code portyear;
var ret_us; output out=vol std=vol n=voln;
run;

data agret3; set agret2;
drop mthyr ret ret_us lagBM lagMC lagMCUS;
proc sort nodup; by code portyear;
run;

data agret3; merge agret3(in=a) bmjune mcjune vol;
by code portyear;
if a;
drop _type_ _freq_;
run;



data siccode; set db.siccode;
drop dscd;
proc sort; by code;
run;

data indcode; set db.indcode;
proc sort; by code;
run;

data agret4; merge agret3(in=a) siccode indcode;
by code;
if a;
run;

proc export data=agret4
    outfile="C:\TEMP\displace\20190503\annual_201905.csv"
	dbms=csv replace;
run;
