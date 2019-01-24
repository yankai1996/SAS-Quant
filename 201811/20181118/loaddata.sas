libname disp "C:\TEMP\displace";

data agret0; set disp.agret0;
drop lagret: pat: cite:;
run;

data mvjune; set disp.mvjune;
run;
/*
filename reffile "C:\TEMP\cty_region.xls" termstr=CR;
proc import datafile=reffile
dbms = xls
out = disp.region;
getnames = yes;
run;
*/
data region; set disp.region; run;
