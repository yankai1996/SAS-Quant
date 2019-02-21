libname import "C:\TEMP\import\";

data dailyreturn; set import.returndaily2018;
proc sort; by DSCD date;
run;

data mthret; set dailyreturn;
by DSCD year month;
if last.month;
mthyr = year*100+month;
drop year month;
run;

data mthret; set mthret;
by DSCD;
mthret = ri/lag(ri)-1;
if first.mthyr then mthret=.;
dmth = mthyr-lag(mthyr);
if dmth~=1 and dmth~=89 then mthret=.;
drop dmth;
run;

data import.mthret; set mthret; run;


data mthend; set import.mvmonthly2018;
proc sort; by DSCD date; 
run;

proc sql;
create table mthdata as 
select * from mthend
left join dailyreturn on mthend.DSCD = dailyreturn.DSCD
and mthend.date = dailyreturn.date;
quit;



data mthdata2; merge mthend(in=a) dailyreturn(in=b);
by DSCD date;
if a;
run;

data mthret; set mthdata2;
by DSCD;
mthret=ri/lag(ri)-1;
if first.DSCD then mthret=.;
mthyr = year(date)*100+month(date);
dmth = mthyr-lag(mthyr);
if dmth~=1 and dmth~=89 then mthret=.;
drop dmth;
run;


data missing; set mthret;
*if DSCD="130053";
dmth = mthyr-lag(mthyr);
if dmth~=1 and dmth~=89;
if DSCD=lag(DSCD);
run;
