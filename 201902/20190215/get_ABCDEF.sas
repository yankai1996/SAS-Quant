
libname export "C:\TEMP\export";
libname disp "C:\TEMP\displace";
libname dsws "C:\TEMP\new DSWS";

data agret0; set disp.agret0;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated;
if (country="US" and mthyr<201307) or (country~="US" and mthyr<201207);
run;

data agret1_us; set export.agret1_us; run;
data agret1_xus; set export.agret1_xus; run;


data old; set agret0 agret1_us agret1_xus; 
flag=1;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated flag;
run;
data new; set dsws.agret0; 
COG = COGS;
flag=2;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated flag;
run;

/*
data junk; set old;
if mthyr=201806;
run;
*/

data ABCDEF; set old new;
proc sort; by code mthyr;
run;

data ABCDEF; set ABCDEF;
by code mthyr;
if (not (first.mthyr and last.mthyr)) and flag=2 then delete;
proc sort; by portyear country;
run;


proc univariate data=ABCDEF noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;

data agret0; merge ABCDEF price;
by portyear country;
drop flag;
proc sort; by code portyear;
run;



data mvdec_old; set disp.mvdec; 
flag=1;
drop country; 
run;
data mvdec_new; set dsws.mvdec; 
flag=2;
run;


data mvdec; set mvdec_old mvdec_new;
proc sort; by code portyear;
run;

data mvdec; set mvdec;
by code portyear;
if (not (first.portyear and last.portyear)) and flag=2 then delete;
drop flag;
run;

/*
data junk2; set mvdec;
by code portyear;
if (not (first.portyear and last.portyear));
run;
*/

data region; set disp.region; run;




data agret1; set agret1_us agret1_xus;
run;


data names0; set agret0;
keep code;
proc sort nodup; by code;
run;

data names1; set agret1;
keep code;
proc sort nodup; by code;
run;

proc sql;
create table names1_x0 as
select * from names1
where code not in (select * from names0)
;
quit;

data names01; set names0 names1;
proc sort nodup; by code;
run;


data names_new; set dsws.agret0; 
keep code;
proc sort nodup; by code;
run;

proc sql;
create table names_new_xold as
select * from names_new
where code not in (select * from names01)
;
quit;
