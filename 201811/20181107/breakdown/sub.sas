data exp; set tem;
code2=compress(code || '-' || floor(portyear/100));
keep code2 code portyear ret_us country mv rhs;
proc sort data=exp;
by code2;
run;

proc sql;
create table exp as 
select * from exp
group by code2
having count(code2) = 12
;
quit;

proc sort data=exp;
by portyear;
run;

data exp2; set exp;
if portyear > 200500;
if portyear < 200900;
mth = mod(portyear, 100);
proc sort;
by code2 portyear;
run;

%macro sheet(output, v);
data &output; set exp2;
keep mth code2 &v;
proc sort;
by mth code2;
run;
proc transpose data=&output out=&output;
var &v;
by mth;
id code2;
run;
data &output; set &output;
drop _name_;
run;
proc export data = &output
   outfile = "C:\TEMP\&output..csv"
   dbms = csv;
run;
%mend sheet;

%sheet(sheet2, ret);
%sheet(sheet3, mv);

proc export data = exp2
   outfile = "C:\TEMP\exp2..csv"
   dbms = csv;
run;

data exp2; set exp2;
ew=1;
drop year;
run;

proc sort data=rank;
by portyear rhs;
run;
