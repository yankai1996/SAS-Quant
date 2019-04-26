
libname number "T:\SASData3\number";

%macro checknum(input, output);

data &output; set &input;
*code=dscd;
n=1;
keep code country portyear n;
proc sort nodup; by portyear country code; 
proc means noprint; by portyear country;
var n;
output out=&output n=n;
run;
proc transpose data=&output out=&output; 
by portyear;
var n;
id country;
run;

data number.&output; set &output; run;

%mend checknum;


%checknum(all_lc, stat_all);

%checknum(test, stat_ret);

%checknum(test, stat_ret_mvdec);

%checknum(irisk, stat_irisk);


