data return; set tmp1.mthret;
if mthyr > 201206;
year = year(date);
proc sort; by dscd year;
run;

data acct; set tmp1.wsacct2018;
if year >= 2012;
proc sort; by dscd year;
run;

data acret; merge return(in=a) acct(in=b);
by dscd year;
if a & b;
run;

libname temp "C:\TEMP\";
data temp.acret; set acret; run;

data agret; set disp.agret0;
keep code portyear mc mv lagmv_us mv_us;
run;

data mvdec; set disp.mvdec;
proc sort; by descending year;
run;
