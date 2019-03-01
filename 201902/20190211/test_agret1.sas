
libname export "C:\TEMP\export";
libname disp "C:\TEMP\displace";
libname dsws "C:\TEMP\new DSWS";

data agret0; set disp.agret0;
keep code country mthyr portyear year ret ret_us MC RD EMP COG SGA p_us_updated;
if (country="US" and mthyr<201307) or (country~="US" and mthyr<201207);
run;

data agret1_us; set export.agret1_us; run;
data agret1_xus; set export.agret1_xus; run;


data names0_us; set agret0;
if country="US" and mthyr=201306;
keep code;
run;

data names0_xus; set agret0;
if country~="US" and mthyr=201206;
keep code;
proc sort; by code;
run;

data junk; set names0_xus;
by code;
if not (first.code and last.code);
run;

proc sort data=agret0; by code mthyr; run;
data junk2; set agret0;
by code mthyr;
if not (first.mthyr and last.mthyr);
run;


data names1_us; set agret1_us;
if country="US" and mthyr=201307;
keep code;
proc sort nodup; by code;
run;

data names1_xus; set agret1_xus;
if country~="US" and mthyr=201207;
keep code;
proc sort nodup; by code;
run;


%macro overlap(input1, input2, byvars, output);

data &input1; set &input1;
keep &byvars old;
old=1;
proc sort; by &byvars;
run;
data &input2; set &input2;
keep &byvars new;
new=1;
proc sort; by &byvars;
run;

data &output; merge &input1 &input2;
by &byvars;
run;

%mend overlap;


%overlap(names0_us, names1_us, code, names_us);
%overlap(names0_xus, names1_xus, code, names_xus);


data junk; set agret0;
keep code;
proc sort nodup; by code;
run;
